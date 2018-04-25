//
//  STFT.swift
//  SignalProcessing
//
//  Created by Jason Cardwell on 9/14/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import AVFoundation
import Accelerate

/// Performs STFT calculations using the provided window length and hop size.
public struct STFT: Collection {

  public var startIndex: Int { return frames.startIndex }
  
  public var endIndex: Int { return frames.endIndex }

  /// The total number of frames.
  public var count: Int { return frames.count }

  public func index(after i: Int) -> Int { return i &+ 1 }

  /// Returns the FFT bin for the specified `position`.
  public subscript(position: Int) -> BinVector { return frames[position] }

  /// The size of the window function given in samples.
  public let windowSize: Int

  /// The hop size for shifting the window given in samples.
  public let hopSize: Int

  /// The collection of bin vectors that represent the STFT frames.
  private var frames: [BinVector]

  /// Applies smoothing to the STFT frames using the specified settings.
  ///
  /// - Parameter settings: The settings to use when smoothing the frames.
  public mutating func smooth(settings: SmoothingSettings) {

    frames = SignalProcessing.smooth(source: frames, settings: settings)

  }

  /// The sample rate as specified by `time`.
  public let sampleRate: SampleRate

  /// Initialize with a buffer holding the signal and some parameter values.
  ///
  /// - Parameters:
  ///   - windowSize: The size of the window function in samples.
  ///   - hopSize: The hop size in samples.
  ///   - buffer: The buffer holding samples for the input signal.
  ///   - sampleRate: The sample rate to retrieve from `buffer`.
  ///   - time: The time associated with the first sample in `buffer`.
  /// - Throws: `Error.fftSetupFailed` if `vDSP_create_fftsetup` fails.
  public init(windowSize: Int, hopSize: Int, buffer: AVAudioPCMBuffer) throws {

    // Initialize the sample rate property.
    guard let sampleRate = SampleRate(buffer: buffer) else {
      throw Error.invalidSampleRate
    }

    self.sampleRate = sampleRate

    // Get the signal.
    guard let signal = buffer.float64ChannelData?.pointee else {
      throw Error.invalidChannelData
    }

    // Get the number of samples.
    let N = Int(buffer.frameLength)

    // Initialize `windowSize` and `window`.
    self.windowSize = windowSize
    let window = Float64Buffer.allocate(capacity: windowSize)
    vDSP_hann_windowD(window, vDSP_Length(windowSize), Int32(vDSP_HANN_NORM))

    self.hopSize = hopSize

    // Calculate the total number of frames in the resulting STFT calculation.
    let frameCount = Int((Float(N) / Float(hopSize)).rounded(.up))

    // Allocate memory for the frames.
    let frames = UnsafeMutablePointer<BinVector>.allocate(capacity: frameCount)

    // Calculate the `windowSize` represented as a power of 2.
//    let log2N = vDSP_Length(log2(Float(windowSize)))

    // Create the FFT support structure.
//    guard let fftSetup = vDSP_create_fftsetupD(log2N, FFTRadix(FFT_RADIX2)) else {
//      throw Error.fftSetupFailed
//    }

    // Create a closure for calculating the number of samples remaining.
    let remainingSamples: (Int) -> Int = { N - hopSize * $0 }

    // Process the signal concurrently.
    DispatchQueue.concurrentPerform(iterations: frameCount) {
      frameIndex in

      // Allocate memory for applying the window to `signal`. `SignalVector` below will free.
      let windowedData = Float64Buffer.allocate(capacity: windowSize)

      // Initialize all the samples to 0
      windowedData.initialize(repeating: 0, count: windowSize)

      // Calculate the number of samples.
      let sampleCount = vDSP_Length(
        Swift.max(0, Swift.min(windowSize, remainingSamples(frameIndex)))
      )

      // Check whether there are samples to which the window should be applied.
      if sampleCount > 0 {

        // Apply the window to the signal storing the result in `windowedData`.
        vDSP_vmulD(signal + (frameIndex * hopSize), 1, window, 1, windowedData, 1, sampleCount)

      }

      // Wrap the windowed data in a vector.
      let signal = SignalVector(storage: windowedData, count: windowSize, assumeOwnership: true)

      // Perform the FFT calculation.
      let calculation = FFT(signal: signal,
                            sampleRate: sampleRate,
                            windowSize: windowSize,
                            hopSize: hopSize)

      // Copy the calculation to `frames[m]`.
      (frames + frameIndex).initialize(to: calculation.bins)

    }

    // Initialize the `frames` property.
    self.frames = Array(UnsafeBufferPointer(start: frames, count: frameCount))

    // Destroy the setup structure.
//    vDSP_destroy_fftsetup(fftSetup)

    // Deallocate the window.
    window.deallocate()

    // Deallocate the frames.
    frames.deallocate()

  }

  /// An enumeration of the possible errors thrown by `STFT`.
  public enum Error: String, Swift.Error {

    case fftSetupFailed = "Failed to setup for fft."
    case invalidSampleRate = "Unsupported sample rate."
    case invalidChannelData = "Missing or incorrectly formatted channel data."

  }

}
