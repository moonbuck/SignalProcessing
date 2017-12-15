//
//  ChordInterval.swift
//  Chord Finder
//
//  Created by Jason Cardwell on 7/31/17.
//  Copyright (c) 2017 Moondeer Studios. All rights reserved.
//
import Foundation

/// A type for specifying the interval between a chord root and a chord member. The raw
/// value of the `Interval` cases are identical to the raw value of a `ChordPattern` composed
/// only of the corresponding `Interval`.
///
/// The raw value uses the 24 least significant bits where each interval from 2 through 13
/// is represented with 2 bits. Flat intervals are represented by `01`. Natural intervals
/// are represented by `10`. Sharp intervals are represented by `11`.
///
/// The number of whole steps between intervals is as follows:
///
/// I-1-II-1-III-½-IV-1-V-1-VI-1-VII-½-VIII-1-IX-1-X-½-XI-1-XII-1-XIII
///
/// - P1:  PerfectUnison, zero steps from the root. This interval is always implied.
/// - M2:  Major second, a whole step from the root.
/// - m2:  Minor second, a half step from the root.
/// - A2:  Augmented second, one and a half steps from the root.
/// - M3:  Major third, two whole steps from the root.
/// - m3:  Minor third, the same as `A2`.
/// - A3:  Augmented third, two and a half steps from the root.
/// - P4:  Perfect fourth, the same as `A3`.
/// - d4:  Minor fourth, the same as `third`.
/// - A4:  Augmented fourth, three whole steps from the root.
/// - P5:  Perfect fifth, three and a half steps from the root.
/// - d5:  Minor fifth, the same as `A4`.
/// - A5:  Augmented fifth, four whole steps from the root.
/// - M6:  Major sixth, four and a half steps from the root.
/// - m6:  Minor sixth, the same as `A5`.
/// - A6:  Augmented sixth, five whole steps from the root.
/// - M7:  Major seventh, five and a half steps from the root.
/// - m7:  Minor seventh, the same as `A6`.
/// - A7:  Augmented seventh, six whole steps from the root.
/// - P8:  Perfect eighth, the same as `A7`.
/// - d8:  Minor eighth, the same as `seventh`.
/// - A8:  Augmented eighth, six and a half steps from the root.
/// - M9:  Major ninth, seven whole steps from the root.
/// - m9:  Minor ninth, the same as `A8`.
/// - A9:  Augmented ninth, seven and a half steps from the root.
/// - M10: Major tenth, eight whole steps from the root.
/// - m10: Minor tenth, the same as `A9`.
/// - A10: Augmented tenth, eight and a half steps from the root.
/// - P11: Perfect eleventh, the same as `A10`.
/// - d11: Minor eleventh, the same as `M10`.
/// - A11: Augmented eleventh, nine whole steps from the root.
/// - P12: Perfect twelfth, nine and a half steps from the root.
/// - d12: Minor twelfth, the same as `A11`.
/// - A12: Augmented twelfth, ten whole steps from the root.
/// - M13: Major thirteenth, ten and a half steps from the root.
/// - m13: Minor thirteenth, the same as `A12`.
/// - A13: Augmented thirteenth, eleven whole steps from the root.
public enum ChordInterval: UInt32, LosslessStringConvertible {

  case P1 = 0

  case M2  = 2,       m2  = 1,       A2  = 3
  case M3  = 8,       m3  = 4,       A3  = 12
  case P4  = 32,      d4  = 16,      A4  = 48
  case P5  = 128,     d5  = 64,      A5  = 192
  case M6  = 512,     m6  = 256,     A6  = 768
  case M7  = 2048,    m7  = 1024,    A7  = 3072
  case P8  = 8192,    d8  = 4096,    A8  = 12288
  case M9  = 32768,   m9  = 16384,   A9  = 49152
  case M10 = 131072,  m10 = 65536,   A10 = 196608
  case P11 = 524288,  d11 = 262144,  A11 = 786432
  case P12 = 2097152, d12 = 1048576, A12 = 3145728
  case M13 = 8388608, m13 = 4194304, A13 = 12582912

  /// Initializing from a chord pattern. To be successful, the pattern must consist of a
  /// single interval.
  public init?(_ chordPattern: ChordPattern) { self.init(rawValue: chordPattern.rawValue) }

  /// A bit mask that can be used to isolate the bits belonging to the interval.
  public var bitMask: UInt32 {
    switch self {
      case .P1:              return 0b00 << 0
      case .M2, .m2, .A2:    return 0b11 << 0
      case .M3, .m3, .A3:    return 0b11 << 2
      case .P4, .d4, .A4:    return 0b11 << 4
      case .P5, .d5, .A5:    return 0b11 << 6
      case .M6, .m6, .A6:    return 0b11 << 8
      case .M7, .m7, .A7:    return 0b11 << 10
      case .P8, .d8, .A8:    return 0b11 << 12
      case .M9, .m9, .A9:    return 0b11 << 14
      case .M10, .m10, .A10: return 0b11 << 16
      case .P11, .d11, .A11: return 0b11 << 18
      case .P12, .d12, .A12: return 0b11 << 20
      case .M13, .m13, .A13: return 0b11 << 22
    }
  }

  /// Returns the value of `symbol` for the interval.
  public var description: String { return symbol }

  /// The name for the interval.
  public var name: String {
    switch self {
      case .P1:  return "Perfect unision"
      case .M2:  return "Major second"
      case .m2:  return "Minor second"
      case .A2:  return "Augmented second"
      case .M3:  return "Major third"
      case .m3:  return "Minor third"
      case .A3:  return "Augmented third"
      case .P4:  return "Perfect fourth"
      case .d4:  return "Minor fourth"
      case .A4:  return "Augmented fourth"
      case .P5:  return "Perfect fifth"
      case .d5:  return "Minor fifth"
      case .A5:  return "Augmented fifth"
      case .M6:  return "Major sixth"
      case .m6:  return "Minor sixth"
      case .A6:  return "Augmented sixth"
      case .M7:  return "Major seventh"
      case .m7:  return "Minor seventh"
      case .A7:  return "Augmented seventh"
      case .P8:  return "Perfect eighth"
      case .d8:  return "Minor eighth"
      case .A8:  return "Augmented eighth"
      case .M9:  return "Major ninth"
      case .m9:  return "Minor ninth"
      case .A9:  return "Augmented ninth"
      case .M10: return "Major tenth"
      case .m10: return "Minor tenth"
      case .A10: return "Augmented tenth"
      case .P11: return "Perfect eleventh"
      case .d11: return "Minor eleventh"
      case .A11: return "Augmented eleventh"
      case .P12: return "Perfect twelfth"
      case .d12: return "Minor twelfth"
      case .A12: return "Augmented twelfth"
      case .M13: return "Major thirteenth"
      case .m13: return "Minor thirteenth"
      case .A13: return "Augmented thirteenth"
    }
  }

  /// A string containing the integer representation of the interval, preceded by '♭' or ♯'
  /// when appropriate.
  public var symbol: String {
    switch self {
      case .P1:  return "1"
      case .M2:  return "2"
      case .m2:  return "♭2"
      case .A2:  return "♯2"
      case .M3:  return "3"
      case .m3:  return "♭3"
      case .A3:  return "♯3"
      case .P4:  return "4"
      case .d4:  return "♭4"
      case .A4:  return "♯4"
      case .P5:  return "5"
      case .d5:  return "♭5"
      case .A5:  return "♯5"
      case .M6:  return "6"
      case .m6:  return "♭6"
      case .A6:  return "♯6"
      case .M7:  return "7"
      case .m7:  return "♭7"
      case .A7:  return "♯7"
      case .P8:  return "8"
      case .d8:  return "♭8"
      case .A8:  return "♯8"
      case .M9:  return "9"
      case .m9:  return "♭9"
      case .A9:  return "♯9"
      case .M10: return "10"
      case .m10: return "♭10"
      case .A10: return "♯10"
      case .P11: return "11"
      case .d11: return "♭11"
      case .A11: return "♯11"
      case .P12: return "12"
      case .d12: return "♭12"
      case .A12: return "♯12"
      case .M13: return "13"
      case .m13: return "♭13"
      case .A13: return "♯13"
    }
  }

  /// Initializing from a string.
  ///
  /// - Parameter description: The string representation as returned by `symbol` for the interval.
  public init?(_ description: String) {
    switch description {
      case "1":   self = .P1
      case "2":   self = .M2
      case "♭2":  self = .m2
      case "♯2":  self = .A2
      case "3":   self = .M3
      case "♭3":  self = .m3
      case "♯3":  self = .A3
      case "4":   self = .P4
      case "♭4":  self = .d4
      case "♯4":  self = .A4
      case "5":   self = .P5
      case "♭5":  self = .d5
      case "♯5":  self = .A5
      case "6":   self = .M6
      case "♭6":  self = .m6
      case "♯6":  self = .A6
      case "7":   self = .M7
      case "♭7":  self = .m7
      case "♯7":  self = .A7
      case "8":   self = .P8
      case "♭8":  self = .d8
      case "♯8":  self = .A8
      case "9":   self = .M9
      case "♭9":  self = .m9
      case "♯9":  self = .A9
      case "10":  self = .M10
      case "♭10": self = .m10
      case "♯10": self = .A10
      case "11":  self = .P11
      case "♭11": self = .d11
      case "♯11": self = .A11
      case "12":  self = .P12
      case "♭12": self = .d12
      case "♯12": self = .A12
      case "13":  self = .M13
      case "♭13": self = .m13
      case "♯13": self = .A13
      default:    return nil
    }
  }

  /// Boolean value indicating whether the interval represents a number of whole steps.
  public var isNatural: Bool { return rawValue == 0 || rawValue % 3 == 2 }

  /// Boolean value indicating whether the interval represents a number of whole steps flattened
  /// by half a step.
  public var isFlat: Bool { return rawValue != 0 && rawValue % 3 == 1 }

  /// Boolean value indicating whether the interval represents a number of whole steps sharpened
  /// by half a step.
  public var isSharp: Bool { return rawValue != 0 && rawValue % 3 == 0 }

  /// The total number of half steps covered by the interval.
  public var semitones: Int {

    switch self {
      case .P1:        return 0
      case .m2:        return 1
      case .M2:        return 2
      case .A2, .m3:   return 3
      case .M3, .d4:   return 4
      case .A3, .P4:   return 5
      case .A4, .d5:   return 6
      case .P5:        return 7
      case .A5, .m6:   return 8
      case .M6:        return 9
      case .A6,.m7:    return 10
      case .M7, .d8:   return 11
      case .A7, .P8:   return 12
      case .A8, .m9:   return 13
      case .M9:        return 14
      case .A9, .m10:  return 15
      case .M10, .d11: return 16
      case .A10, .P11: return 17
      case .A11, .d12: return 18
      case .P12:       return 19
      case .A12, .m13: return 20
      case .M13:       return 21
      case .A13:       return 22
    }

  }

  /// Initializing with the total number of semitones in the interval. Where multiple intervals
  /// match `semitones`, the minor or diminished interval will be selected over the augmented
  /// interval.
  ///
  /// - Parameter semitones: The number of semitones in the interval. To avoid a `nil`
  ///                        value, this must be in the range `1...22`.
  public init?(semitones: Int) {
    switch semitones {
      case 0:  self = .P1
      case 1:  self = .m2
      case 2:  self = .M2
      case 3:  self = .m3
      case 4:  self = .M3
      case 5:  self = .P4
      case 6:  self = .d5
      case 7:  self = .P5
      case 8:  self = .m6
      case 9:  self = .M6
      case 10: self = .m7
      case 11: self = .M7
      case 12: self = .P8
      case 13: self = .m9
      case 14: self = .M9
      case 15: self = .m10
      case 16: self = .M10
      case 17: self = .P11
      case 18: self = .d12
      case 19: self = .P12
      case 20: self = .m13
      case 21: self = .M13
      case 22: self = .A13
      default: return nil
    }
  }

}
