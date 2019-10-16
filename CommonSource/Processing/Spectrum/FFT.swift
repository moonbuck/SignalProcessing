//
//  FFT.swift
//  SignalProcessing
//
//  Created by Jason Cardwell on 9/14/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//

import Foundation
import Accelerate
import AVFoundation

/// A structure for calculating the Fourier coefficients for a given signal.
public struct FFT {

  /// The sample rate in Hz of the transformed audio signal.
  public let sampleRate: SampleRate

  /// Storage for the energy values.
  public let bins: BinVector

  /// Initializer that derives sample rate and window size from the specified buffer.
  ///
  /// - Parameters:
  ///   - buffer: The buffer of audio samples.
  ///   - representation: Specifies how energy values should be calculated. Default is `magnitude`.
  public init(samples buffer: AVAudioPCMBuffer, representation: BinRepresentation = .magnitude) {

    guard let sampleRate = SampleRate(buffer: buffer) else {
      fatalError("\(#function) Unsupported sample rate: \(buffer.format.sampleRate)")
    }

    let windowSize = Int(buffer.frameLength)

    let signal = SignalVector(buffer: buffer)

    self.init(signal: signal,
              sampleRate: sampleRate,
              windowSize: windowSize,
              representation: representation)

  }

  /// Initializing with a pointer to the signal's samples and their count; as well as, the window
  /// size. This initializer creates single use values to pass to
  /// `init(signal:sampleRate:setup:log2N)`.
  ///
  /// - Parameters:
  ///   - signal: The samples for the signal to transform.
  ///   - sampleRate: The sample rate.
  ///   - windowSize: The window size for the calculation.
  ///   - representation: Specifies how energy values should be calculated. Default is `magnitude`
  public init(signal: SignalVector,
              sampleRate: SampleRate,
              windowSize: Int,
              representation: BinRepresentation = .magnitude)
  {

    // Calculate the `windowSize` represented as a power of 2.
    let log2N = vDSP_Length(log2(Float(windowSize)))

    // Create the FFT support structure.
    guard let fftSetup = vDSP_create_fftsetupD(log2N, FFTRadix(FFT_RADIX2)) else {
      fatalError("Failed to create FFT setup support structure.")
    }

    defer { vDSP_destroy_fftsetupD(fftSetup) }

    self.init(signal: signal,
              sampleRate: sampleRate,
              setup: fftSetup,
              log2N: log2N,
              representation: representation)

  }

  /// Initializing with a pointer to the signal's samples and their count, the structure
  /// with the weighted array to use, and a precalculated value for `log2N`.
  ///
  /// - Parameters:
  ///   - signal: The samples for the signal to transform.
  ///   - sampleRate: The sample rate.
  ///   - setup: The setup structure to use in calculations.
  ///   - log2N: The precalculated base 2 log value for `N`.
  ///   - representation: Specifies how energy values should be calculated. Default is `magnitude`.
  public init(signal: SignalVector,
              sampleRate: SampleRate,
              setup: FFTSetupD,
              log2N: vDSP_Length,
              representation: BinRepresentation = .magnitude)
  {

    // Initialize the sample rate property.
    self.sampleRate = sampleRate

    // Cast `N` to the type required by the Accelerate framework.
    let N = vDSP_Length(signal.count)

    // Initialize `K` as half of `N`.
    let K = N / 2

    // Initialize a split complex buffer.
    var complexBuffer = DSPDoubleSplitComplex(
      realp: Float64Buffer.allocate(capacity: Int(K) + 1),
      imagp: Float64Buffer.allocate(capacity: Int(K) + 1)
    )

    // Fill the buffer mapping even-indexed values to `realp` and odd to `imagp`.
    signal.storage.withMemoryRebound(to: DSPDoubleComplex.self, capacity: Int(K)) {
      vDSP_ctozD($0, 2, &complexBuffer, 1, K)
    }

    // Calculate the fft.
    vDSP_fft_zripD(setup, &complexBuffer, 1, log2N, FFTDirection(FFT_FORWARD))

    // Divide by two since Cimp = Cmath * 2
    var oneHalf = 0.5
    vDSP_vsmulD(complexBuffer.realp, 1, &oneHalf, complexBuffer.realp, 1, K)
    vDSP_vsmulD(complexBuffer.imagp, 1, &oneHalf, complexBuffer.imagp, 1, K)

    // Move the nyquist value.
    (complexBuffer.realp + Int(K)).initialize(to: complexBuffer.imagp[0])
    complexBuffer.imagp[0] = 0

    // Allocate memory for the energy values.
    bins = BinVector(count: Int(K) + 1)

    // Initialize `bins` by calculating energies from the complex buffer.
    switch representation {

      case .magnitude:
        // Calculate energy as magnitude.

        vDSP_zvabsD(&complexBuffer, 1, bins.storage, 1, K + 1)

      case .magnitudeSquared:
        // Calculate energy as magnitude squared.

        vDSP_zvmagsD(&complexBuffer, 1, bins.storage, 1, K + 1)
        
    }

    // Deallocate memory.
    complexBuffer.realp.deallocate()
    complexBuffer.imagp.deallocate()

  }

}

extension FFT {

  /// An enumeration of possible energy representations stored by the bins.
  ///
  /// - magnitude: The bins will store energy as each value's magnitude.
  /// - magnitudeSquared: The bins will store energy as each value's magnitude squared.
  public enum BinRepresentation {

    case magnitude, magnitudeSquared

  }

}

extension FFT: Collection {

  /// The total number of Fourier coefficients.
  public var count: Int { return bins.count }

  public var startIndex: Int { return 0 }
  public var endIndex: Int { return count }

  public func index(after i: Int) -> Int { return i &+ 1 }

  /// Accessor for the energy value of the specified coefficient.
  ///
  /// - Parameter position: The index of the coefficient.
  public subscript(position: Int) -> Float64 { return bins[position] }

}

