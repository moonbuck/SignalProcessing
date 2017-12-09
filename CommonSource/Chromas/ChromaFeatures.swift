//
//  ChromaFeatures.swift
//  Chord Finder
//
//  Created by Jason Cardwell on 8/04/17.
//  Copyright (c) 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import Accelerate

/// A collection of an audio signal's per-frame per-chroma energy in the form of STMSP.
public struct ChromaFeatures: ParameterizedFeatureCollection {

  /// An array with the vectors holding chroma energies.
  public let features: [ChromaVector]

  /// The number of features per second.
  public let featureRate: Float

  /// The parameters used to extract `features`.
  public let parameters: Parameters

  /// The index for the first chroma feature.
  public let startIndex: Int = 0

  /// The index after the last chroma feature.
  public var endIndex: Int { return features.endIndex }

  /// The total number of chroma features.
  public var count: Int { return features.count }

  /// Returns the successor for the specified index.
  ///
  /// - Parameter i: The index whose successor should be returned.
  /// - Returns: The successor for `i`.
  public func index(after i: Int) -> Int { return i &+ 1 }

  /// Accessor for the chroma feature at a specific index.
  ///
  /// - Parameter position: The index of the chroma feature to retrieve.
  public subscript(position: Int) -> ChromaVector { return features[position] }

  /// Initialize by deep copying an existing collection of features.
  public init(_ features: ChromaFeatures) {

    var copiedFeatures: [ChromaVector] = []
    copiedFeatures.reserveCapacity(features.count)

    for vector in features {
      let vectorCopy = ChromaVector(vector)
      copiedFeatures.append(vectorCopy)
    }

    self.features = copiedFeatures
    featureRate = features.featureRate
    parameters = features.parameters

  }

  /// Initializing with a buffer and the associated parameters.
  public init(_ buffer: ChromaBuffer, _ parameters: Parameters) {
    features = buffer.array
    featureRate = buffer.featureRate
    self.parameters = parameters
  }

  /// Initializing with an existing collection of pitch features.
  ///
  /// - Parameters:
  ///   - pitchFeatures: The pitch features from which chroma features are to be extracted.
  ///   - variant: The chroma feature variant to extract from `pitchBuffer`.
  public init(pitchFeatures: PitchFeatures, variant: Variant) {

    // Create a variable for the buffer of chroma features.
    let chromaBuffer: ChromaBuffer

    // Convert the pitch features into a pitch buffer.
    let pitchBuffer = PitchBuffer(pitchFeatures)

    // Switch on `variant` to set the value of `extract`.
    switch variant {

      case .CP(compression: let compression, normalization: let normalization):
        chromaBuffer = extractChromaFeatures(from: pitchBuffer,
                                             compression: compression,
                                             normalization: normalization)

      case .CENS(quantization: let quantization, smoothing: let smoothing):
        chromaBuffer = extractCENSFeatures(from: pitchBuffer,
                                           quantization: quantization,
                                           smoothing: smoothing)

      case .CRP(coefficients: let coefficients, smoothing: let smoothing):
        chromaBuffer = extractCRPFeatures(from: pitchBuffer,
                                          coefficients: coefficients,
                                          smoothing: smoothing)

    }

    let parameters = Parameters(pitchFeatureParameters: pitchFeatures.parameters, variant: variant)

    // Initialize with the buffer of chroma features.
    self.init(chromaBuffer, parameters)
    
  }

  /// An enumeration for specifying the desired characteristics for extracted chroma features.
  public enum Variant {

    /// - CP: Chroma-Pitch
    /// - Parameters:
    ///   - compression: The settings for compressing feature values or `nil`.
    ///   - normalization: The settings for normalizing feature values or `nil`.
    case CP (compression: CompressionSettings?, normalization: NormalizationSettings?)

    /// - CENS: Chroma Energy Normalized Statistics
    /// - Parameters:
    ///   - quantization: The settings to use during the quantization step.
    ///   - smoothing: The settings for smoothing feature values or `nil`.
    case CENS (quantization: QuantizationSettings, smoothing: SmoothingSettings?)

    /// - CRP: Chroma DCT-Reduced log Pitch
    /// - Parameters:
    ///   - coefficients: The coefficients to keep.
    ///   - smoothing: The settings for smoothing feature values or `nil`.
    case CRP (coefficients: CountableRange<Int>, smoothing: SmoothingSettings?)

    /// The default variant value.
    public static var `default`: Variant {
      return .CP(compression: CompressionSettings(), normalization: .default)
    }

  }

  /// A type for specifying the parameters used to extract chroma features. 
  public struct Parameters {

    /// The parameter values that were used to extract the pitch features from which the 
    /// chroma features are extracted.
    public let pitchFeatureParameters: PitchFeatures.Parameters

    /// The chroma feature variant to extract.
    public let variant: Variant

    /// Initializing with default property values.
    ///
    /// - Parameters:
    ///   - pitchFeatureParameters: The parameter values that were used to extract the pitch 
    ///                             features from which the chroma features are extracted.
    ///   - variant: The chroma feature variant to extract.
    public init(pitchFeatureParameters: PitchFeatures.Parameters = .default,
                variant: Variant = .default)
    {
      self.pitchFeatureParameters = pitchFeatureParameters
      self.variant = variant
    }

    /// The default set of parameters.
    public static var `default`: Parameters { return Parameters() }

  }

}

/// Accumulates the pitch energies into 12 subbands corresponding to the 12 chroma values.
///
/// - Parameters:
///   - pitchBuffer: The buffer of pitch vectors to process.
///   - compression: The settings for compressing the feature values or `nil`.
///   - normalization: The settings for normalizing the feature values or `nil`.
/// - Returns: A buffer with chroma features for each for frame.
private func extractChromaFeatures(from pitchBuffer: PitchBuffer,
                                   compression: CompressionSettings?,
                                   normalization: NormalizationSettings?) -> ChromaBuffer
{


  // Check if the pitch feature values should be compressed.
  if let compressionSettings = compression {

    // Apply compression.
    compress(buffer: pitchBuffer, settings: compressionSettings)

  }

  // Create a chroma buffer by accumulating values in `pitchBuffer`.
  let chromaBuffer = ChromaBuffer(source: pitchBuffer)

  // Check whether the features should be normalized.
  if let normalizationSettings = normalization {

    // Normalize the features.
    normalize(buffer: chromaBuffer, settings: normalizationSettings)

  }
  
  return chromaBuffer
  
}

/// Calculates and returns the CENS (Chroma Energy distribution Normalized Statistics)
/// features for the specified buffer of pitch vectors.
///
/// - Parameters:
///   - pitchBuffer: The buffer of pitch vectors to process.
///   - quantization: The steps and weights to use for the features.
///   - smoothing: The settings for smoothing feature values or `nil`.
/// - Returns: The CENS features extracted from `buffer`.
private func extractCENSFeatures(from pitchBuffer: PitchBuffer,
                                 quantization: QuantizationSettings,
                                 smoothing: SmoothingSettings?) -> ChromaBuffer
{

  // Get the chroma energies and frame count.
  let buffer = extractChromaFeatures(from: pitchBuffer,
                                     compression: nil,
                                     normalization: .lᵖNorm(space: .l¹, threshold: 0.001))

  // Normalize the energies with respect to each frame's ℓ¹ norm.
  normalize(buffer: buffer, settings: .lᵖNorm(space: .l¹, threshold: 0.001))

  quantize(buffer: buffer, settings: quantization)

  // Check whether smoothing or downsampling should be applied.
  guard let smoothingSettings = smoothing else {

    // Return the unsmoothed features at their current feature rate.
    return buffer
  }

  // Return the smoothed features.
  return smooth(buffer: buffer, settings: smoothingSettings)

}

/// Calculates and returns chroma DCT-reduced log pitch features for the specified buffer.
///
/// - Parameters:
///   - pitchBuffer: The buffer of pitch vectors to process.
///   - coefficients: The DCT coefficents to keep.
///   - smoothing: The settings for smoothing feature values or `nil`.
/// - Returns: The CRP features extracted from `buffer`.
private func extractCRPFeatures(from pitchBuffer: PitchBuffer,
                                coefficients: CountableRange<Int>,
                                smoothing: SmoothingSettings?) -> ChromaBuffer
{

  // Allocate memory for a 128 x 128 matrix.
  var dct = Float64Buffer.allocate(capacity: 128 * 128)

  // Precalculate the constant factor.
  let a = sqrt(2/Float64(128))

  // Help shorten the complex line of code below.
  let π = Float64.pi

  // Iterate concurrently over the first dimension of the matrix.
  DispatchQueue.concurrentPerform(iterations: 128) {
    m in

    // Iterate over the second dimension of the matrix.
    for n in 0 ..< 128 {

      // Cast `m` and `n` for use in the calculation.
      let mʹ = Float64(m)
      let nʹ = Float64(n)

      // Calculate the matrix value.
      let value = a * cos((mʹ * (nʹ + 0.5) * π) / 128)

      // Insert the value into the matrix.
      (dct + (m * 128 + n)).initialize(to: value)

    }

  }

  // Divide the first row of the matrix by √2.
  var squareRootOf2 = 1.414213562
  vDSP_vsdivD(dct, 1, &squareRootOf2, dct, 1, 128)

  // Allocate memory for copying `dct`.
  let dctCut = Float64Buffer.allocate(capacity: 16384)

  // Fill `dctCut` with zeros.
  vDSP_vclrD(dctCut, 1, 16384)

  // Calculate the number of values to copy.
  let copyCount = vDSP_Length(coefficients.count * 128)

  // Calculate the offset for the start of the values to copy.
  let offset = coefficients.lowerBound * 128

  // Copy the kept coefficients into `dctCut`.
  vDSP_mmovD(dct + offset, dctCut + offset, copyCount, 1, copyCount, copyCount)

  // Transpose `dct` before multiplying.
  dct.transpose(rowCount: 128, columnCount: 128)

  // Allocate memory for the filter.
  let dctFilter = Float64Buffer.allocate(capacity: 128 * 128)

  // Generate the filter by multiplying `dctᵀ` by `dctCut`.
  vDSP_mmulD(dct, 1, dctCut, 1, dctFilter, 1, 128, 128, 128)

  // Allocate memory for a contiguous copy of `pitchBuffer`.
  var pitchBufferʹ = Float64Buffer.allocate(capacity: 128 * pitchBuffer.count)

  // Iterate the buffer's frames.
  for frame in 0 ..< pitchBuffer.count {

    // Copy this frame's vector into the contiguous buffer.
    vDSP_mmovD(pitchBuffer.buffer[frame].storage, pitchBufferʹ + (frame * 128), 128, 1, 128, 128)

  }

  // Transpose `pitchBufferʹ` so the filter can be applied across frames for each pitch.
  pitchBufferʹ.transpose(rowCount: pitchBuffer.count, columnCount: 128)

  // Allocate memory for result of multiplying `pitchBufferʹ` by `dctFilter`.
  var pitchDCT = Float64Buffer.allocate(capacity: pitchBuffer.count * 128)

  // Apply the filter.
  vDSP_mmulD(dctFilter, 1,
             pitchBufferʹ, 1,
             pitchDCT, 1,
             128, vDSP_Length(pitchBuffer.count), 128)

  // Transpose the result back to row-major order where each row has values for one frame.
  pitchDCT.transpose(rowCount: 128, columnCount: pitchBuffer.count)

  let chromaDCT = ChromaBuffer(count: pitchBuffer.count, featureRate: pitchBuffer.featureRate)

  // Iterate through the frames.
  for frame in 0 ..< pitchBuffer.count {

    // Iterate through the pitch indices.
    for pitch in 0 ..< 128 {

      // Add the value for this pitch to the value for the pitch's chroma.
      chromaDCT.buffer[frame][pitch % 12] += pitchDCT[frame * 128 + pitch]

    }

    // Normalize the chroma values for this frame.
    normalize(vector: chromaDCT.buffer[frame], settings: .lᵖNorm(space: .l², threshold: 0.00001))

  }

  // Check whether smoothing or downsampling should be applied.
  guard let smoothingSettings = smoothing else {

    // Return the unsmoothed features at their current feature rate.
    return chromaDCT

  }

  // Return the smoothed and/or downsampled features.
  return smooth(buffer: chromaDCT, settings: smoothingSettings)

}
