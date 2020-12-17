//
//  Normalization.swift
//  Chord Finder
//
//  Created by Jason Cardwell on 8/23/17.
//  Copyright (c) 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import Accelerate

/// A simple enumeration encapsulating settings for normalization.
public enum NormalizationSettings {

  /// Normalize values across frames using the overall max value.
  case maxValue

  /// Normalize each from using its l¹ or l² norm.
  /// - space: The lᵖ space to use.
  /// - threshold: Value below which the unit vector will be substituted.
  case lᵖNorm(space: NormSpace, threshold: Float64)

  /// Default normalization settings.
  public static var `default`: NormalizationSettings {
    return .lᵖNorm(space: .l², threshold: 0.001)
  }

}

/// An enumeration of supported norm spaces.
/// - l¹: The ℓ¹ norm.
/// - l²: The ℓ² norm.
public enum NormSpace: CustomStringConvertible {

  case l¹, l²

  /// Calculates and returns the lᵖ norm of a vector.
  ///
  /// - Parameters:
  ///   - vector: The values for which a norm will be calculated.
  ///   - count: The total number of values in `vector`.
  /// - Returns: The vector's norm.
  public func norm(for vector: Float64Buffer, count: Int) -> Float64 {

    // Switch on the value of `p`.
    switch self {

      case .l¹:
        // Return the ℓ¹ norm which is the sum of the magnitudes.
        
        var sum: Float64 = 0
        vDSP_svemgD(vector, 1, &sum, vDSP_Length(count))
        return sum

      case .l²:
        // Return the ℓ² norm which is the square root of the sum of the squared magnitudes.

        return cblas_dnrm2(Int32(count), vector, 1)
      
    }
    
  }

  public var description: String {
    switch self { case .l¹: return "l¹"; case .l²: return "l²" }
  }

}

// MARK: - Normalizing Array

/// Normalizes an array of vectors using the specified settings.
///
/// - Parameters:
///   - array: The array of vectors to normalize.
///   - settings: The settings to use when normalizing the vectors in `array`.
public func normalize<Vector>(array: [Vector], settings: NormalizationSettings)
  where Vector:ConstantSizeFloat64Vector
{

  switch settings {

    case .maxValue:
      maxValueNormalize(array: array)

    case .lᵖNorm(space: let space, threshold: let threshold):
      lᵖNormalize(array: array, normSpace: space, threshold: threshold)

  }

}

/// Normalizes the specified buffer using the overall max value contained in its vectors.
///
/// - Parameters:
///   - array: The array with values to normalize.
///   - count: The number of vectors held by `buffer`.
private func maxValueNormalize<Vector>(array: [Vector]) where Vector:ConstantSizeFloat64Vector {

  // Allocate storage for the max value of each vector.
  let maxValues = Float64Buffer.allocate(capacity: array.count)

  let vectorValueCount = vDSP_Length(Vector.count)

  // Iterate the vectors.
  for i in 0 ..< array.count {

    // Get the max value for the buffer's `i`th vector.
    var frameMax: Float64 = 0
    vDSP_maxvD(array[i].storage, 1, &frameMax, vectorValueCount)

    // Initialize the `i`th value in `maxValues`.
    (maxValues + i).initialize(to: frameMax)

  }

  // Determine the max value in `maxValues`.
  var max: Float64 = 0
  vDSP_maxvD(maxValues, 1, &max, vDSP_Length(array.count))

  // Iterate the vectors.
  for i in 0 ..< array.count {

    // Divide each value in the `i`th vector by `max`.
    vDSP_vsdivD(array[i].storage, 1, &max, array[i].storage, 1, vectorValueCount)

  }

}

/// Normalizes each vector using its lᵖ norm.
///
/// - Parameters:
///   - array: An array with vectors to normalize.
///   - normSpace: Specifies whether the l¹ norm or the l² norm will be used.
///   - threshold: The minimum acceptable value for the vector's lᵖ norm. Vectors with an
///                lᵖ norm falling below this value will be filled with the normalized unit
///                vector. The default value for this parameter is `0.001`.
private func lᵖNormalize<Vector>(array: [Vector], normSpace: NormSpace, threshold: Float64)
  where Vector: ConstantSizeFloat64Vector
{

  let vectorValueCount = Vector.count
  for index in 0 ..< array.count {
    lᵖNormalize(vector: array[index].storage,
                count: vectorValueCount,
                normSpace: normSpace,
                threshold: threshold)
  }

}

// MARK: - Normalizing Float64VectorBufferWrapper

/// Normalizes a buffer of vectors using the specified settings.
///
/// - Parameters:
///   - buffer: The buffer of vectors to normalize.
///   - settings: The settings to use when normalizing the vectors in `buffer`.
public func normalize<Buffer>(buffer: Buffer, settings: NormalizationSettings)
  where Buffer: Float64VectorBufferWrapper
{

  switch settings {

    case .maxValue:
      maxValueNormalize(buffer: buffer)

    case .lᵖNorm(space: let space, threshold: let threshold):
      lᵖNormalize(buffer: buffer, normSpace: space, threshold: threshold)

  }

}

/// Normalizes the specified buffer using the overall max value contained in its vectors.
///
/// - Parameters:
///   - buffer: The buffer with values to normalize.
///   - count: The number of vectors held by `buffer`.
private func maxValueNormalize<Buffer>(buffer: Buffer) where Buffer: Float64VectorBufferWrapper {

  // Allocate storage for the max value of each vector.
  let maxValues = Float64Buffer.allocate(capacity: buffer.count)

  let vectorValueCount = vDSP_Length(Buffer.Vector.count)

  // Iterate the vectors.
  for i in 0 ..< buffer.count {

    // Get the max value for the buffer's `i`th vector.
    var frameMax: Float64 = 0
    vDSP_maxvD(buffer.buffer[i].storage, 1, &frameMax, vectorValueCount)

    // Initialize the `i`th value in `maxValues`.
    (maxValues + i).initialize(to: frameMax)

  }

  // Determine the max value in `maxValues`.
  var max: Float64 = 0
  vDSP_maxvD(maxValues, 1, &max, vDSP_Length(buffer.count))

  // Iterate the vectors.
  for i in 0 ..< buffer.count {

    // Divide each value in the `i`th vector by `max`.
    vDSP_vsdivD(buffer.buffer[i].storage, 1, &max, buffer.buffer[i].storage, 1, vectorValueCount)

  }

}

/// Normalizes each vector using its lᵖ norm.
///
/// - Parameters:
///   - buffer: A buffer with vectors to normalize.
///   - normSpace: Specifies whether the l¹ norm or the l² norm will be used.
///   - threshold: The minimum acceptable value for the vector's lᵖ norm. Vectors with an
///                lᵖ norm falling below this value will be filled with the normalized unit
///                vector. The default value for this parameter is `0.001`.
private func lᵖNormalize<Buffer>(buffer: Buffer, normSpace: NormSpace, threshold: Float64)
  where Buffer: Float64VectorBufferWrapper
{

  let vectorValueCount = Buffer.Vector.count
  for index in 0 ..< buffer.count {
    lᵖNormalize(vector: buffer.buffer[index].storage,
                count: vectorValueCount,
                normSpace: normSpace,
                threshold: threshold)
  }

}

// MARK: - Normalizing Float64Vector

/// Normalizes a vector using the specified settings.
///
/// - Parameters:
///   - vector: The vector to normalize.
///   - settings: The settings to use when normalizing `vector`.
public func normalize(vector: ConstantSizeFloat64Vector, settings: NormalizationSettings) {

  normalize(vector: vector.storage, count: type(of: vector).count, settings: settings)

}

// MARK: - Normalizing Float64Buffer

/// Normalizes a vector using the specified settings.
///
/// - Parameters:
///   - vector: The vector to normalize.
///   - count: The number of values in `vector`.
///   - settings: The settings to use when normalizing `vector`.
public func normalize(vector: Float64Buffer, count: Int, settings: NormalizationSettings) {

  switch settings {

    case .maxValue:
      maxValueNormalize(vector: vector, count: count)

    case .lᵖNorm(space: let space, threshold: let threshold):
      lᵖNormalize(vector: vector, count: count, normSpace: space, threshold: threshold)

  }

}

/// Normalizes a vector by dividing each vector value by the vector's maximum value.
///
/// - Parameters:
///   - vector: The vector to normalize.
///   - count: The number of values in `vector`.
private func maxValueNormalize(vector: Float64Buffer, count: Int) {

  var max = 0.0
  vDSP_maxvD(vector, 1, &max, vDSP_Length(count))

  vDSP_vsdivD(vector, 1, &max, vector, 1, vDSP_Length(count))

}

/// Normalizes the specified vector by dividing each value by the its lᵖ norm. To suppress
/// random noise, the values in `vector` may be replaced by the normalized unit vector.
///
/// - Parameters:
///   - vector: The vector of values to replace with their normalized value.
///   - count: The total number of values in `vector`.
///   - normSpace: Specifies whether the l¹ norm or the l² norm will be used.
///   - threshold: The minimum acceptable value for the vector's lᵖ norm. If the lᵖ norm
///                is below this value, `vector` will be filled with the normalized unit
///                vector. This results in the same normalized `vector` as would be
///                produced by invoking this method with a `count` size vector of `1`s.
/// - Note: This method overwrites the values in `vector`.
private func lᵖNormalize(vector: Float64Buffer,
                        count: Int,
                        normSpace: NormSpace,
                        threshold: Float64)
{

  // Get the vector's count as the required types.
  let countf = Float64(count)
  let countu = vDSP_Length(count)

  // Calculate the ℓₚ norm.
  var norm = normSpace.norm(for: vector, count: count)

  // Check the norm against the threshold.
  if norm < threshold {
    // The norm is below the threshold, replace the vector with the unit vector
    // with values divided by the unit vector's ℓₚ norm.

    // Determine the value to use for all elements in the vector.
    // The sum of the unit vector will be equal to `count` for `p == 1` and `p == 2`
    // since `1` squared is still `1`. Thus, the ℓ₁ norm for the unit vector is `count`
    // and the ℓ₂ norm for the unit vector is the square root of `count`. The value of
    // every element in the vector then becomes `1` divided by the norm.
    var normalizedUnitValue = normSpace == .l¹ ? 1 / countf : 1 / sqrt(countf)

    // Fill `vector` with `normalizedUnitValue`.
    vDSP_vfillD(&normalizedUnitValue, vector, 1, countu)

  } else {
    // The norm is above the threshold, use it to divide each value in the vector.

    // Divide each element in `vector` by `norm`.
    vDSP_vsdivD(vector, 1, &norm, vector, 1, countu)
    
  }
  

}


