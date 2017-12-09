//
//  Scoring.swift
//  Chord Finder
//
//  Created by Jason Cardwell on 8/03/17.
//  Copyright (c) 2017 Moondeer Studios. All rights reserved.
//
import Foundation


/// Calculates the F score for the specified false negative and true/false positive counts.
/// If `TP` and `FP` are both `0`, the F score returned will be `0`.
///
/// - Parameters:
///   - TP: The number of true positives. A true positive is indicated by a correctly 
///         identified chord.
///   - FP: The number of false positives. A false positive is indicated by an incorrectly
///         identified chord.
///   - FN: The number of false negatives. A false negative is indicated by the failure to
///         identify any chord (correct or incorrect) when a chord was present.
/// - Returns: The F score given `TP`, `FP` and `FN`.
public func Fscore(TP: Int, FP: Int, FN: Int) -> Float {

  // Convert the arguments into `Float` values.
  let TP = Float(TP), FP = Float(FP), FN = Float(FN)

  // Calculate the precision.
  let P = TP / (TP + FP)

  // Calculate the recall.
  let R = TP / (TP + FN)

  // Return the F score calculate with `P` and `R`.
  return P.isNaN || R.isNaN ? 0 : (2 * P * R) / (P + R)

}

/// Generates a score indicating the similarity between the template's `vector` and `otherVector`.
/// The base score is calculated using the inner product of the two vectors. To this base score
/// bonuses and/or penalities are applied according to various characteristics of the two vectors.according
///
/// - Parameters:
///   - otherVector: The the vector to score.
///   - adjustments: Adjustments to apply to similarity scores.
///   - possibleRoots: A collection of the most likely chroma values to serve as root.
///   - estimatedNoteCount: The estimated note count for `otherVector`.
/// - Returns: The similarity score.
public func score(template: ChromaTemplate,
                  for otherVector: ChromaVector,
                  adjustments: [ScoreAdjustment]//,
//                  mostLikelyRoots: PossibleRoots,
//                  estimatedNoteCount: Int
  ) -> Float64
{

  // Create an evaluation that starts with a score set to the inner product of the vectors.
  var evaluation = TemplateEvaluation(template: template,
                                      otherVector: otherVector,
//                                      mostLikelyRoots: mostLikelyRoots,
//                                      estimatedNoteCount: estimatedNoteCount,
                                      score: otherVector ~ template.vector)

  for adjustment in adjustments {

    adjustment.adjust(evaluation: &evaluation)

  }

  return evaluation.score

}

/// A simple structure for the components necessary for generating a similarity score between a
/// chroma template and a chroma vector.
private struct TemplateEvaluation {

  /// The template being evaluated.
  let template: ChromaTemplate

  /// The vector being evaluated.
  let otherVector: ChromaVector

  /// The supplied root chroma candidates.
//  let mostLikelyRoots: PossibleRoots

  /// The estimated number of notes in `otherVector`.
//  let estimatedNoteCount: Int

  /// The resulting similarity score.
  var score: Float64

}

/// An enumeration encapsulating various similarity score adjustments.
public enum ScoreAdjustment {

  /// Adjusts a score on the basis of the estimated number of notes.
  ///
  /// `matchingBonus`: The bonus to apply should the number of notes match.
  case noteCount (matchingBonus: Float64)

  /// Adjusts a score on the basis of whether the chord root and any of the possible roots match.
  ///
  /// `matchingBonus`: Bonus applied to the score when roots are a match.
  ///
  /// `mismatchPenalty`: Penalty applied to the score when the roots are a mismatch.
  ///
  /// `highEnergyThreshold`: The threshold required to consider a value 'high energy'.
  ///
  /// `highEnergyBonus`: The additional bonus when a 'high energy' root is matched.
  case chordRoot (matchingBonus: Float64,
                  mismatchPenalty: Float64,
                  highEnergyThreshold: Float64,
                  highEnergyBonus: Float64)

  /// Adjusts a score on the basis of how the vector energies are distributed.
  ///
  /// `absentChromaThreshold`: The threshold below which a chroma is considered missing.
  ///
  /// `matchingChromasBonus`: Bonus applied when the top energy chromas from each vector match.
  ///
  /// `highEnergyThreshold`: Values ≥ to this threshold will be considered 'high energy'.
  ///
  /// `highEnergyBonus`: Bonus applied for matching a 'high energy' chroma.
  ///
  /// `highEnergyPenalty`: Penalty applied for a 'high energy' chroma mismatch.
  case energyDistribution (absentChromaThreshold: Float64,
                           matchingChromasBonus: Float64,
                           highEnergyThreshold: Float64,
                           highEnergyBonus: Float64,
                           highEnergyPenalty: Float64)

  public static var defaultAdjustments: [ScoreAdjustment] {
    return [
      .noteCount(matchingBonus: 0.1),
      .chordRoot(matchingBonus: 0.2,
                 mismatchPenalty: 0.2,
                 highEnergyThreshold: 0.3,
                 highEnergyBonus: 0.2),
      .energyDistribution(absentChromaThreshold: 0.1,
                          matchingChromasBonus: 0.2,
                          highEnergyThreshold: 0.2,
                          highEnergyBonus: 0.1,
                          highEnergyPenalty: 0.1)
    ]
  }

  /// Adjusts the score for an evaluation according to the case criteria.
  ///
  /// - Parameter evaluation: The evaluation to have its score adjusted.
  fileprivate func adjust(evaluation: inout TemplateEvaluation) {

    switch self {

      case let .noteCount(matchingBonus):
        noteCountAdjustment(evaluation: &evaluation, matchingBonus: matchingBonus)

      case let .chordRoot(bonus, penalty, threshold, energyBonus):
        chordRootAdjustment(evaluation: &evaluation,
                            matchingBonus: bonus,
                            mismatchPenalty: penalty,
                            highEnergyThreshold: threshold,
                            highEnergyBonus: energyBonus)
      case let .energyDistribution(absent, matching, threshold, bonus, penalty):
        energyDistributionAdjustment(evaluation: &evaluation,
                                     absentChromaThreshold: absent,
                                     matchingChromasBonus: matching,
                                     highEnergyThreshold: threshold,
                                     highEnergyBonus: bonus,
                                     highEnergyPenalty: penalty)

    }

  }

}

/// Estimates the number of notes in `evaluation.otherVector` and applies a bonus if this number
/// matches the number of notes in the template's chord.
///
/// - Parameters:
///   - evaluation: The evaluation to adjust.
///   - matchingBonus: The bonus to apply should the number of notes match.
private func noteCountAdjustment(evaluation: inout TemplateEvaluation, matchingBonus: Float64) {

/*
  // Check whether the estimate matches the number of notes in the template's chord.
  if evaluation.template.chord.chromas.count == evaluation.estimatedNoteCount {

    // Apply a bonus for the matching note count.
    evaluation.score += matchingBonus

  }
*/

}

/// Adjusts the score of the evaluation on the basis of similarity between the template's chord's
/// root and the list of possible roots.
///
/// - Parameters:
///   - evaluation: The evaluation to adjust.
///   - matchingBonus: Bonus applied to the score when roots are a match.
///   - mismatchPenalty: Penalty applied to the score when the roots are a mismatch.
///   - highEnergyThreshold: The threshold required to consider a value 'high energy'.
///   - highEnergyBonus: The additional bonus when a 'high energy' root is matched.
private func chordRootAdjustment(evaluation: inout TemplateEvaluation,
                                 matchingBonus: Float64,
                                 mismatchPenalty: Float64,
                                 highEnergyThreshold: Float64,
                                 highEnergyBonus: Float64)
{
/*
  if evaluation.mostLikelyRoots.byFrequency.chroma == evaluation.template.chord.root {

    evaluation.score += matchingBonus

  } else {

    evaluation.score -= mismatchPenalty

  }
*/

//  // Convert the tuple of most likely root chromas into an array.
//  let possibleRoots = [evaluation.mostLikelyRoots.byFrequency.chroma,
//                       evaluation.mostLikelyRoots.averaged,
//                       evaluation.mostLikelyRoots.byEnergy,
//                       evaluation.mostLikelyRoots.byCount]
//
//  // Check whether any of the possible roots contains a substantial amount of energy.
//  // TODO: The literal used as the threshold needs to be or be related to a variable of some sort.
//  if let root = possibleRoots.first(where: {evaluation.otherVector[$0] >= 0.35}) {
//
//    // Check if the roots match.
//    if evaluation.template.chord.root == root {
//
//      // Multiply the bonus by three and apply to score.
//      evaluation.score += matchingBonus * 3 + highEnergyBonus
//
//    }
//
//      // Otherwise apply a penalty.
//    else {
//
//      // Penalize the score.
//      evaluation.score -= mismatchPenalty
//
//    }
//
//  }
//
//  // Otherwise, check whether `root` is included in `possibleRoots` by retrieving its index.
//  else if let rootIndex = possibleRoots.index(of: evaluation.template.chord.root) {
//
//    // Apply a bonus based on `rootIndex`
//    switch rootIndex {
//
//      case 0:
//        // Apply the matching root bonus to score.
//        evaluation.score += matchingBonus
//
//        // Fallthrough to apply `matchingRootBonus` two more times and test for high energy.
//        fallthrough
//
//      case 1:
//        // Apply the matching root bonus to score.
//        evaluation.score += matchingBonus
//
//        // Fallthrough to apply `matchingRootBonus` one more time and test for high energy.
//        fallthrough
//
//      default:
//        // Apply the bonus to the score.
//        evaluation.score += matchingBonus
//
//        // Check whether the root's energy qualifies as high root energy.
//        if evaluation.otherVector[rootIndex] >= highEnergyThreshold {
//
//          // Apply the high root energy bonus.
//          evaluation.score += highEnergyBonus
//
//        }
//
//    }
//
//  }
//
//  // Otherwise apply a penalty for the mismatch of the root.
//  else {
//
//    // Penalize the score.
//    evaluation.score -= mismatchPenalty
//
//  }

}

/// Adjusts an evaluation's score on the basis of how the energy is distributed in the template
/// and in the other vector.
///
/// - Parameters:
///   - evaluation: The evaluation to adjust.
///   - absentChromaThreshold: The threshold below which a chroma is considered missing.
///   - matchingChromasBonus: Bonus applied when the top energy chromas from each vector match.
///   - highEnergyThreshold: Values ≥ to this threshold will be considered 'high energy'.
///   - highEnergyBonus: Bonus applied for matching a 'high energy' chroma.
///   - highEnergyPenalty: Penalty applied for a 'high energy' chroma mismatch.
private func energyDistributionAdjustment(evaluation: inout TemplateEvaluation,
                                          absentChromaThreshold: Float64,
                                          matchingChromasBonus: Float64,
                                          highEnergyThreshold: Float64,
                                          highEnergyBonus: Float64,
                                          highEnergyPenalty: Float64)
{

  // Look for chromas that are ≥ 0.3 in `otherVector` that are ≤ 0.01 in `vector`.
  guard evaluation.otherVector.chromas(ordered: .orderedDescending, threshold: 0.3)
          .first(where: {evaluation.template.vector[$0] <= 0.01}) == nil
    else
  {
    evaluation.score = 0
    return
  }

  // Create a set of the chord's chromas and critical chromas.
  let chordChromas = Set(evaluation.template.chord.chromas)
  let chordCriticalChromas = Set(evaluation.template.chord.criticalChromas)

  // Assess whether one of the chord's critical chromas is missing energy in `otherVector`.
  let absentChromaDetected = chordCriticalChromas.first(where: {
    evaluation.otherVector[$0] < absentChromaThreshold
  }) != nil

  // Calculate the number of high value chromas from `otherVector` to retrieve.
  let highValueCount = min(12, chordChromas.count + 1)

  // Apply a bonus if all of the chord's chromas are present in `otherHighValueChromas`.
  if chordCriticalChromas.isSubset(of: Set(evaluation.otherVector.chromasByValue[0..<highValueCount])) {
    evaluation.score += matchingChromasBonus
  }

  // Iterate the indices of other vector ordered by value.
  for otherChroma in evaluation.otherVector.chromas(ordered: .orderedDescending, threshold: 0.2) {

    // Check whether the template has high energy at the same index.
    if evaluation.template.vector[otherChroma] >= highEnergyThreshold {

      // Apply a bonus to the score.
      evaluation.score += highEnergyBonus

    } else {

      // Otherwise, apply a penalty.
      evaluation.score -= highEnergyPenalty * (evaluation.otherVector[otherChroma] >= 0.3 ? 2 : 1)

      // Return an automatic `0` if `absentChromaDetected == true`.
      guard !absentChromaDetected else {

        evaluation.score = 0
        return

      }

    }

  }

}
