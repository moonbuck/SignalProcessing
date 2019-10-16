//
//  FeatureBuffer.swift
//  Chord Finder
//
//  Created by Jason Cardwell on 8/04/17.
//  Copyright (c) 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import AVFoundation
import Accelerate

/// A protocol for types that wrap a buffer of `Float64Vector` values.
public protocol Float64VectorBufferWrapper: class, Collection {

  /// The type of `Float64Vector` of which the buffer is a collection.
  associatedtype Vector: ConstantSizeFloat64Vector

  /// The wrapped buffer.
  var buffer: UnsafeMutablePointer<Vector> { get }

  /// The number of vectors in `buffer`.
  var count: Int { get }

}

// Extension adding basic support for the `Collection` protocol.
extension Float64VectorBufferWrapper {

  public var startIndex: Int { return 0 }

  public var endIndex: Int { return count }

  public func index(after i: Int) -> Int { return i &+ 1 }

  public subscript(position: Int) -> Vector { return buffer[position] }

}

/// A protocol for types that serve as a collection of features with an associated feature rate.
public protocol FeatureCollection: Collection {

  /// The associated feature rate in Hertz.
  var featureRate: Float { get }

}

/// A protocol for type that conform to `FeatureCollection` and make available the parameters
/// that were used to extract the features it has collected.
public protocol ParameterizedFeatureCollection: FeatureCollection {

  /// The type used to express the features' extraction parameters.
  associatedtype Parameters

  /// The extraction parameters.
  var parameters: Parameters { get }

}

/// A wrapper for a buffer of `PitchVector` values, the total number of vectors and their
/// associated feature rate.
public final class FeatureBuffer<Vector>: FeatureCollection, Float64VectorBufferWrapper
  where Vector: ConstantSizeFloat64Vector
{

  /// A buffer of feature values.
  public let buffer: UnsafeMutablePointer<Vector>

  deinit {
    buffer.deallocate()
  }

  /// The number of feature vectors in `buffer`.
  public let count: Int

  /// The feature rate associated with `buffer`.
  public let featureRate: Float

  /// `buffer` converted to an array of chroma vectors.
  public var array: [Vector] { return Array(UnsafeBufferPointer(start: buffer, count: count)) }

  /// Initializing with an array of vectors and the associated feature rate.
  ///
  /// - Parameters:
  ///   - vectors: The vector values to copy into the new buffer.
  ///   - featureRate: The feature rate associated with the vectors.
  public init(vectors: [Vector], featureRate: Float) {
    buffer = UnsafeMutablePointer<Vector>.allocate(capacity: vectors.count)
    buffer.initialize(from: vectors, count: vectors.count)
    self.featureRate = featureRate
    count = vectors.count
  }

  /// Initializing with from a pointer, the number of vectors and the associated feature rate.
  ///
  /// - Parameters:
  ///   - buffer: A pointer to the first vector.
  ///   - frameCount: The total number of contiguous vectors.
  ///   - featureRate: The feature rate associated with the vectors.
  public init(buffer: UnsafeMutablePointer<Vector>, frameCount: Int, featureRate: Float) {
    self.buffer = buffer
    self.count = frameCount
    self.featureRate = featureRate
  }

  /// Initializing with the buffer's count and feature rate. `buffer` is initialized with `count` 
  /// zero-valued vectors.
  ///
  /// - Parameters:
  ///   - count: The number of vectors the buffer will hold.
  ///   - featureRate: The buffer's feature rate.
  public init(count: Int, featureRate: Float) {

    // Allocated memory for `frameCount` vectors.
    buffer = UnsafeMutablePointer<Vector>.allocate(capacity: count)

    // Fill the buffer with zero-valued vectors.
    for frame in 0 ..< count { (buffer + frame).initialize(to: Vector()) }

    // Update the `count` property.
    self.count = count

    // Update the `featureRate` property.
    self.featureRate = featureRate

  }
  
}

/// A typealias for a buffer of pitch feature vectors.
public typealias PitchBuffer = FeatureBuffer<PitchVector>

/// A typealias for a buffer of chroma feature vectors.
public typealias ChromaBuffer = FeatureBuffer<ChromaVector>

extension FeatureBuffer where Vector == PitchVector {

  /// Initializing by extracting pitch feature vectors from an audio signal.
  ///
  /// - Parameters:
  ///   - buffer: The buffer of audio from which to extract the features.
  ///   - method: The method of extraction to use.
  ///   - windowSize: The window size used during feature extraction.
  ///   - hopSize: The hop size used during feature extraction.
  public convenience init(from buffer: AVAudioPCMBuffer,
                          method: PitchFeatures.ExtractionMethod) throws
  {

    switch method {

      case let .filterbank(windowSize, hopSize):
        // Extraction via `MultirateFilterBank`.

        guard let multirateBuffer = try? MultirateAudioPCMBuffer(buffer: buffer) else {
          fatalError("Unable to create multirate buffer from the buffer provided.")
        }

        let (frames, frameCount, featureRate) =
          MultirateFilterBank.shared.extractPitchFeatures(from: multirateBuffer,
                                                          windowSize: windowSize,
                                                          hopSize: hopSize)
        
        self.init(buffer: frames, frameCount: frameCount, featureRate: featureRate)

      case let .stft(windowSize, hopSize, sampleRate, representation):
        // Extraction via Fast Fourier Transform.

        // Calculate the STFT.
        let stftResult = try STFT(windowSize: windowSize,
                                  hopSize: hopSize,
                                  buffer: buffer.mono64,
                                  representation: representation)

        // Allocate memory for the frames.
        let frames = UnsafeMutablePointer<PitchVector>.allocate(capacity: stftResult.count)

        // Retrieve the pitch vector of each frame.
        for (index, bins) in stftResult.enumerated() {
          (frames + index).initialize(to: PitchVector(bins: bins,
                                                      windowLength: windowSize,
                                                      sampleRate: sampleRate))
        }

        // Calculate the feature rate.
        let featureRate = Float(sampleRate.rawValue)/Float(windowSize - hopSize)

        self.init(buffer: frames, frameCount: stftResult.count, featureRate: featureRate)

    }

  }

  /// Full-width conversion from an instance of `PitchFeatures`.
  ///
  /// - Parameter features: The `PitchFeatures` instance to convert. 
  public convenience init(_ features: PitchFeatures) {

    // Initialize with `features` count and feature rate.
    self.init(count: features.count, featureRate: features.featureRate)

    for vectorIndex in 0 ..< features.count {

      (buffer + vectorIndex).initialize(to: PitchVector(features.features[vectorIndex]))

    }

  }

}

extension FeatureBuffer where Vector == ChromaVector {

  /// Initializing a chroma buffer by accumulating pitch vector values.
  ///
  /// - Parameter source: A collection of pitch vectors to reduce to chroma vectors.
  public convenience init<Source>(source: Source)
    where Source: FeatureCollection,
          Source.Iterator.Element == PitchVector,
          Source.Index == Int
  {

    self.init(count: source.count, featureRate: source.featureRate)

    // Iterate the frames.
    for frame in 0 ..< source.count {

      // Accumulate energy into chroma bands by iterating through pitches.
      for pitch in 0 ..< PitchVector.count {

        // Add the energy for this pitch in this frame to the bin for this pitch's chroma.
        buffer[frame][pitch % 12] += source[frame][pitch]

      }
      
    }
    
  }

  /// Full-width conversion from an instance of `ChromaFeatures`.
  ///
  /// - Parameter features: The `ChromaFeatures` instance to convert.
  public convenience init(_ features: ChromaFeatures) {

    // Initialize with `features` count and feature rate.
    self.init(count: features.count, featureRate: features.featureRate)

    for vectorIndex in 0 ..< features.count {

      (buffer + vectorIndex).initialize(to: ChromaVector(features.features[vectorIndex]))

    }

  }

}
