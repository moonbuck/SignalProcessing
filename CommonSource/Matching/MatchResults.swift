//
//  MatchResults.swift
//  Chord Finder
//
//  Created by Jason Cardwell on 8/31/17.
//  Copyright (c) 2017 Moondeer Studios. All rights reserved.
//
import Foundation

/// A structure that takes a target chroma vector and scores its similarity against all available
/// chords.
public struct MatchResults {

  /// The chroma vector matched against all available chords.
  public let sourceVector: ChromaVector

  /// The chroma values most likely to be the root of the chord.
  public let mostLikelyRoots: PossibleRoots

  /// Adjustments applied to similarity scores.
  public let scoreAdjustments: [ScoreAdjustment]

  /// The scores index by chroma resulting from matching `sourceVector` against the chords.
  public let scores: [Chord:Float64]

  /// Initializing with a vector to match against the chords.
  /// - Parameters:
  ///   - sourceVector: The vector to match against all available chords.
  ///   - scoreAdjustments: Adjustments to apply to similarity scores.
  ///   - possibleRoots: An optional array of chroma values most likely to be the root of the chord.
  ///   - estimatedNoteCount: The estimated note count for `sourceVector`.
  public init(sourceVector: ChromaVector,
              scoreAdjustments: [ScoreAdjustment] = [],
              mostLikelyRoots: PossibleRoots,
              estimatedNoteCount: Int)
  {

    // Initialize the `mostLikelyRoots` property.
    self.mostLikelyRoots = mostLikelyRoots

    // Initialize the `scoreAdjustments` property.
    self.scoreAdjustments = scoreAdjustments

    // Initialize the `sourceVector` property.
    self.sourceVector = sourceVector

    // Create an empty dictionary for storing chords tupled with their scores indexed by chroma.
    var scores: [Chord:Float64] = [:]

    // Iterate the chromas and their chord sets.
    for (_, chords) in ChordLibrary.chords {

      // Insert the result of mapping `chords` to pair each chord with its score for `vector`.
      for chord in chords {

        scores[chord] = score(template: chord.template,
                              for: sourceVector,
                              adjustments: scoreAdjustments,
                              mostLikelyRoots: mostLikelyRoots,
                              estimatedNoteCount: estimatedNoteCount)
      }

    }

    // Initialize the `scores` property.
    self.scores = scores

  }

  /// Generates an array composed of chord-score tuples sorted by score in descending order.
  ///
  /// - Parameter count: The number of tuples to include in the result.
  /// - Returns: An array of chord-score tuples with `count` elements.
  public func maxScores(count: Int) -> [(Chord, Float64)] {

    // Ensure `count` is not `0` or negative.
    guard count > 0 else {

      // Just return an empty array.
      return []

    }

    // Transform `scores` into a sorted collection of tuples.
    let unifiedScores = scores.sorted(by: {$0.value > $1.value})

    // Return an array containing `unifiedScores` sliced according to `count`.
    return Array(unifiedScores[0..<min(count, unifiedScores.count)])

  }

  /// The chord-score tuple with the hightest score.
  public var maxScore: (Chord, Float64) { return scores.max(by: {$0.value < $1.value})! }

}
