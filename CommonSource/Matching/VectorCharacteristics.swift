//
//  VectorCharacteristics.swift
//  SignalProcessing
//
//  Created by Jason Cardwell on 9/17/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import Accelerate

/// Estimates the number of notes present in a chroma feature.
///
/// - Parameter feature: The feature for which to estimate the number of notes.
/// - Returns: The estimated note count for `feature`.
public func estimateNoteCount(for feature: ChromaVector) -> Int {

  // Calculate the sum of all the chroma energies.
  var sum = 0.0
  vDSP_sveD(feature.storage, 1, &sum, 12)

  // Calculate the contributions for each chroma.
  let contributions = Float64Buffer.allocate(capacity: 12)
  vDSP_vsdivD(feature.storage, 1, &sum, contributions, 1, 12)

  // Tuple the chromas with their contributions and sort.
  let chromaContributions = feature.indices.map({
    (chroma: Chroma(rawValue: $0), contribution: contributions[$0])
  }).sorted(by: {$0.contribution > $1.contribution})

  // Calculate a rough estimate based on the count of contributors above 13%.
  let roughEstimate = chromaContributions.filter({$0.contribution >= 0.13}).count

  return roughEstimate
  
}

/// Estimates the most likely root chroma in a feature returning a tuple with the estimated
/// root chroma based on frequency, the number of partials present, the sum of the energies for
/// partials present, and the averaged positions in sorted count and energy collections.
///
/// - Parameter feature: The feature for which to estimate the most likely root chroma.
/// - Returns: A tuple with the most likely root chroma for various bas
public func estimateRoot(for feature: PitchVector) -> PossibleRoots {

  // Create a variable for the possible roots.
  var possibleRoots: [Pitch] = []

  // Iterate through the raw pitch values until three possible roots have been found.
  for pitch in 0 ..< 128 where possibleRoots.count < 3 && feature[pitch] >= 0.18 {

    // Append the chroma for this pitch as a possible root.
    possibleRoots.append(Pitch(rawValue: pitch))

  }

  // Define the lowest pitch consider.
  let startingPitch = possibleRoots.first
                        ?? Pitch(rawValue: feature.enumerated().first(where: {$1 > 0})?.offset ?? 0)

  // Create the range of pitches to look at.
  let pitchRange = (possibleRoots.first ?? 0) ..< 128

  // Create a collection of tuples composed of the pitch, the number of its partials present, and
  // the sum of the energies for those partials.
  let pitches = pitchRange.map {
    pitch -> (pitch: Pitch, count: Int, energy: Float64) in

    // Get the partials with energy ≥ `0`.
    let partials = pitch.partials.filter({feature[$0] > 0})

    // Calculate the sum of the energies for `partials`.
    let energy = partials.reduce(0.0, {$0 + feature[$1]})

    return (pitch: pitch, count: partials.count, energy: energy)

  }

  // Create a copy of `pitches` sorted in descending order by partial count.
  let byCount = pitches.sorted { $0.count > $1.count }

  // Create a copy of `pitches` sorted in descending order by energy.
  let byEnergy = pitches.sorted { $0.energy > $1.energy }

  // Create a collection of tuples composed of the pitch and the average of its index in `byCount`
  // and its index in `byEnergy`.
  let pitchIndexes = pitchRange.map {
    pitch -> (pitch: Pitch, averageIndex: Int) in

    // Get the index of `pitch` within `byCount`.
    let countIndex = byCount.index(where: { $0.pitch == pitch })!

    // Get the index of `pitch` within `byEnergy`.
    let energyIndex = byEnergy.index(where: { $0.pitch == pitch })!

    // Calculate the average with energy weighted greater than count.
    let averageIndex = (countIndex + energyIndex * 2) / 3

    return (pitch: pitch, averageIndex: averageIndex)

  }

  // Create a list of the pitches in descending order according to average index.
  let byAverageIndex = pitchIndexes.sorted { $0.averageIndex < $1.averageIndex }

  // Get the chroma for the first pitch by count.
  let count = byCount[0].pitch.chroma

  // Get the chroma for the first pitch by energy.
  let energy = byEnergy[0].pitch.chroma

  // Get the chroma for the first pitch by averaged indices.
  let average = byAverageIndex[0].pitch.chroma

  return PossibleRoots(byFrequency: startingPitch, byCount: count, byEnergy: energy, averaged: average)

}
