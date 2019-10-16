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
  ///   - representation: Specifies how energy values should be calculated. Default is `magnitude`.
  /// - Throws: `Error.fftSetupFailed` if `vDSP_create_fftsetup` fails.
  public init(windowSize: Int,
              hopSize: Int,
              buffer: AVAudioPCMBuffer,
              representation: FFT.BinRepresentation = .magnitude) throws
  {

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
    
    let window = Window(size: windowSize, zeroPhase: false, kind: .hanningNormalized)

    self.hopSize = hopSize

    // Calculate the total number of frames in the resulting STFT calculation.
    let frameCount = Int((Float(N) / Float(hopSize)).rounded(.up))

    // Allocate memory for the frames.
    let frames = UnsafeMutablePointer<BinVector>.allocate(capacity: frameCount)

    // Create a closure for calculating the number of samples remaining.
    let remainingSamples: (Int) -> Int = { N - hopSize * $0 }

    // Process the signal concurrently.
    DispatchQueue.concurrentPerform(iterations: frameCount) {
      frameIndex in

      // Calculate the number of samples.
      let sampleCount = Swift.max(0, Swift.min(windowSize, remainingSamples(frameIndex)))

      // Wrap the signal in a vector.
      var signalʹ = SignalVector(copying: signal + (frameIndex * hopSize),
                                  count: sampleCount,
                                  capacity: windowSize)

      // Window the signal.
      window.window(signal: &signalʹ)

      // Perform the FFT calculation.
      let calculation = FFT(signal: signalʹ,
                            sampleRate: sampleRate,
                            windowSize: windowSize,
                            representation: representation)

      // Copy the calculation to `frames[m]`.
      (frames + frameIndex).initialize(to: calculation.bins)

    }

    // Initialize the `frames` property.
    self.frames = Array(UnsafeBufferPointer(start: frames, count: frameCount))

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
