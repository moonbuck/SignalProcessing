//
//  Window.swift
//  SignalProcessing
//
//  Created by Jason Cardwell on 9/27/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import Accelerate

/// A structure for cutting out a window of samples from an audio signal.
public struct Window {

  /// The length of the window in samples.
  public let size: Int

  /// Whether to use zero-phase windowing.
  public let zeroPhase: Bool

  /// The kind of window.
  public let kind: Kind

  /// The default initializer for creating a `Window`. This initializer calculates a Hann
  /// window normalized and scaled by `2`.
  ///
  /// - Parameters:
  ///   - size: The number of samples covered by the window.
  ///   - zeroPhase: `true` if the window should be zero-phase and `false` otherwise.
  ///   - kind: The kind of window to generate.
  public init(size: Int, zeroPhase: Bool = true, kind: Kind = .`default`) {

    // Initialize the window's properties.
    self.size = size
    self.zeroPhase = zeroPhase
    self.kind = kind

    // Allocate memory for the window and initialize all values to `0`.
    storage = Float64Buffer.allocate(capacity: size)
    vDSP_vclrD(storage, 1, vDSP_Length(size))

    // Switch on the kind of window to generate.
    switch kind {

      case .`default`:

        // Initialize the allocated memory by calculating a Hann window.
        for i in 0 ..< size {
          (storage + i).initialize(to: 0.5 - 0.5 * cos((2 * .pi * Float64(i)) / Float64(size - 1)))
        }

        // Calculate the sum of the window vector's values.
        var sum = 0.0
        vDSP_svemgD(storage, 1, &sum, vDSP_Length(size))

        // Scale the window vector's normalized values by 2.
        var scale = 2 / sum
        vDSP_vsmulD(storage, 1, &scale, storage, 1, vDSP_Length(size))

      case .hanningNormalized:

        vDSP_hann_windowD(storage, vDSP_Length(size), Int32(vDSP_HANN_NORM))

      case .hanningNormalizedHalf:

        vDSP_hann_windowD(storage, vDSP_Length(size), Int32(vDSP_HANN_NORM|vDSP_HALF_WINDOW))

      case .hanningDenormalized:

        vDSP_hann_windowD(storage, vDSP_Length(size), Int32(vDSP_HANN_DENORM))

      case .hanningDenormalizedHalf:

        vDSP_hann_windowD(storage, vDSP_Length(size), Int32(vDSP_HANN_DENORM|vDSP_HALF_WINDOW))

      case .hamming:

        vDSP_hamm_windowD(storage, vDSP_Length(size), 0)

      case .hammingHalf:

        vDSP_hamm_windowD(storage, vDSP_Length(size), Int32(vDSP_HALF_WINDOW))

      case .blackman:

        vDSP_blkman_windowD(storage, vDSP_Length(size), 0)

      case .blackmanHalf:

        vDSP_blkman_windowD(storage, vDSP_Length(size), Int32(vDSP_HALF_WINDOW))

    }

  }

  /// The contiguous storage for the window values.
  private let storage: Float64Buffer

  /// Applies the window to the specified signal.
  ///
  /// - Parameter signal: The signal to window.
  /// - Returns: The result of windowing `signal`.
  public func window(signal: SignalVector) -> SignalVector {

    // Allocate memory for the windowed signal.
    let windowedSignal = SignalVector(count: size)

    // Switch on whether the result should be zero-phase.
    switch zeroPhase {

    case true:
      // Result should be zero-phase. Window the signal but swap positions of the two halves of
      // the resulting vector.

      var i = 0

      // The first half of the windowed signal is the second half of the signal with windowing.
      for j in signal.count/2..<signal.count {
        windowedSignal.storage[i] = signal[j] * storage[j]
        i += 1
      }

      // The second half of the signal is the first half of the signal with windowing.
      for j in 0 ..< signal.count/2 {
        windowedSignal.storage[i] = signal[j] * storage[j]
        i += 1
      }

    case false:
      // Result need not be zero-phase. Just window the signal.

      for i in 0 ..< signal.count {
        windowedSignal.storage[i] = signal[i] * storage[i]
      }

    }

    return windowedSignal
    
  }

  /// Applies the window to the specified signal in place.
  ///
  /// - Parameter signal: The signal to window.
  public func window(signal: inout SignalVector) {

    vDSP_vmulD(signal.storage, 1,
               storage, 1,
               signal.storage, 1,
               vDSP_Length(min(size, signal.count)))

    guard zeroPhase && size == signal.count else { return }

    var buffer = UnsafeMutableBufferPointer(start: signal.storage, count: signal.count)

    let halfSize = size / 2

    for index in 0 ..< halfSize { buffer.swapAt(index, index + halfSize) }

  }

}

extension Window: CustomStringConvertible, CustomDebugStringConvertible {

  public var description: String {
    return "Window {size: \(size); zero-phase: \(zeroPhase); kind: \(kind)}"
  }

  public var debugDescription: String {
    var result = String(description.dropLast())
    result += "; _window: ["
    let buffer = UnsafeBufferPointer(start: storage, count: size)
    let values = buffer.map(\.description).joined(separator: ", ")
    result += values
    result += "}"
    return result
  }

}

extension Window {

  /// An enumeration of the kinds of windows that can be generated.
  /// - `default`: Specifies a Hanning window normalized and scaled by `2`.
  /// - hanningNormalized: Specifies a normalized Hanning window.
  /// - hanningNormalizedHalf: Specifies half of a normalized Hanning window.
  /// - hanningDenormalized: Specifies a denormalized Hanning window.
  /// - hanningDenormalizedHalf: Specifies half of a denormalized Hanning window.
  /// - hamming: Specifies a Hamming window.
  /// - hammingHalf: Specifies half of a Hamming window.
  /// - blackman: Specifies a Blackman window.
  /// - blackmanHalf: Specifies half of a Blackman window.
  public enum Kind: String, CustomStringConvertible {

    case `default`
    case hanningNormalized, hanningNormalizedHalf
    case hanningDenormalized, hanningDenormalizedHalf
    case hamming, hammingHalf
    case blackman, blackmanHalf

    public var description: String { return rawValue }

  }

}
