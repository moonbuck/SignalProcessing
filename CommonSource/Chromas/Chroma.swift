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
/// - c: The C pitch class.
/// - dFlat: the D♭ pitch class.
/// - d: The D pitch class.
/// - eFlat: The E♭ pitch class.
/// - e: The E pitch class.
/// - f: The F pitch class.
/// - gFlat: The G♭ pitch class.
/// - g: The G pitch class.
/// - aFlat: The A♭ pitch class.
/// - a: The A pitch class.
/// - bFlat: The B♭ pitch class.
/// - b: The B pitch class.
public enum Chroma: Int {

  case c, dFlat, d, eFlat, e, f, gFlat, g, aFlat, a, bFlat, b

  /// Initializing with a `Chroma`'s raw value. To allow this initializer to always
  /// succeed, the value `|rawValue| modulo 7` is used in place of `rawValue`.
  ///
  /// - Parameter rawValue: The integer whose absolute value modulo `7` selects the
  ///                       `Chroma` case.
  public init(rawValue: Int) {
    switch rawValue {
      case 0: self = .c
      case 1: self = .dFlat
      case 2: self = .d
      case 3: self = .eFlat
      case 4: self = .e
      case 5: self = .f
      case 6: self = .gFlat
      case 7: self = .g
      case 8: self = .aFlat
      case 9: self = .a
      case 10: self = .bFlat
      case 11: self = .b
      default: self = Chroma(rawValue: abs(rawValue % 12))
    }
  }

  /// Calculates the chroma value at `interval` with the chroma serving as root.
  ///
  /// - Parameter interval: The interval at which the chroma value should be deduced.
  /// - Returns: The chroma at `interval`.
  public func chroma(at interval: PitchInterval) -> Chroma {
    return advanced(by: interval.semitones)
  }


  /// The set of chromas for the 3rd, 5th, 6th, and 7th partials.
  public var significantPartials: Set<Chroma> {
    return [advanced(by: 7), advanced(by: 4), advanced(by: 10)]
  }

  /// An array of all the chroma values in ascending order.
  public static let all: [Chroma] = [
    .c, .dFlat, .d, .eFlat, .e, .f, .gFlat, .g, .aFlat, .a, .bFlat, .b
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
      case .c:     return "C"
      case .dFlat: return "D♭"
      case .d:     return "D"
      case .eFlat: return "E♭"
      case .e:     return "E"
      case .f:     return "F"
      case .gFlat: return "G♭"
      case .g:     return "G"
      case .aFlat: return "A♭"
      case .a:     return "A"
      case .bFlat: return "B♭"
      case .b:     return "B"
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

      case "D♭", "d♭": self = .dFlat
      case "D", "d":   self = .d
      case "E♭", "e♭": self = .eFlat
      case "E", "e":   self = .e
      case "F", "f":   self = .f
      case "G♭", "g♭": self = .gFlat
      case "G", "g":   self = .g
      case "A♭", "a♭": self = .aFlat
      case "A", "a":   self = .a
      case "B♭", "b♭": self = .bFlat
      case "B", "b":   self = .b
      default:         self = .c

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
