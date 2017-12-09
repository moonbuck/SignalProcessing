//
//  MatchedChromaFeatures.swift
//  Chord Finder
//
//  Created by Jason Cardwell on 9/11/17.
//  Copyright (c) 2017 Moondeer Studios. All rights reserved.
//
import Foundation

public struct MatchedChromaFeatures: Collection {

  /// The matched chroma features, normalized so that each vector has a sum of `1`.
  public let features: ChromaFeatures

  /// The feature rate for `features` in Hz.
  public var featureRate: Float { return features.featureRate }

  /// The match results that correspond with `features`.
  public let matchResults: [MatchResults]

  /// Adjustments applied to similarity scores.
  public let scoreAdjustments: [ScoreAdjustment]

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

  /// Accessor for the match results for a specific frame.
  ///
  /// - Parameter position: The index of the match results to retrieve.
  public subscript(position: Int) -> MatchResults { return matchResults[position] }

  /// Initializing with a collection of chroma features and, optionally, the lists of possible
  /// roots for each frame.
  ///
  /// - Parameters:
  ///   - features: The chroma features to match.
  ///   - mostLikelyRoots: The possible root chromas for each frame.
  ///   - noteCountEstimates: The estimated note count for each feature.
  ///   - scoreAdjustments: Adjustments to apply to similarity scores.
  public init(features: ChromaFeatures,
//              mostLikelyRoots: [PossibleRoots],
//              noteCountEstimates: [Int],
              scoreAdjustments: [ScoreAdjustment] = [])
  {

    // Create a deep copy of `features` so they an be normalized.
    let featuresBuffer = ChromaBuffer(features)

    // Normalize the features before matching against templates.
    normalize(buffer: featuresBuffer, settings: .lᵖNorm(space: .l¹, threshold: 0.001))

    let normalizedFeatures = ChromaFeatures(featuresBuffer, features.parameters)

    // Create an array for holding the match results.
    var matchResults: [MatchResults] = []
    matchResults.reserveCapacity(normalizedFeatures.count)

    // Iterate the enumerated features.
    for (/*frame*/_, vector) in normalizedFeatures.enumerated() {

      // Match the normalized vector against the chord templates.
      let results = MatchResults(sourceVector: vector,
                                 scoreAdjustments: scoreAdjustments//,
//                                 mostLikelyRoots: mostLikelyRoots[frame],
//                                 estimatedNoteCount: noteCountEstimates[frame]
      )

      // Append the results for this frame.
      matchResults.append(results)

    }

    // Initialize the property values.
    self.features = normalizedFeatures
    self.matchResults = matchResults
    self.scoreAdjustments = scoreAdjustments

  }

  /// Initializing from an instance of `Features`.
  ///
  /// - Parameter features: The `Features` instance from which to retrieve the chroma features,
  ///                       possible roots, and similarity score parameters.
  public init(features: Features) {

    self.init(features: features.chromaFeatures,
//              mostLikelyRoots: features.smoothedPitchFeatures.mostLikelyRoots,
//              noteCountEstimates: features.smoothedPitchFeatures.noteCountEstimates,
              scoreAdjustments: features.recipe.scoreAdjustments)

  }

}
