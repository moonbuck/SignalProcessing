//
//  ChordPattern.swift
//  Chord Finder
//
//  Created by Jason Cardwell on 7/29/17.
//  Copyright (c) 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import MoonKit

/// Generates an ASCII-friendly, canonical suffix from the given suffix.
/// The following symbols are used in suffix composition:
/// • flat accidentals are represented by 'b'
/// • sharp accidentals are represented by '#'
/// • major is represented by 'M'
/// • minor is represented by 'm'
/// • diminished is represented by 'dim'
/// • augmented is represented by 'aug'
/// • opening and closing parentheses are replaced by '_'
/// • '/' is replaced by '-'
///
/// - Parameter suffix: The non-ASCII suffix.
/// - Returns: A version of `suffix` with all ASCII characters.
private func canonicalSuffix(for suffix: String) -> String {

  var result = ""

  for character in suffix {

    switch character {
      case "♭": result.append("b")
      case "♯": result.append("#")
      case "╱", "/": result.append("-")
      case "+": result.append("aug")
      case "°": result.append("dim")
      case "(", ")": result.append("_")
      default:  result.append(character)
    }

  }

  return result

}

/// Generates a presentational suffix from a given suffix.
/// The following symbols are used in suffix composition:
/// • flat accidentals are represented by '♭'
/// • sharp accidentals are represented by '♯'
/// • major is represented by 'M'
/// • minor is represented by 'm'
/// • diminished is represented by '°'
/// • augmented is represented by '+'
/// • matching '_' are replaced by opening and closing parentheses
/// • '-' is replaced by '╱'
///
/// - Parameter suffix: The non-presentational suffix.
/// - Returns: A version of `suffix` with presentational characters.
private func presentationalSuffix(for suffix: String) -> String {

  let result = NSMutableString()
  result.append(suffix)
  let range = NSRange(location: 0, length: result.length)
  result.replaceOccurrences(of: "b", with: "♭", range: range)
  result.replaceOccurrences(of: "#", with: "♯", range: range)
  result.replaceOccurrences(of: "-", with: "╱", range: range)
  result.replaceOccurrences(of: "/", with: "╱", range: range)
  result.replaceOccurrences(of: "aug", with: "+", range: range)
  result.replaceOccurrences(of: "dim", with: "°", range: range)

  var resultʹ = ""

  var opening = true

  for character in result as String {

    switch character {
      case "_" where opening:
        resultʹ.append("(")
        opening = false
      case "_":
        resultʹ.append(")")
      default:
        resultʹ.append(character)
    }

  }

  return resultʹ

}

/// A type for specifiying a musical chord. `ChordPattern` stores which intervals, from a ♭2
/// through a ♯13, are included in the formation of a chord. Interval 1 represents the root of
/// the chord and so its presence is always implied. The constant raw values of `ChordPattern`
/// are shared with `ChordPattern.Interval` so that a `ChordPattern` composed of a single interval
/// may be interchanged with the corresponding `Interval` where the language avails.
public struct ChordPattern: OptionSet {

  /// The bit field for the pattern.
  public let rawValue: UInt32

  /// The name of the pattern's chord minus the leading root.
  public var suffix: String {
    return ChordPattern.suffixIndex[rawValue] ?? "?"
  }

  /// Initializing with a bit field. The 8 most significant digits of the specified value
  /// are ignored.
  ///
  /// - Parameter rawValue: The raw value for the pattern.
  public init(rawValue: UInt32) {
    self.rawValue = rawValue & 0b0000_0000_1111_1111_1111_1111_1111_1111
  }

  /// Initializing with a pattern suffix. If the suffix does not match the suffix of a
  /// static pattern then `nil` is returned.
  ///
  /// - Parameter suffix: The suffix of the desired pattern.
  public init?(suffix: String) {
    let suffix = presentationalSuffix(for: suffix)
    guard let index = ChordPattern.suffixIndex .index(where: {$1 == suffix}) else {
      return nil
    }

    let (rawValue, _) = ChordPattern.suffixIndex[index]
    self.init(rawValue: rawValue)
  }

  /// Initiliazing with a sequence of intervals.
  public init<S>(_ intervals: S)
    where S:Sequence, S.Iterator.Element == ChordInterval
  {
    rawValue = intervals.reduce(0, {$0|$1.rawValue})
  }

  /// Variable length argument initializer that initializes the pattern with the logical
  /// 'or' of the raw values for `intervals`.
  ///
  /// - Parameters:
  ///   - suffix: The name for the pattern's chord minus the leading root.
  ///   - intervals: One or more chord intervals composing the pattern.
  public init(_ intervals: ChordInterval...) {
    self.init(intervals)
  }

  /// An array of `Interval` values for the intervals of which the pattern is composed.
  /// - Note: This does not include the implied root interval.
  public var intervals: [ChordInterval] {
    return stride(from: UInt32(), through: 22, by: 2).compactMap {
      let intervalRawValue = rawValue & (0b11 << $0)
      return intervalRawValue > 0 ? ChordInterval(rawValue: intervalRawValue) : nil
    }
  }

  /// Tests for membership of the specified chord interval.
  ///
  /// - Parameter interval: The interval to test for membership in the chord pattern.
  /// - Returns: `true` if the chord pattern contains `interval` and `false` otherwise.
  public func contains(interval: ChordInterval) -> Bool {
    return interval == .P1 ? true : interval.rawValue ^ (rawValue & interval.bitMask) == 0
  }

  /// The number of notes, including the implied root note, present in the chord pattern.
  public var noteCount: Int {

    // Use bitwise operations to determine the number of bits that have been set in `rawValue`.
    var result = rawValue
    result = ((result >>  1) & 0x55555555) + (result & 0x55555555)
    result = ((result >>  2) & 0x33333333) + (result & 0x33333333)
    result = ((result >>  4) & 0x07070707) + (result & 0x07070707)
    result = ((result >>  8) & 0x000F000F) + (result & 0x000F000F)
    result = ((result >> 16)             ) + (result & 0x0000001F)

    // Add one for the implied root note.
    result += 1

    return Int(result)

  }

  public static let ﹡M          = ChordPattern(.M3, .P5)
  public static let ﹡m          = ChordPattern(.m3, .P5)
  public static let ﹡aug        = ChordPattern(.M3, .A5)
  public static let ﹡dim        = ChordPattern(.m3, .d5)
  public static let ﹡sus4       = ChordPattern(.P4, .P5)
  public static let ﹡_f5_       = ChordPattern(.M3, .d5)
  public static let ﹡sus2       = ChordPattern(.M2, .P5)
  public static let ﹡6          = ChordPattern(.M3, .P5, .M6)
  public static let ﹡_add2_     = ChordPattern(.M2, .M3, .P5)
  public static let ﹡M7         = ChordPattern(.M3, .P5, .M7)
  public static let ﹡M7f5       = ChordPattern(.M3, .d5, .M7)
  public static let ﹡M7s5       = ChordPattern(.M3, .A5, .M7)
  public static let ﹡7          = ChordPattern(.M3, .P5, .m7)
  public static let ﹡7f5        = ChordPattern(.M3, .d5, .m7)
  public static let ﹡7s5        = ChordPattern(.M3, .A5, .m7)
  public static let ﹡7sus4      = ChordPattern(.P4, .P5, .m7)
  public static let ﹡m_add2_    = ChordPattern(.M2, .m3, .P5)
  public static let ﹡m6         = ChordPattern(.m3, .P5, .M6)
  public static let ﹡m7         = ChordPattern(.m3, .P5, .m7)
  public static let ﹡m_M7_      = ChordPattern(.m3, .P5, .M7)
  public static let ﹡m7f5       = ChordPattern(.m3, .d5, .m7)
  public static let ﹡dim7       = ChordPattern(.m3, .d5, .M6)
  public static let ﹡dim7_M7_   = ChordPattern(.m3, .d5, .M7)
  public static let ﹡5          = ChordPattern(.P5)
  public static let ﹡6_9        = ChordPattern(.M3, .P5, .M6, .M9)
  public static let ﹡M6_9       = ChordPattern(.M3, .P5, .M6, .M7, .M9)
  public static let ﹡M7s11      = ChordPattern(.M3, .P5, .M7, .A11)
  public static let ﹡M9         = ChordPattern(.M3, .P5, .M7, .M9)
  public static let ﹡M9f5       = ChordPattern(.M3, .d5, .M7, .M9)
  public static let ﹡M9s5       = ChordPattern(.M3, .A5, .M7, .M9)
  public static let ﹡M9s11      = ChordPattern(.M3, .P5, .M7, .M9, .A11)
  public static let ﹡M13        = ChordPattern(.M3, .P5, .M7, .M9, .M13)
  public static let ﹡M13f5      = ChordPattern(.M3, .d5, .M7, .M9, .M13)
  public static let ﹡M13s11     = ChordPattern(.M3, .P5, .M7, .M9, .A11, .M13)
  public static let ﹡7f9        = ChordPattern(.M3, .P5, .m7, .m9)
  public static let ﹡7s9        = ChordPattern(.M3, .P5, .m7, .A9)
  public static let ﹡7s11       = ChordPattern(.M3, .P5, .m7, .A11)
  public static let ﹡7f5_f9_    = ChordPattern(.M3, .d5, .m7, .m9)
  public static let ﹡7f5_s9_    = ChordPattern(.M3, .d5, .m7, .A9)
  public static let ﹡7s5_f9_    = ChordPattern(.M3, .A5, .m7, .m9)
  public static let ﹡7s5_s9_    = ChordPattern(.M3, .A5, .m7, .A9)
  public static let ﹡7_add13_   = ChordPattern(.M3, .P5, .m7, .M13)
  public static let ﹡7f13       = ChordPattern(.M3, .P5, .m7, .m13)
  public static let ﹡7f9_s11_   = ChordPattern(.M3, .P5, .m7, .m9, .A11)
  public static let ﹡7s9_s11_   = ChordPattern(.M3, .P5, .m7, .A9, .A11)
  public static let ﹡7f9_f13_   = ChordPattern(.M3, .P5, .m7, .m9, .m13)
  public static let ﹡7s9_f13_   = ChordPattern(.M3, .P5, .m7, .A9, .m13)
  public static let ﹡7s11_f13_  = ChordPattern(.M3, .P5, .m7, .A11, .m13)
  public static let ﹡9          = ChordPattern(.M3, .P5, .m7, .M9)
  public static let ﹡9_f5_      = ChordPattern(.M3, .d5, .m7, .M9)
  public static let ﹡9s5        = ChordPattern(.M3, .A5, .m7, .M9)
  public static let ﹡9s11       = ChordPattern(.M3, .P5, .m7, .M9, .A11)
  public static let ﹡9f13       = ChordPattern(.M3, .P5, .m7, .M9, .m13)
  public static let ﹡9s11_f13_  = ChordPattern(.M3, .P5, .m7, .M9, .A11, .m13)
  public static let ﹡11         = ChordPattern(.P5, .m7, .M9, .P11)
  public static let ﹡13         = ChordPattern(.M3, .P5, .m7, .M9, .M13)
  public static let ﹡13f5       = ChordPattern(.M3, .d5, .m7, .M9, .M13)
  public static let ﹡13f9       = ChordPattern(.M3, .P5, .m7, .m9, .M13)
  public static let ﹡13s9       = ChordPattern(.M3, .P5, .m7, .A9, .M13)
  public static let ﹡13s11      = ChordPattern(.M3, .P5, .m7, .M9, .A11, .M13)
  public static let ﹡13_sus4_   = ChordPattern(.P4, .P5, .m7, .M9, .M13)
  public static let ﹡m_s5_      = ChordPattern(.m3, .A5)
  public static let ﹡m6_9t      = ChordPattern(.m3, .P5, .M6, .M9)
  public static let ﹡m7_add4_   = ChordPattern(.m3, .P4, .P5, .m7)
  public static let ﹡m7_add11_  = ChordPattern(.m3, .P5, .m7, .P11)
  public static let ﹡m7f5_f9_   = ChordPattern(.m3, .d5, .m7, .m9)
  public static let ﹡m9         = ChordPattern(.m3, .P5, .m7, .M9)
  public static let ﹡m9_M7_     = ChordPattern(.m3, .P5, .M7, .M9)
  public static let ﹡m9_f5_     = ChordPattern(.m3, .d5, .m7, .M9)
  public static let ﹡m11        = ChordPattern(.m3, .P5, .m7, .M9, .P11)
  public static let ﹡m13        = ChordPattern(.m3, .P5, .m7, .M9, .P11, .M13)
  public static let ﹡dim7_add9_ = ChordPattern(.m3, .d5, .M6, .M9)
  public static let ﹡m11f5      = ChordPattern(.m3, .d5, .m7, .M9, .P11)
  public static let ﹡m11_M7_    = ChordPattern(.m3, .P5, .M7, .M9, .P11)

  public static let all: [ChordPattern] = [
    .﹡dim, .﹡_f5_, .﹡5, .﹡sus2, .﹡m, .﹡m_add2_, .﹡M, .﹡_add2_, .﹡sus4, .﹡m_s5_,
    .﹡aug, .﹡dim7, .﹡m6, .﹡6, .﹡m7f5, .﹡7f5, .﹡m7, .﹡7, .﹡7sus4, .﹡m7_add4_, .﹡7s5,
    .﹡dim7_M7_, .﹡M7f5, .﹡m_M7_, .﹡M7, .﹡M7s5, .﹡m7f5_f9_, .﹡7f5_f9_, .﹡7f9, .﹡7s5_f9_,
    .﹡dim7_add9_, .﹡m6_9t, .﹡6_9, .﹡m9_f5_, .﹡9_f5_, .﹡m9, .﹡9, .﹡9s5, .﹡M9f5, .﹡m9_M7_,
    .﹡M9, .﹡M9s5, .﹡M6_9, .﹡7f5_s9_, .﹡7s9, .﹡7s5_s9_, .﹡m7_add11_, .﹡m11f5, .﹡11, .﹡m11,
    .﹡m11_M7_, .﹡7s11, .﹡M7s11, .﹡7f9_s11_, .﹡9s11, .﹡M9s11, .﹡7s9_s11_, .﹡7f13, .﹡7f9_f13_,
    .﹡9f13, .﹡7s9_f13_, .﹡7s11_f13_, .﹡9s11_f13_, .﹡7_add13_, .﹡13f9, .﹡13f5, .﹡13,
    .﹡13_sus4_, .﹡M13f5, .﹡M13, .﹡13s9, .﹡m13, .﹡13s11, .﹡M13s11
  ]

  private static let suffixIndex: [RawValue:String] = [
    ChordPattern.﹡dim.rawValue: "°",
    ChordPattern.﹡_f5_.rawValue: "(♭5)",
    ChordPattern.﹡5.rawValue: "5",
    ChordPattern.﹡sus2.rawValue: "sus2",
    ChordPattern.﹡m.rawValue: "m",
    ChordPattern.﹡m_add2_.rawValue: "m(add2)",
    ChordPattern.﹡M.rawValue: "M",
    ChordPattern.﹡_add2_.rawValue: "(add2)",
    ChordPattern.﹡sus4.rawValue: "sus4",
    ChordPattern.﹡m_s5_.rawValue: "m(♯5)",
    ChordPattern.﹡aug.rawValue: "+",
    ChordPattern.﹡dim7.rawValue: "°7",
    ChordPattern.﹡m6.rawValue: "m6",
    ChordPattern.﹡6.rawValue: "6",
    ChordPattern.﹡m7f5.rawValue: "m7♭5",
    ChordPattern.﹡7f5.rawValue: "7♭5",
    ChordPattern.﹡m7.rawValue: "m7",
    ChordPattern.﹡7.rawValue: "7",
    ChordPattern.﹡7sus4.rawValue: "7sus4",
    ChordPattern.﹡m7_add4_.rawValue: "m7(add4)",
    ChordPattern.﹡7s5.rawValue: "7♯5",
    ChordPattern.﹡dim7_M7_.rawValue: "°7(M7)",
    ChordPattern.﹡M7f5.rawValue: "M7♭5",
    ChordPattern.﹡m_M7_.rawValue: "m(M7)",
    ChordPattern.﹡M7.rawValue: "M7",
    ChordPattern.﹡M7s5.rawValue: "M7♯5",
    ChordPattern.﹡m7f5_f9_.rawValue: "m7♭5(♭9)",
    ChordPattern.﹡7f5_f9_.rawValue: "7♭5(♭9)",
    ChordPattern.﹡7f9.rawValue: "7♭9",
    ChordPattern.﹡7s5_f9_.rawValue: "7♯5(♭9)",
    ChordPattern.﹡dim7_add9_.rawValue: "°7(add9)",
    ChordPattern.﹡m6_9t.rawValue: "m6╱9",
    ChordPattern.﹡6_9.rawValue: "6╱9",
    ChordPattern.﹡m9_f5_.rawValue: "m9(♭5)",
    ChordPattern.﹡9_f5_.rawValue: "9(♭5)",
    ChordPattern.﹡m9.rawValue: "m9",
    ChordPattern.﹡9.rawValue: "9",
    ChordPattern.﹡9s5.rawValue: "9♯5",
    ChordPattern.﹡M9f5.rawValue: "M9♭5",
    ChordPattern.﹡m9_M7_.rawValue: "m9(M7)",
    ChordPattern.﹡M9.rawValue: "M9",
    ChordPattern.﹡M9s5.rawValue: "M9♯5",
    ChordPattern.﹡M6_9.rawValue: "M6╱9",
    ChordPattern.﹡7f5_s9_.rawValue: "7♭5(♯9)",
    ChordPattern.﹡7s9.rawValue: "7♯9",
    ChordPattern.﹡7s5_s9_.rawValue: "7♯5(♯9)",
    ChordPattern.﹡m7_add11_.rawValue: "m7(add11)",
    ChordPattern.﹡m11f5.rawValue: "m11♭5",
    ChordPattern.﹡11.rawValue: "11",
    ChordPattern.﹡m11.rawValue: "m11",
    ChordPattern.﹡m11_M7_.rawValue: "m11(M7)",
    ChordPattern.﹡7s11.rawValue: "7♯11",
    ChordPattern.﹡M7s11.rawValue: "M7♯11",
    ChordPattern.﹡7f9_s11_.rawValue: "7♭9(♯11)",
    ChordPattern.﹡9s11.rawValue: "9♯11",
    ChordPattern.﹡M9s11.rawValue: "M9♯11",
    ChordPattern.﹡7s9_s11_.rawValue: "7♯9(♯11)",
    ChordPattern.﹡7f13.rawValue: "7♭13",
    ChordPattern.﹡7f9_f13_.rawValue: "7♭9(♭13)",
    ChordPattern.﹡9f13.rawValue: "9♭13",
    ChordPattern.﹡7s9_f13_.rawValue: "7♯9(♭13)",
    ChordPattern.﹡7s11_f13_.rawValue: "7♯11(♭13)",
    ChordPattern.﹡9s11_f13_.rawValue: "9♯11(♭13)",
    ChordPattern.﹡7_add13_.rawValue: "7(add13)",
    ChordPattern.﹡13f9.rawValue: "13♭9",
    ChordPattern.﹡13f5.rawValue: "13♭5",
    ChordPattern.﹡13.rawValue: "13",
    ChordPattern.﹡13_sus4_.rawValue: "13(sus4)",
    ChordPattern.﹡M13f5.rawValue: "M13♭5",
    ChordPattern.﹡M13.rawValue: "M13",
    ChordPattern.﹡13s9.rawValue: "13♯9",
    ChordPattern.﹡m13.rawValue: "m13",
    ChordPattern.﹡13s11.rawValue: "13♯11",
    ChordPattern.﹡M13s11.rawValue: "M13♯11"
  ]

}

extension ChordPattern: Hashable {

  public var hashValue: Int { return rawValue.hashValue }

}

extension ChordPattern: ExpressibleByArrayLiteral {

//  public init(arrayLiteral: ChordInterval) { self.init(arrayLiteral) }

}

extension ChordPattern: CustomStringConvertible {

  /// The list of `intervals` enclosed by parentheses
  public var description: String {
    return "(\(intervals.map({$0.symbol}).joined(separator: ", ")))"
  }

}

extension ChordPattern: ExpressibleByStringLiteral {

  /// Initializing with a known suffix. If the suffix is unknown, initializes with intervals
  /// `.M3` and `.P5`.
  ///
  /// - Parameter value: The suffix for the chord pattern.
  public init(stringLiteral value: String) {

    let value = presentationalSuffix(for: value)
    if let index = ChordPattern.suffixIndex .index(where: {$1 == value}) {
      let (rawValue, _) = ChordPattern.suffixIndex[index]
      self.init(rawValue: rawValue)
    } else {
      self.init(.M3, .P5)
    }

  }

}
