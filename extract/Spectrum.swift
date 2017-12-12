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

    if arguments.convertToPitch {

      let pitchIndex = binMap(windowLength: arguments.windowSize, sampleRate: .Fs44100)
      let pitchOutput: [PitchVector] = output.map {
        frame in
        var pitchVector = PitchVector()
        for (bin, magnitude) in frame.enumerated() {
          let pitch = pitchIndex[bin]
          pitchVector[pitch] += Float64(magnitude)
        }
        return pitchVector
      }

      let sampleRate = CGFloat(buffer.format.sampleRate)
      let featureRate = sampleRate/CGFloat(arguments.windowSize - arguments.hopSize)

      normalize(array: pitchOutput, settings: .maxValue)

      result = .pitchVectorVec(pitchOutput, featureRate)

    } else {

      result = .realVecVec(output)

    }


  } else {

    // Apply the equal loudness filter.
    EqualLoudnessFilter.process(signal: buffer)

    if arguments.convertToPitch || arguments.convertToChroma {

      let parameters = PitchFeatures.Parameters(
        method: .stft(windowSize: 8820, hopSize: 4410, sampleRate: .Fs44100),
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

          result = .binVectorVec(Array(stft))

        } catch {
          print("Error encountered calculating STFT: \(error.localizedDescription)")
          exit(EXIT_FAILURE)
      }

    }

  }

  return result

}

