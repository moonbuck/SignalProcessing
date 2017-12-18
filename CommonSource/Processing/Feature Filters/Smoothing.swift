//
//  Smoothing.swift
//  Chord Finder
//
//  Created by Jason Cardwell on 8/23/17.
//  Copyright (c) 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import Accelerate

/// A simple structure encapsulating smoothing parameter values.
public struct SmoothingSettings {

  /// The size of the window used as a FIR filter. Use `1` to prevent filtering.
  public var windowSize: Int

  /// The decimation factor used in downsampling. Use `1` to preserve the current feature rate.
  public var downsampleFactor: Int

  /// Initializing with default property values.
  ///
  /// - Parameters:
  ///   - windowSize: The size of the window used as a FIR filter. Use `1` to prevent filtering.
  ///   - downsampleFactor: The decimation factor used in downsampling. Use `1` to preserve the
  ///                       current feature rate.
  public init(windowSize: Int = 21, downsampleFactor: Int = 5) {
    self.windowSize = windowSize
    self.downsampleFactor = downsampleFactor
  }

  public static var `default`: SmoothingSettings { return SmoothingSettings() }

}

/// Smooths and/or downsamples a buffer of `Float64Vector` values.
///
/// - Parameters:
///   - buffer: The buffer of chroma features to smooth and/or downsample.
///   - settings: The parameters to use when smoothing and/or downsampling.
/// - Returns: A buffer of processed chroma features.
public func smooth<Vector>(buffer: FeatureBuffer<Vector>,
                   settings: SmoothingSettings) -> FeatureBuffer<Vector>
{

  let vcount = Vector.count
  let vcountu = vDSP_Length(vcount)

  // Allocate memory for a contiguous copy of `buffer`.
  var columns = Float64Buffer.allocate(capacity: buffer.count * vcount)

  // Iterate the buffer's frames.
  for frame in 0 ..< buffer.count {

    // Copy this frame's vector into the contiguous buffer.
    vDSP_mmovD(buffer.buffer[frame].storage,
               columns + (frame * vcount),
               vcountu,
               1,
               vcountu,
               vcountu)

  }

  // Calculate the amount of zero-padding needed.
  let padAmount = settings.windowSize - 1

  // Transpose the buffer to column-major order.
  columns.transpose(rowCount: buffer.count, columnCount: vcount, pad: padAmount)

  // Create a Hanning window to use for a FIR filter.
  var window = Float64Buffer.allocate(capacity: settings.windowSize + 1)
  vDSP_hann_windowD(window, vDSP_Length(settings.windowSize + 1), Int32(vDSP_HANN_NORM))

  // Move the window past the leading `0`.
  window = window + 1

  // Normalize the window with respect to it's ℓ₁ norm.
  normalize(vector: window, count: settings.windowSize, settings: .lᵖNorm(space: .l¹, threshold: 0))

  // Calculate the new frame count after decimation.
  let newRowCount = Int((Float(buffer.count)/Float(settings.downsampleFactor)).rounded(.up))

  // Create a contiguous buffer to hold the downsampled/filtered values.
  var columnsʹ = Float64Buffer.allocate(capacity: newRowCount * vcount)

  // Iterate the column indices since `columns` is transposed.
  for column in 0 ..< vcount {

    // Filter and decimate the frame values for the chroma band.
    vDSP_desampD(columns + (column * (buffer.count + padAmount)),
                 settings.downsampleFactor,
                 window,
                 columnsʹ + (column * newRowCount),
                 vDSP_Length(newRowCount),
                 vDSP_Length(settings.windowSize))

  }

  // Transpose the buffer of downsampled/filtered values back to row-major order.
  columnsʹ.transpose(rowCount: vcount, columnCount: newRowCount)

  // Allocate memory for a buffer of chroma features.
  let processedBuffer = UnsafeMutablePointer<Vector>.allocate(capacity: newRowCount)

  // Iterate the new frame count.
  for frame in 0 ..< newRowCount {

    let vector = Vector(storage: columnsʹ + (frame * vcount), assumeOwnership: true)

    normalize(vector: vector, settings: .lᵖNorm(space: .l², threshold: 0.001))

    // Initialize this frame's chroma features.
    (processedBuffer + frame).initialize(to: vector)

  }

  // Adjust group delay?

  return FeatureBuffer(buffer: processedBuffer,
                       frameCount: newRowCount,
                       featureRate: buffer.featureRate / Float(settings.downsampleFactor))

}

/// Smooths and/or downsamples a buffer of `Float64Vector` values.
///
/// - Parameters:
///   - buffer: The buffer of chroma features to smooth and/or downsample.
///   - settings: The parameters to use when smoothing and/or downsampling.
/// - Returns: A buffer of processed chroma features.
public func smooth<Source>(source: Source, settings: SmoothingSettings) -> [Source.Element]
  where Source: Collection, Source.Element: Float64Vector,
        Source.IndexDistance == Int, Source.Index == Int
{

  // Determine the count by using the smallest vector.
  guard let vcount = source.map({$0.count}).min() else { return [] }

  let vcountu = vDSP_Length(vcount)

  // Allocate memory for a contiguous copy of `buffer`.
  var columns = Float64Buffer.allocate(capacity: source.count * vcount)

  // Iterate the buffer's frames.
  for frame in 0 ..< source.count {

    // Copy this frame's vector into the contiguous buffer.
    vDSP_mmovD(source[frame].storage,
               columns + (frame * vcount),
               vcountu,
               1,
               vcountu,
               vcountu)

  }

  // Calculate the amount of zero-padding needed.
  let padAmount = settings.windowSize - 1

  // Transpose the buffer to column-major order.
  columns.transpose(rowCount: source.count, columnCount: vcount, pad: padAmount)

  // Create a Hanning window to use for a FIR filter.
  var window = Float64Buffer.allocate(capacity: settings.windowSize + 1)
  vDSP_hann_windowD(window, vDSP_Length(settings.windowSize + 1), Int32(vDSP_HANN_NORM))

  // Move the window past the leading `0`.
  window = window + 1

  // Normalize the window with respect to it's ℓ₁ norm.
  normalize(vector: window, count: settings.windowSize, settings: .lᵖNorm(space: .l¹, threshold: 0))

  // Calculate the new frame count after decimation.
  let newRowCount = Int((Float(source.count)/Float(settings.downsampleFactor)).rounded(.up))

  // Create a contiguous buffer to hold the downsampled/filtered values.
  var columnsʹ = Float64Buffer.allocate(capacity: newRowCount * vcount)

  // Iterate the column indices since `columns` is transposed.
  for column in 0 ..< vcount {

    // Filter and decimate the frame values for the chroma band.
    vDSP_desampD(columns + (column * (source.count + padAmount)),
                 settings.downsampleFactor,
                 window,
                 columnsʹ + (column * newRowCount),
                 vDSP_Length(newRowCount),
                 vDSP_Length(settings.windowSize))

  }

  // Transpose the buffer of downsampled/filtered values back to row-major order.
  columnsʹ.transpose(rowCount: vcount, columnCount: newRowCount)

  // Allocate memory for a buffer of chroma features.
  let processedBuffer = UnsafeMutablePointer<Source.Element>.allocate(capacity: newRowCount)

  // Iterate the new frame count.
  for frame in 0 ..< newRowCount {

    let vector = Source.Element(storage: columnsʹ + (frame * vcount),
                                count: vcount,
                                assumeOwnership: true)

    normalize(vector: vector.storage,
              count: vcount,
              settings: .lᵖNorm(space: .l², threshold: 0.001))

    // Initialize this frame's chroma features.
    (processedBuffer + frame).initialize(to: vector)

  }

  return Array(UnsafeBufferPointer(start: processedBuffer, count: newRowCount))

}

