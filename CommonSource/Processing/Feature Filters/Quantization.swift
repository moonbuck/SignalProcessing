//
//  Quantization.swift
//  Chord Finder
//
//  Created by Jason Cardwell on 8/23/17.
//  Copyright (c) 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import Accelerate

/// A simple structure encapsulating settings for quantization.
public struct QuantizationSettings {

  /// Values to which feature values are quantized.
  public var steps = [0.4, 0.2, 0.1, 0.05]

  /// Weights used to generate the quantized value. The weights are cumulative.
  public var weights = [0.25, 0.25, 0.25, 0.25]

  /// Initializing with default property values.
  ///
  /// - Parameters:
  ///   - steps: Values to which feature values are quantized.
  ///   - weights: Weights assigned to `steps`.
  public init(steps: [Float64] = [0.05, 0.1, 0.2, 0.4],
              weights: [Float64] = [0.25, 0.25, 0.25, 0.25])
  {
    precondition(steps.count == weights.count, "`steps` and `weights` must have the same count.")
    let stepsʹ = steps.enumerated().sorted { $0.1 < $1.1 }
    self.steps = stepsʹ.map { $0.1 }
    self.weights = stepsʹ.map { weights[$0.0] }
  }

  public static var `default`: QuantizationSettings { return QuantizationSettings() }
}

/// Quantizes a buffer of vectors using the specified settings.
///
/// - Parameters:
///   - buffer: The buffer with vectors to quantize.
///   - settings: The parameters to use when quantizing the vectors in `buffer`.
/// - Note: This function will overwrite the values stored in `buffer`.
public func quantize<Vector>(buffer: FeatureBuffer<Vector>, settings: QuantizationSettings) {

  // Quantize vectors concurrently.
  DispatchQueue.concurrentPerform(iterations: buffer.count) {
    frame in

    // Get the vector's storage for this frame.
    let frameBuffer = buffer.buffer[frame].storage

    // Iterate over the vector indices.
    for valueIndex in 0..<Vector.count {

      // Get the value for this index.
      let value = frameBuffer[valueIndex]

      // Create a variable for accumulating the quantized value.
      var quantizedValue = 0.0

      // Iterate over the step values.
      for (stepIndex, stepValue) in settings.steps.enumerated() {

        // Check that the value is at least as large as this step value.
        guard value >= stepValue else { break }

        // Add the weight for this step to `quantizedValue`.
        quantizedValue += settings.weights[stepIndex]

      }

      // Replace the vector's value with the quantized value.
      frameBuffer[valueIndex] = quantizedValue

    }

  }

}
