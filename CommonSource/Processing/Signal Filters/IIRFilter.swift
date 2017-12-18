//
//  IIRFilter.swift
//  SignalProcessing
//
//  Created by Jason Cardwell on 9/25/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import Accelerate

///  Direct Form II Transposed implementation of the standard difference equation:
///
///  `A₀Yₙ = B₀Xₙ + B₁X₍ₙ₋₁₎ + … + B₍ₗ₋₁₎X₍ₙ₋ₗ₊₁₎ - A₁Y₍ₙ₋₁₎ - … - A₍ₙ₋₁₎Y₍ₙ₋ₘ₊₁₎` where
///  `l` is the number of B coefficients and `m` is the number of A coefficients.
public final class IIRFilter: SignalFilter {

  /// The 'A' or denominator coefficients for the filter.
  private var a: [Float64]

  /// The 'B' or numerator coefficients for the filter.
  private var b: [Float64]

  /// Buffer for coefficient calculations.
  private var state: [Float64]

  private var isIdentityFilter = false

  /// Initializing with the filter coefficients.
  ///
  /// - Parameters:
  ///   - a: The A or denominator coefficients.
  ///   - b: The B or numerator coefficients.
  /// - Requires: `a` not be empty, `b` not be empty, and `a[0] != 0`.
  public init(a: [Float64], b: [Float64]) {

    // Initialize the `a` and `b` properties.
    self.a = a
    self.b = b

    // Check that the coefficients are adequate.
    guard !(b.isEmpty || a.isEmpty) else {

      state = []
      isIdentityFilter = true

      return

    }

    guard a[0] != 0 else  {
      fatalError("The first value of the denominator vector must not be 0.")
    }

    // Normalize all the coeffiencts with `a[0]`.
    var a0 = a[0]
    vDSP_vsdivD(self.a, 1, &a0, &self.a, 1, vDSP_Length(a.count))
    vDSP_vsdivD(self.b, 1, &a0, &self.b, 1, vDSP_Length(b.count))

    // Initialize the `state` property.
    state = Array<Float64>(repeating: 0, count: max(a.count, b.count))

  }

  /// Zeroes all values in `state`.
  public func reset() {
    guard !isIdentityFilter else { return }
    vDSP_vclrD(&state, 1, vDSP_Length(state.count))
  }

  /// Filters the input signal `x` storing the filtered signal in `y`.
  ///
  /// - Parameters:
  ///   - x: The signal to filter.
  ///   - y: The vector to which the filtered signal will be written.
  public func process(signal x: SignalVector, y: SignalVector) {
    process(signal: x.storage, y: y)
  }

  /// Filters the input signal `x` storing the filtered signal in `y`.
  ///
  /// - Parameters:
  ///   - x: The signal to filter.
  ///   - y: The vector to which the filtered signal will be written.
  public func process(signal x: Float64Buffer, y: SignalVector) {

    guard !isIdentityFilter else {

      let countu = vDSP_Length(y.count)
      vDSP_mmovD(x, y.storage, countu, countu, 1, countu)

      return

    }

    /// Internal helper for recalculating state for a new sample.
    ///
    /// - Parameters:
    ///   - size: The size of the adjustment. This should be equal to `min(a.count, b.count)`.
    ///   - x: The value from the input signal.
    ///   - y: The value from the output signal.
    func updateStateLine(size: Int, x: Float64, y: Float64) {

      // Adjust the values in `state` to account for the new input value.
      for k in 1 ..< size { state[k - 1] = b[k] * x - a[k] * y + state[k] }

      // Ensure there are no subnormal values in `state`.
      for k in 1 ..< size { renormalize(&state[k - 1]) }

    }

    /// Helper for preventing subnormal values.
    ///
    /// - Parameter value: The value for which to ensure normality.
    func renormalize(_ value: inout Float64) { if value.isSubnormal { value = 0 } }

    // Process according to the counts of the a and b coefficients.
    switch (a.count, b.count) {

      case let (nA, nB) where nA == nB:
        // There are the same number of a and b coefficients.

        for n in 0 ..< y.count {

          y[n] = b[0] * x[n] + state[0]
          updateStateLine(size: a.count, x: x[n], y: y[n])

        }

      case let (nA, nB) where nB > nA:
        // There are more b coefficients than a coefficients.

        for n in 0 ..< y.count {

          y[n] = b[0] * x[n] + state[0]
          updateStateLine(size: a.count, x: x[n], y: y[n])

          for k in a.count ..< state.count {

            state [k - 1] = b[k] * x[n] + state[k]
            renormalize(&state[k - 1])

          }

        }

      default:
        // There are more a coefficients than b coefficients.

        for n in 0 ..< y.count {

          y[n] = b[0] * x[n] + state[0]
          updateStateLine(size: b.count, x: x[n], y: y[n])

          for k in b.count ..< state.count {

            state[k - 1] = -a[k] * y[n] + state[k]
            renormalize(&state[k - 1])

          }

        }

    }

  }

}
