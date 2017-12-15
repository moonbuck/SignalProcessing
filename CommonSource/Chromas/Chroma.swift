//
//  Chroma.swift
//  Chord Finder
//
//  Created by Jason Cardwell on 7/30/17.
//  Copyright (c) 2017 Moondeer Studios. All rights reserved.
//
import Foundation

/// A type for specifying one of the twelve chromas, or pitch classes, of the equal-tempered scale.
///
/// - C: The C pitch class.
/// - Db: the D♭ pitch class.
/// - D: The D pitch class.
/// - Eb: The E♭ pitch class.
/// - E: The E pitch class.
/// - F: The F pitch class.
/// - Gb: The G♭ pitch class.
/// - G: The G pitch class.
/// - Ab: The A♭ pitch class.
/// - A: The A pitch class.
/// - Bb: The B♭ pitch class.
/// - B: The B pitch class.
public enum Chroma: Int {

  case C, Db, D, Eb, E, F, Gb, G, Ab, A, Bb, B

  /// Initializing with a `Chroma`'s raw value. To allow this initializer to always
  /// succeed, the value `|rawValue| modulo 12` is used in place of `rawValue`.
  ///
  /// - Parameter rawValue: The integer whose absolute value modulo `12` selects the
  ///                       `Chroma` case.
  public init(rawValue: Int) {
    switch rawValue {
      case 0: self = .C
      case 1: self = .Db
      case 2: self = .D
      case 3: self = .Eb
      case 4: self = .E
      case 5: self = .F
      case 6: self = .Gb
      case 7: self = .G
      case 8: self = .Ab
      case 9: self = .A
      case 10: self = .Bb
      case 11: self = .B
      default: self = Chroma(rawValue: abs(rawValue % 12))
    }
  }

  /// Calculates the chroma value at `interval` with the chroma serving as root.
  ///
  /// - Parameter interval: he interval at which the chroma value should be deduced.
  public subscript(interval: ChordInterval) -> Chroma {
    return advanced(by: interval.semitones)
  }

  /// The set of chromas for the 3rd, 5th, 6th, and 7th partials.
  public var significantPartials: Set<Chroma> {
    return [advanced(by: 7), advanced(by: 4), advanced(by: 10)]
  }

  /// An array of all the chroma values in ascending order.
  public static let all: [Chroma] = [
    .C, .Db, .D, .Eb, .E, .F, .Gb, .G, .Ab, .A, .Bb, .B
  ]

  /// Accessor the chroma of a one of the first `20` partials.
  ///
  /// - Parameter partial: The number for the partial to return.
  public subscript(partial: Int) -> Chroma {

    precondition((1...20).contains(partial),
                 "\(#function) `partial` must be a number from 1 through 20.")

    switch partial {
      case 3, 6, 12:  return advanced(by: 7)
      case 5, 10, 20: return advanced(by: 4)
      case 7, 14:     return advanced(by: 10)
      case 9, 18:     return advanced(by: 2)
      case 11:        return advanced(by: 6)
      case 13:        return advanced(by: 8)
      case 15:        return advanced(by: 11)
      case 17:        return advanced(by: 1)
      case 19:        return advanced(by: 3)
      default:        return self
    }

  }

}

extension Chroma: CustomStringConvertible {

  /// The string representation for the chroma, composed of the capitalized pitch letter and a
  /// trailing '♭' when appropriate.
  public var description: String {
    switch self {
      case .C:  return "C"
      case .Db: return "D♭"
      case .D:  return "D"
      case .Eb: return "E♭"
      case .E:  return "E"
      case .F:  return "F"
      case .Gb: return "G♭"
      case .G:  return "G"
      case .Ab: return "A♭"
      case .A:  return "A"
      case .Bb: return "B♭"
      case .B:  return "B"
    }
  }

}

extension Chroma: ExpressibleByIntegerLiteral {

  /// Initializing with an integer literal. Uses `value` to invoke `init(rawValue:)`.
  public init(integerLiteral value: Int) { self.init(rawValue: value) }

}

extension Chroma: ExpressibleByStringLiteral {

  /// Initializing with a chroma's description.
  ///
  /// - Parameter value: The chroma's description.
  public init(stringLiteral value: String) {

    switch value {

      case "D♭", "d♭", "Db", "db": self = .Db
      case "D", "d":               self = .D
      case "E♭", "e♭", "Eb", "eb": self = .Eb
      case "E", "e":               self = .E
      case "F", "f":               self = .F
      case "G♭", "g♭", "Gb", "gb": self = .Gb
      case "G", "g":               self = .G
      case "A♭", "a♭", "Ab", "ab": self = .Ab
      case "A", "a":               self = .A
      case "B♭", "b♭", "Bb", "bb": self = .Bb
      case "B", "b":               self = .B
      default:                     self = .C

    }

  }

}

extension Chroma: Strideable {

  /// Advances the chroma by a specified amount along the equal-tempered scale.
  ///
  /// - Parameter amount: The number of chromas to advance.
  /// - Returns: The chroma advanced by `amount`.
  public func advanced(by amount: Int) -> Chroma { return Chroma(rawValue: rawValue + amount) }

  /// Returns the distance between two chroma values using the difference of their raw values.
  ///
  /// - Parameter other: The chroma to which the distance will be calculated.
  /// - Returns: The distance from the chroma to `other`.
  public func distance(to other: Chroma) -> Int { return other.rawValue - rawValue }

}
