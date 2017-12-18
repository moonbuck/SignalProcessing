//
//  ChromaTemplate.swift
//  Chord Finder
//
//  Created by Jason Cardwell on 8/01/17.
//  Copyright (c) 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import Accelerate

/// Structure for coupling a `ChromaVector` with the chromas serving as the source of the
/// vector's weighted values.
public struct ChromaTemplate {

  /// Constant used in weighting values for partials.
  public static var α: Float64 = 0.9

  /// The chord represented by `vector`.
  public let chord: Chord

  /// The vector of values weighted for `chromas`.
  public let vector: ChromaVector

  /// Intializing with a chord.
  public init(chord: Chord) {

    // Initialize the `chord` property.
    self.chord = chord

    // Check that there is at least one chroma value.
    guard !chord.chromas.isEmpty else {
      vector = ChromaVector()
      return
    }

    // Check that there is more than one chroma value.
    guard chord.chromas.count > 1 else {
      vector = ChromaTemplate.vector(weightedFor: chord.root)
      return

    }

    // Allocate enough storage for a weighted vector for each chroma value.
    let vectors = UnsafeMutablePointer<ChromaVector>.allocate(capacity: chord.chromas.count)

    // Calculate a vector for each chroma concurrently.
    DispatchQueue.concurrentPerform(iterations: chord.chromas.count) {

      // Initialize a vector for this iteration weighted for this iteration's chroma value.
      (vectors + $0).initialize(to: ChromaTemplate.vector(weightedFor: chord.chromas[$0]))
    }

    // Initialize `vector` to the sum of `vectors`.
    vector = UnsafeBufferPointer(start: vectors,
                                 count: chord.chromas.count).reduce(ChromaVector(), +)

    // Normalize the vector.
    normalize(vector: vector, settings: .lᵖNorm(space: .l¹, threshold: 0.001))

  }

  /// Creates a new chroma vector weighted for a single chroma value.
  ///
  /// - Parameter root: The chroma value for which the vector will be weighted.
  /// - Returns: A chroma vector weighted for `root`.
  private static func vector(weightedFor root: Chroma) -> ChromaVector {

    // Create an empty chroma vector.
    let vector = ChromaVector()

    // Iterate through the first 8 partials.
    for k in 1...8 {

      // Add αᵏ⁻¹ to the value stored in the vector for `chroma`.
      vector[root[k]] += pow(α, Float64(k - 1))

    }

    // Boost the root up over the partials.
    vector[root] += 1

    return vector

  }

}

extension ChromaTemplate: CustomStringConvertible {

  public var description: String {
    let chromas = chord.chromas.map({$0.description}).joined(separator: "-")
    return "\(chord) (\(chromas)): \(vector.description)"
  }

}

extension ChromaTemplate: CustomReflectable {

  public var customMirror: Mirror {
    return Mirror(self, children: ["chord": chord, "chromas": chord.chromas, "vector": vector])
  }

}
