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


func executeSpectrumCommand(using buffer: AVAudioPCMBuffer) -> Command.Output {

  let result: Command.Output

  if arguments.useEssentia {

    guard let channelData = buffer.floatChannelData?.pointee else {
      fatalError("Failed to obtain channel data from buffer.")
    }

    let signal = Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))

    let windowSize = Parameter(value: .integer(Int32(arguments.windowSize)))
    let hopSize = Parameter(value: .integer(Int32(arguments.hopSize)))

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
    spectrum[output: .spectrum] >> vectorOutput[input: .data]

    Network(generator: vectorInput).run()

    let output = vectorOutput.vector

    let sampleRate = CGFloat(buffer.format.sampleRate)
    let featureRate = sampleRate/CGFloat(arguments.windowSize - arguments.hopSize)

    let binVectors = output.map({BinVector(array: $0.map(Float64.init))})

    if arguments.convertToPitch || arguments.convertToChroma {

      let pitchIndex = binMap(windowLength: arguments.windowSize, sampleRate: .Fs44100)

      let pitchVectors = binVectors.map({PitchVector(bins: $0,
                                                     sampleRate: .Fs44100,
                                                     pitchIndex: pitchIndex)})


      if arguments.convertToChroma {

        var chromaVectors: [ChromaVector] = []
        chromaVectors.reserveCapacity(pitchVectors.count)

        for pitchFrame in pitchVectors {

          var chromaFrame = ChromaVector()

          for index in pitchFrame.indices { chromaFrame[index % 12] += pitchFrame[index] }

          chromaVectors.append(chromaFrame)

        }

        normalize(array: chromaVectors, settings: .lᵖNorm(space: .l², threshold: 0.001))

        result = .chromaVectorVec(chromaVectors, featureRate)

      } else {

        normalize(array: pitchVectors, settings: .maxValue)

        result = .pitchVectorVec(pitchVectors, featureRate)

      }

    } else {

      result = .binVectorVec(binVectors, featureRate)

    }


  } else {

    // Apply the equal loudness filter.
    EqualLoudnessFilter.process(signal: buffer)

    if arguments.convertToPitch || arguments.convertToChroma {

      let parameters = PitchFeatures.Parameters(
        method: .stft(windowSize: arguments.windowSize,
                      hopSize: arguments.hopSize, 
                      sampleRate: .Fs44100),
        filters: [.normalization(settings: .maxValue)]
      )

      let pitchFeatures = PitchFeatures(from: buffer, parameters: parameters)

      if arguments.convertToChroma {

        let variant: ChromaFeatures.Variant =
          .CP(compression: CompressionSettings(term: 1, factor: 100),
              normalization: .lᵖNorm(space: .l², threshold: 0.001))

        let chromaFeatures = ChromaFeatures(pitchFeatures: pitchFeatures, variant: variant)

        result = .chromaVectorVec(chromaFeatures.features, CGFloat(chromaFeatures.featureRate))

      } else {

        result = .pitchVectorVec(pitchFeatures.features, CGFloat(pitchFeatures.featureRate))
        
      }

    } else {

        do {

          let stft = try STFT(windowSize: arguments.windowSize,
                              hopSize: arguments.hopSize,
                              buffer: buffer)

          let sampleRate = CGFloat(buffer.format.sampleRate)
          let featureRate = sampleRate/CGFloat(arguments.windowSize - arguments.hopSize)

          result = .binVectorVec(Array(stft), featureRate)

        } catch {
          print("Error encountered calculating STFT: \(error.localizedDescription)")
          exit(EXIT_FAILURE)
      }

    }

  }

  return result

}

