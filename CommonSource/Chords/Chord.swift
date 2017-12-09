//
//  Chord.swift
//  Chord Finder
//
//  Created by Jason Cardwell on 7/31/17.
//  Copyright (c) 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import Accelerate

/// A structure for representing a chord in Western music. Static constants are declared for
/// around 75 standard chords all with C as root. The chord's pattern would be the same across
/// the 12 choices for root. For a template with a root other than C, one should be able to
/// shift the values in the template's vector and/or shift the template's chromas.
/// The naming of the static constants uses the following pattern:
/// 1) All start with 'C' to indicate that the `template` value corresponds to a root of C.
/// 2) 'M' is used to indicate major, 'm' for minor, 'aug' for augmented, 'dim' for diminished
///    and 'sus' for suspended.
/// 3) Intervals are indicated by their digit or double-digit value.
/// 4) '_' is used to replace parentheses and in place of a forward slash.
public struct Chord {

  /// A name or label describing the chord.
  public var name: String { return "\(root)\(pattern.suffix)" }

  /// The chord's root chroma value.
  public let root: Chroma

  /// The chord's pattern describing the intervals used in the chord's construction.
  public let pattern: ChordPattern

  /// The chroma template composed of the weighted chromas corresponding to `pattern`.
  public var template: ChromaTemplate { return ChromaTemplate(chord: self) }

  /// The chromas corresponding to the pattern intervals.
  public let chromas: [Chroma]

  /// The chromas that must be present to be considered the chord.
  public var criticalChromas: [Chroma] {

    // Create a mutable copy of `chromas`.
    var chromas = self.chromas

    // Get the index for the fifth or return all the chromas.
    guard let fifth = self[.P5], let index = chromas.index(of: fifth) else { return chromas }

    // Remove the fifth.
    chromas.remove(at: index)

    // Return the remaining chromas.
    return chromas

  }

  /// Initializing with a root for a chord and its pattern. Generates a chroma template using
  /// the specified chord pattern and root.
  ///
  /// - Parameters:
  ///   - root: The chroma value for the chord's root.
  ///   - pattern: The chord pattern.
  public init(root: Chroma, pattern: ChordPattern) {

    self.root = root
    self.pattern = pattern

    chromas = [root] + pattern.intervals.map({root.chroma(at: $0)})
    
  }

  /// Initializing with a root for the chord and a list of intervals. Creates a `ChordPattern`
  /// with the specified intervals and invokes `init(name:pattern:)`.
  ///
  /// - Parameters:
  ///   - root: The chroma value of the chord's root.
  ///   - intervals: The intervals, other than the implied `1`, composing the chord.
  public init(root: Chroma, _ intervals: PitchInterval...) {
    self.init(root: root, pattern: ChordPattern(intervals))
  }

  /// Provides the pitch interval for a member of `chromas` or `nil` if the specified chroma
  /// is not part of the chord.
  ///
  /// - Parameter chroma: The chroma whose interval is desired.
  /// - Returns: The interval of `chroma` or `nil` if `chroma` ∉ `chromas`.
  public func interval(for chroma: Chroma) -> PitchInterval? {

    // Get the index of `chroma` in `chromas` or return `nil`.
    guard let index = chromas.index(of: chroma) else { return nil }

    // Return the corresponding interval.
    return index == 0 ? PitchInterval(rawValue: 0) : pattern.intervals[index - 1]

  }

  /// Provides the pitch interval for a member of `chromas` or `nil` if the specified chroma
  /// is not part of the chord.
  ///
  /// - Parameter chroma: The chroma whose interval is desired.
  /// - Returns: The interval of `chroma` or `nil` if `chroma` ∉ `chromas`.
  public subscript(chroma: Chroma) -> PitchInterval? {

    // Get the index of `chroma` in `chromas` or return `nil`.
    guard let index = chromas.index(of: chroma) else { return nil }

    // Return the corresponding interval.
    return index == 0 ? PitchInterval(rawValue: 0) : pattern.intervals[index - 1]

  }

  /// Accessor for the chroma at the specified interval. Returns `nil` if the chord does not
  /// include `interval`.
  ///
  /// - Parameter interval: The interval for which the chroma shall be returned.
  public subscript(interval: PitchInterval) -> Chroma? {

    // Check whether the interval is the root.
    guard interval.rawValue > 0 else { return root }

    // Check whether the chord pattern contains `interval`.
    guard pattern.contains(interval: interval) else { return nil }

    // Return the chroma at `interval` from `root`.
    return root.chroma(at:interval)

  }

  public var chromaRepresentation: ChromaVector {
    var vector = ChromaVector()
    for chroma in Set(chromas) {
      vector[chroma] = 1
    }
    return vector
  }

}

extension Chord: Hashable {

  public  static func ==(lhs: Chord, rhs: Chord) -> Bool {
    return lhs.root == rhs.root && lhs.pattern == rhs.pattern
  }

  public var hashValue: Int { return name.hashValue }

}

extension Chord: CustomStringConvertible {

  public var description: String { return name }

}

extension Chord: ExpressibleByStringLiteral {

  public init(stringLiteral value: String) {

    // Capture the root chroma and the suffix or initialize with a default of 'CM'.
    guard let match = (~/"([a-gA-G]♭?)(.+)").firstMatch(in: value),
          let chromaLiteral = match.captures[1]?.substring,
          let suffix = match.captures[2]?.substring
      else
    {
      self.init(root: .c, pattern: .﹡M)
      return
    }

    let root = Chroma(stringLiteral: String(chromaLiteral))
    let pattern = ChordPattern(stringLiteral: String(suffix))

    self.init(root: root, pattern: pattern)

  }

}

extension Chord: CustomReflectable {

  public var customMirror: Mirror {
    return Mirror(self, children: ["name": name, "root": root, "pattern": pattern])
  }

}
