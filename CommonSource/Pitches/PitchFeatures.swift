//
//  PitchFeatures.swift
//  Chord Finder
//
//  Created by Jason Cardwell on 8/04/17.
//  Copyright (c) 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import Accelerate
import AVFoundation

/// A collection of an audio signal's per-frame per-pitch energy in the form of STMSP.
public struct PitchFeatures: ParameterizedFeatureCollection {

  /// An array with the vectors holding pitch energies.
  public let features: [PitchVector]

  /// The number of features per second.
  public let featureRate: Float

  /// The parameters that were used to extract `features`.
  public let parameters: Parameters

  /// The index for the first pitch feature.
  public let startIndex: Int = 0

  /// The index after the last pitch feature.
  public var endIndex: Int { return features.endIndex }

  /// The total number of pitch features.
  public var count: Int { return features.count }

  /// The most likely root chromas per frame as a tuple of the most likely by count, by energy,
  /// and by the averaged count and energy rankings.
  public let mostLikelyRoots: [PossibleRoots]

  /// The estimated number of notes per frame.
  public let noteCountEstimates: [Int]

  /// Returns the successor for the specified index.
  ///
  /// - Parameter i: The index whose successor should be returned.
  /// - Returns: The successor for `i`.
  public func index(after i: Int) -> Int { return i &+ 1 }

  /// Accessor for the pitch feature at a specific index.
  ///
  /// - Parameter position: The index of the pitch feature to retrieve.
  public subscript(position: Int) -> PitchVector { return features[position] }

  /// Accessor for the pitch feature at a specific index.
  ///
  /// - Parameter pitch: The pitch whose feature is to be returned.
  public subscript(pitch: Pitch) -> PitchVector { return self[pitch.rawValue] }

  /// Initializing with a buffer.
  public init(_ buffer: PitchBuffer, _ parameters: Parameters) {
    features = buffer.array
    featureRate = buffer.featureRate
    self.parameters = parameters
    mostLikelyRoots = features.map(estimateRoot(for:))
    noteCountEstimates = Array<Int>(repeating: 3, count: features.count)
  }

  /// Initializing with the URL for an audio file.
  ///
  /// - Parameters:
  ///   - url: The URL for the audio file from which to extract pitch features.
  ///   - parameters: The parameters to use during extration.
  /// - Throws: Any error thrown while filling a buffer with the content of `url`.
  public init(from url: URL, parameters: Parameters) throws {

    // Create a buffer from the PCM buffer.
    let buffer = (try AVAudioPCMBuffer(contentsOf: url)).mono64

    // Apply the equal loudness filter.
    EqualLoudnessFilter().process(signal: buffer)

    // Initialize using the buffer along with the specified parameters.
    self.init(from: buffer, parameters: parameters)

  }

  /// Initializing with a buffer of audio from which to extract the pitch features.
  ///
  /// - Parameters:
  ///   - buffer: The buffer for which the energy values are to be calculated.
  ///   - parameters: The parameter values to use during pitch extraction.
  public init(from buffer: AVAudioPCMBuffer, parameters: Parameters) {

    // Extract the pitch features.
    var pitchBuffer = PitchBuffer(from: buffer, method: parameters.method)

    // Apply the filters.
    for filter in parameters.filters { filter.filter(buffer: &pitchBuffer) }

    // Initialize with the buffer and parameters.
    self.init(pitchBuffer, parameters)

  }

  /// A structure for grouping various parameters used during pitch feature extraction.
  public struct Parameters {

    /// The method used to extract the pitch features from a buffer of audio.
    public var method: ExtractionMethod

    /// The filters to be applied to the extracted features.
    public var filters: [FeatureFilter]

    /// Initializing with default property values.
    public init(method: ExtractionMethod = .default, filters: [FeatureFilter] = []) {

      self.method = method
      self.filters = filters

    }

    public static var `default`: Parameters { return Parameters() }

  }

  /// An enumeration of the available methods that can be used to extract pitch features from
  /// a buffer of audio.
  /// - stft: Fast Fourier Transform based extraction.
  /// - filterbank: Filterbank based extraction.
  public indirect enum ExtractionMethod {

    case stft       (windowSize: Int, hopSize: Int, sampleRate: SampleRate)
    case filterbank (windowSize: Int, hopSize: Int)

    public static var `default`: ExtractionMethod {
      return .filterbank(windowSize: 4410, hopSize: 2205)
    }

  }


}

public struct PossibleRoots {

  let byFrequency: Pitch
  let byCount: Chroma
  let byEnergy: Chroma
  let averaged: Chroma

}



