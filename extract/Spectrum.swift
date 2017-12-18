//
//  Spectrum.swift
//  extract
//
//  Created by Jason Cardwell on 12/9/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import AVFoundation
import Essentia
import SignalProcessing

//   ********    Custom operators for use with Essentia streaming mode.

infix operator >>
infix operator >!
postfix operator >>|
postfix operator >>>

enum Output {
  case pitchFeatures ([PitchVector], CGFloat)
  case binFeatures ([BinVector], CGFloat)
  case chromaFeatures ([ChromaVector], CGFloat)
}


/// Performs feature extraction on the specified buffer.
///
/// - Parameter buffer: The buffer from which features will be extracted.
/// - Returns: The extracted features.
func extractFeatures(using buffer: AVAudioPCMBuffer) -> Output {

  return arguments.extractionOptions.useEssentia
           ? extractFeaturesUsingEssentia(buffer: buffer)
           : extractFeaturesUsingSignalProcessing(buffer: buffer)

}

/// Performs feature extraction on the specified buffer using the Essentia framework.
///
/// - Parameter buffer: The buffer from which features will be extracted.
/// - Returns: The extracted features.
private func extractFeaturesUsingEssentia(buffer: AVAudioPCMBuffer) -> Output {

  guard let channelData = buffer.floatChannelData?.pointee else {
    fatalError("Failed to obtain channel data from buffer.")
  }

  let signal = Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))

  let ws = arguments.extractionOptions.windowSize
  let hs = arguments.extractionOptions.hopSize

  let quantization = arguments.extractionOptions.quantization

  let windowSize = Parameter(value: .integer(Int32(ws)))
  let hopSize = Parameter(value: .integer(Int32(hs)))

  let vectorInput = VectorInput<Float>(signal)

  let equalLoudness = EqualLoudnessSAlgorithm()

  let frameCutter = FrameCutterSAlgorithm([
    .frameSize: windowSize, .hopSize: hopSize, .startFromZero: false
    ])

  let windowing = WindowingSAlgorithm([.type: "hann", .size: windowSize])

  let spectrum = SpectrumSAlgorithm([.size: windowSize])


  let vectorOutput = VectorOutput<[Float]>()

  vectorInput[output: .data] >> equalLoudness[input: .signal]
  equalLoudness[output: .signal] >> frameCutter[input: .signal]
  frameCutter[output: .frame] >> windowing[input: .frame]
  windowing[output: .frame] >> spectrum[input: .frame]

  if arguments.extractionOptions.convertToDecibels {

    let unaryOperator = UnaryOperatorSAlgorithm([.type: "lin2db"])

    spectrum[output: .spectrum] >> unaryOperator[input: .array]
    unaryOperator[output: .array] >> vectorOutput[input: .data]

  } else {

    spectrum[output: .spectrum] >> vectorOutput[input: .data]

  }

  Network(generator: vectorInput).run()

  let output = vectorOutput.vector

  let sampleRate = CGFloat(buffer.format.sampleRate)
  let featureRate = sampleRate/CGFloat(ws - hs)

  let binVectors = output.map({BinVector(array: $0.map(Float64.init))})

  if quantization != .bin {

    let pitchVectors = binVectors.map({PitchVector(bins: $0,
                                                   windowLength: ws,
                                                   sampleRate: .Fs44100
                                                   )})


    if quantization == .chroma {

      var chromaVectors: [ChromaVector] = []
      chromaVectors.reserveCapacity(pitchVectors.count)

      for pitchFrame in pitchVectors {

        let chromaFrame = ChromaVector()

        for index in pitchFrame.indices { chromaFrame[index % 12] += pitchFrame[index] }

        chromaVectors.append(chromaFrame)

      }

      normalize(array: chromaVectors, settings: .lᵖNorm(space: .l², threshold: 0.001))

      return .chromaFeatures(chromaVectors, featureRate)

    } else {

      normalize(array: pitchVectors, settings: .maxValue)

      return .pitchFeatures(pitchVectors, featureRate)

    }

  } else {

    return .binFeatures(binVectors, featureRate)

  }

}

/// Performs feature extraction on the specified buffer using the SignalProcessing framework.
///
/// - Parameter buffer: The buffer from which features will be extracted.
/// - Returns: The extracted features.
private func extractFeaturesUsingSignalProcessing(buffer: AVAudioPCMBuffer) -> Output {

  let windowSize = arguments.extractionOptions.windowSize
  let hopSize = arguments.extractionOptions.hopSize
  let quantization = arguments.extractionOptions.quantization

  // Apply the equal loudness filter.
  let filter = EqualLoudnessFilter()
  filter.process(signal: buffer)

  if quantization != .bin {

    let method: PitchFeatures.ExtractionMethod =
      .stft(windowSize: windowSize, hopSize: hopSize, sampleRate: .Fs44100)

    var filters: [FeatureFilter] = []

    if arguments.extractionOptions.convertToDecibels {
      filters.append(.decibel(settings: DecibelConversionSettings(multiplier: .amplitude,
                                                                  zeroReference: 1)))
    }

    if arguments.extractionOptions.compressionFactor > 0 {

      let settings = CompressionSettings(term: 1,
                                         factor: arguments.extractionOptions.compressionFactor)
      filters.append(.compression(settings: settings))
      
    }

    filters.append(.normalization(settings: .maxValue))

    let parameters = PitchFeatures.Parameters(method: method, filters: filters)

    do {

      let pitchFeatures = try PitchFeatures(from: buffer, parameters: parameters)

      if quantization == .chroma {

        let variant: ChromaFeatures.Variant =
          .CP(compression: CompressionSettings(term: 1, factor: 100),
              normalization: .lᵖNorm(space: .l², threshold: 0.001))

        let chromaFeatures = ChromaFeatures(pitchFeatures: pitchFeatures, variant: variant)

        return .chromaFeatures(chromaFeatures.features, CGFloat(chromaFeatures.featureRate))

      } else {

        return .pitchFeatures(pitchFeatures.features, CGFloat(pitchFeatures.featureRate))

      }

    } catch {

      print("Error encountered extracting pitch features: \(error.localizedDescription)")
      exit(EXIT_FAILURE)

    }

  } else {

    do {

      let stft = try STFT(windowSize: windowSize, hopSize: hopSize, buffer: buffer)

      let sampleRate = CGFloat(buffer.format.sampleRate)
      let featureRate = sampleRate/CGFloat(windowSize - hopSize)

      let features = Array(stft)

      if arguments.extractionOptions.convertToDecibels {
        let settings = DecibelConversionSettings(multiplier: .amplitude, zeroReference: 0)
        decibelConversion(buffer: features, settings: settings)
      }

      return .binFeatures(features, featureRate)

    } catch {
      print("Error encountered calculating STFT: \(error.localizedDescription)")
      exit(EXIT_FAILURE)
    }

  }

}
