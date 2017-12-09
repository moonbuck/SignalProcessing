//
//  Compression.swift
//  Chord Finder
//
//  Created by Jason Cardwell on 8/23/17.
//  Copyright (c) 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import Accelerate

/// A simple structure encapsulating settings for logarithmic compression.
public struct CompressionSettings {

  /// The constant added to the product of the value and `factor` before the log is taken.
  public var term: Float64

  /// The constant by which the value is multiplied before `term` is added and the log taken.
  public var factor: Float64

  /// Initializing with default property values.
  public init(term: Float64 = 1.0, factor: Float64 = 100.0) {

    self.term = term
    self.factor = factor

  }

  public static var `default`: CompressionSettings { return CompressionSettings() }

}

/// Logarithmic compression for a vector.
///
/// - Parameters:
///   - vector: The vector with values to compress.
///   - settings: The factor and term to use when compressing.
public func compress(vector: ConstantSizeFloat64Vector, settings: CompressionSettings) {

  // Get the number of values in `vector`.
  var count = Int32(type(of: vector).count)

  // Get the factor and term from `settings`.
  var factor = settings.factor
  var term = settings.term

  // For each value, multiple by `factor` and add `term`.
  vDSP_vsmsaD(vector.storage, 1, &factor, &term, vector.storage, 1, vDSP_Length(count))

  // Take the base 10 log of each value.
  vvlog10(vector.storage, vector.storage, &count)

}


/// Logarithmic compression for a buffer of vectors.
///
/// - Parameters:
///   - buffer: The buffer of vectors with values to compress.
///   - settings: The factor and term to use when compressing.
public func compress<Buffer>(buffer: Buffer, settings: CompressionSettings)
  where Buffer: Float64VectorBufferWrapper
{

  for index in 0 ..< buffer.count {

    compress(vector: buffer.buffer[index], settings: settings)

  }

}
