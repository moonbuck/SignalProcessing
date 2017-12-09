//
//  ChordPattern.swift
//  Chord Finder
//
//  Created by Jason Cardwell on 7/29/17.
//  Copyright (c) 2017 Moondeer Studios. All rights reserved.
//
import Foundation


/// A type for specifiying a musical chord. `ChordPattern` stores which intervals, from a ♭2
/// through a ♯13, are included in the formation of a chord. Interval 1 represents the root of
/// the chord and so its presence is always implied. The constant raw values of `ChordPattern`
/// are shared with `ChordPattern.Interval` so that a `ChordPattern` composed of a single interval
/// may be interchanged with the corresponding `Interval` where the language avails.
public struct ChordPattern: OptionSet {

  /// The bit field for the pattern.
  public let rawValue: UInt32

  /// The name of the pattern's chord minus the leading root.
  public let suffix: String

  /// Initializing with a bit field.
  public init(rawValue: UInt32) { self.rawValue = rawValue; suffix = "?" }

  /// Initiliazing with a sequence of intervals.
  public init<S>(_ intervals: S)
    where S:Sequence, S.Iterator.Element == PitchInterval
  {
    let rawValue = intervals.reduce(0, {$0|$1.rawValue})
    if let existing = ChordPattern.index[rawValue] { self = existing }
    else { self.rawValue = rawValue; suffix = "?" }
  }

  /// Variable length argument initializer that feeds `intervals` into the generic `init(_:)`.
  ///
  /// - Parameter intervals: One or more pitch intervals composing the pattern.
  public init(_ intervals: PitchInterval...) {
    self.init(intervals)
  }

  /// Variable length argument initializer that feeds `intervals` into the generic `init(_:)`.
  ///
  /// - Parameters:
  ///   - suffix: The name for the pattern's chord minus the leading root.
  ///   - intervals: One or more pitch intervals composing the pattern.
  public init(suffix: String, _ intervals: PitchInterval...) {
    rawValue = intervals.reduce(0, {$0|$1.rawValue})
    self.suffix = suffix
  }

  /// An array of `Interval` values for the intervals of which the pattern is composed.
  public var intervals: [PitchInterval] {
    return stride(from: UInt32(), through: 22, by: 2).flatMap {
      PitchInterval(rawValue: rawValue & (0b11 << $0))
    }
  }

  /// Tests for membership of the specified pitch interval.
  ///
  /// - Parameter interval: The interval to test for membership in the chord pattern.
  /// - Returns: `true` if the chord pattern contains `interval` and `false` otherwise.
  public func contains(interval: PitchInterval) -> Bool {
    return rawValue & interval.rawValue == interval.rawValue
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

  public static let ﹡M          = ChordPattern(suffix: "M", .M3, .P5)
  public static let ﹡m          = ChordPattern(suffix: "m", .m3, .P5)
  public static let ﹡aug        = ChordPattern(suffix: "+", .M3, .A5)
  public static let ﹡dim        = ChordPattern(suffix: "°", .m3, .d5)
  public static let ﹡sus4       = ChordPattern(suffix: "sus4", .P4, .P5)
  public static let ﹡_f5_       = ChordPattern(suffix: "(♭5)", .M3, .d5)
  public static let ﹡sus2       = ChordPattern(suffix: "sus2", .M2, .P5)
  public static let ﹡6          = ChordPattern(suffix: "6", .M3, .P5, .M6)
  public static let ﹡_add2_     = ChordPattern(suffix: "(add2)", .M2, .M3, .P5)
  public static let ﹡M7         = ChordPattern(suffix: "M7", .M3, .P5, .M7)
  public static let ﹡M7f5       = ChordPattern(suffix: "M7♭5", .M3, .d5, .M7)
  public static let ﹡M7s5       = ChordPattern(suffix: "M7♯5", .M3, .A5, .M7)
  public static let ﹡7          = ChordPattern(suffix: "7", .M3, .P5, .m7)
  public static let ﹡7f5        = ChordPattern(suffix: "7♭5", .M3, .d5, .m7)
  public static let ﹡7s5        = ChordPattern(suffix: "7♯5", .M3, .A5, .m7)
  public static let ﹡7sus4      = ChordPattern(suffix: "7sus4", .P4, .P5, .m7)
  public static let ﹡m_add2_    = ChordPattern(suffix: "m(add2)", .M2, .m3, .P5)
  public static let ﹡m6         = ChordPattern(suffix: "m6", .m3, .P5, .M6)
  public static let ﹡m7         = ChordPattern(suffix: "m7", .m3, .P5, .m7)
  public static let ﹡m_M7_      = ChordPattern(suffix: "m(M7)", .m3, .P5, .M7)
  public static let ﹡m7f5       = ChordPattern(suffix: "m7♭5", .m3, .d5, .m7)
  public static let ﹡dim7       = ChordPattern(suffix: "°7", .m3, .d5, .M6)
  public static let ﹡dim7_M7_   = ChordPattern(suffix: "°7(M7)", .m3, .d5, .M7)
  public static let ﹡5          = ChordPattern(suffix: "5", .P5)
  public static let ﹡6_9        = ChordPattern(suffix: "6╱9", .M3, .P5, .M6, .M9)
  public static let ﹡M6_9       = ChordPattern(suffix: "M6╱9", .M3, .P5, .M6, .M7, .M9)
  public static let ﹡M7s11      = ChordPattern(suffix: "M7♯11", .M3, .P5, .M7, .A11)
  public static let ﹡M9         = ChordPattern(suffix: "M9", .M3, .P5, .M7, .M9)
  public static let ﹡M9f5       = ChordPattern(suffix: "M9♭5", .M3, .d5, .M7, .M9)
  public static let ﹡M9s5       = ChordPattern(suffix: "M9♯5", .M3, .A5, .M7, .M9)
  public static let ﹡M9s11      = ChordPattern(suffix: "M9♯11", .M3, .P5, .M7, .M9, .A11)
  public static let ﹡M13        = ChordPattern(suffix: "M13", .M3, .P5, .M7, .M9, .M13)
  public static let ﹡M13f5      = ChordPattern(suffix: "M13♭5", .M3, .d5, .M7, .M9, .M13)
  public static let ﹡M13s11     = ChordPattern(suffix: "M13♯11", .M3, .P5, .M7, .M9, .A11, .M13)
  public static let ﹡7f9        = ChordPattern(suffix: "7♭9", .M3, .P5, .m7, .m9)
  public static let ﹡7s9        = ChordPattern(suffix: "7♯9", .M3, .P5, .m7, .A9)
  public static let ﹡7s11       = ChordPattern(suffix: "7♯11", .M3, .P5, .m7, .A11)
  public static let ﹡7f5_f9_    = ChordPattern(suffix: "7♭5(♭9)", .M3, .d5, .m7, .m9)
  public static let ﹡7f5_s9_    = ChordPattern(suffix: "7♭5(♯9)", .M3, .d5, .m7, .A9)
  public static let ﹡7s5_f9_    = ChordPattern(suffix: "7♯5(♭9)", .M3, .A5, .m7, .m9)
  public static let ﹡7s5_s9_    = ChordPattern(suffix: "7♯5(♯9)", .M3, .A5, .m7, .A9)
  public static let ﹡7_add13_   = ChordPattern(suffix: "7(add13)", .M3, .P5, .m7, .M13)
  public static let ﹡7f13       = ChordPattern(suffix: "7♭13", .M3, .P5, .m7, .m13)
  public static let ﹡7f9_s11_   = ChordPattern(suffix: "7♭9(♯11)", .M3, .P5, .m7, .m9, .A11)
  public static let ﹡7s9_s11_   = ChordPattern(suffix: "7♯9(♯11)", .M3, .P5, .m7, .A9, .A11)
  public static let ﹡7f9_f13_   = ChordPattern(suffix: "7♭9(♭13)", .M3, .P5, .m7, .m9, .m13)
  public static let ﹡7s9_f13_   = ChordPattern(suffix: "7♯9(♭13)", .M3, .P5, .m7, .A9, .m13)
  public static let ﹡7s11_f13_  = ChordPattern(suffix: "7♯11(♭13)", .M3, .P5, .m7, .A11, .m13)
  public static let ﹡9          = ChordPattern(suffix: "9", .M3, .P5, .m7, .M9)
  public static let ﹡9_f5_      = ChordPattern(suffix: "9(♭5)", .M3, .d5, .m7, .M9)
  public static let ﹡9s5        = ChordPattern(suffix: "9♯5", .M3, .A5, .m7, .M9)
  public static let ﹡9s11       = ChordPattern(suffix: "9♯11", .M3, .P5, .m7, .M9, .A11)
  public static let ﹡9f13       = ChordPattern(suffix: "9♭13", .M3, .P5, .m7, .M9, .m13)
  public static let ﹡9s11_f13_  = ChordPattern(suffix: "9♯11(♭13)", .M3, .P5, .m7, .M9, .A11, .m13)
  public static let ﹡11         = ChordPattern(suffix: "11", .P5, .m7, .M9, .P11)
  public static let ﹡13         = ChordPattern(suffix: "13", .M3, .P5, .m7, .M9, .M13)
  public static let ﹡13f5       = ChordPattern(suffix: "13♭5", .M3, .d5, .m7, .M9, .M13)
  public static let ﹡13f9       = ChordPattern(suffix: "13♭9", .M3, .P5, .m7, .m9, .M13)
  public static let ﹡13s9       = ChordPattern(suffix: "13♯9", .M3, .P5, .m7, .A9, .M13)
  public static let ﹡13s11      = ChordPattern(suffix: "13♯11", .M3, .P5, .m7, .M9, .A11, .M13)
  public static let ﹡13_sus4_   = ChordPattern(suffix: "13(sus4)", .P4, .P5, .m7, .M9, .M13)
  public static let ﹡m_s5_      = ChordPattern(suffix: "m(♯5)", .m3, .A5)
  public static let ﹡m6_9t      = ChordPattern(suffix: "m6╱9", .m3, .P5, .M6, .M9)
  public static let ﹡m7_add4_   = ChordPattern(suffix: "m7(add4)", .m3, .P4, .P5, .m7)
  public static let ﹡m7_add11_  = ChordPattern(suffix: "m7(add11)", .m3, .P5, .m7, .P11)
  public static let ﹡m7f5_f9_   = ChordPattern(suffix: "m7♭5(♭9)", .m3, .d5, .m7, .m9)
  public static let ﹡m9         = ChordPattern(suffix: "m9", .m3, .P5, .m7, .M9)
  public static let ﹡m9_M7_     = ChordPattern(suffix: "m9(M7)", .m3, .P5, .M7, .M9)
  public static let ﹡m9_f5_     = ChordPattern(suffix: "m9(♭5)", .m3, .d5, .m7, .M9)
  public static let ﹡m11        = ChordPattern(suffix: "m11", .m3, .P5, .m7, .M9, .P11)
  public static let ﹡m13        = ChordPattern(suffix: "m13", .m3, .P5, .m7, .M9, .P11, .M13)
  public static let ﹡dim7_add9_ = ChordPattern(suffix: "°7(add9)", .m3, .d5, .M6, .M9)
  public static let ﹡m11f5      = ChordPattern(suffix: "m11♭5", .m3, .d5, .m7, .M9, .P11)
  public static let ﹡m11_M7_    = ChordPattern(suffix: "m11(M7)", .m3, .P5, .M7, .M9, .P11)

  public static let all: [ChordPattern] = [
    ﹡M, ﹡m, ﹡aug, ﹡dim, ﹡sus4, ﹡_f5_, ﹡sus2, ﹡6, ﹡_add2_, ﹡M7, ﹡M7f5, ﹡M7s5,
    ﹡7, ﹡7f5, ﹡7s5, ﹡7sus4, ﹡m_add2_, ﹡m6, ﹡m7, ﹡m_M7_, ﹡m7f5, ﹡dim7, ﹡dim7_M7_,
    ﹡5, ﹡6_9, ﹡M6_9, ﹡M7s11, ﹡M9, ﹡M9f5, ﹡M9s5, ﹡M9s11, ﹡M13, ﹡M13f5, ﹡M13s11,
    ﹡7f9, ﹡7s9, ﹡7s11, ﹡7f5_f9_, ﹡7f5_s9_, ﹡7s5_f9_, ﹡7s5_s9_, ﹡7_add13_,
    ﹡7f13, ﹡7f9_s11_, ﹡7s9_s11_, ﹡7f9_f13_, ﹡7s9_f13_, ﹡7s11_f13_, ﹡9,
    ﹡9_f5_, ﹡9s5, ﹡9s11, ﹡9f13, ﹡9s11_f13_, ﹡11, ﹡13, ﹡13f5, ﹡13f9, ﹡13s9, ﹡13s11,
    ﹡13_sus4_, ﹡m_s5_, ﹡m6_9t, ﹡m7_add4_, ﹡m7_add11_, ﹡m7f5_f9_, ﹡m9, ﹡m9_M7_, ﹡m9_f5_,
    ﹡m11, ﹡m13, ﹡dim7_add9_, ﹡m11f5, ﹡m11_M7_
  ]

  public static let index: [RawValue:ChordPattern] = {
    var index = [RawValue:ChordPattern](minimumCapacity: ChordPattern.all.count)
    for pattern in ChordPattern.all { index[pattern.rawValue] = pattern }
    return index
  }()

}

extension ChordPattern: Hashable {

  public var hashValue: Int { return rawValue.hashValue }

}

extension ChordPattern: ExpressibleByArrayLiteral {

  public init(arrayLiteral: PitchInterval) { self.init(arrayLiteral) }

}

extension ChordPattern: CustomStringConvertible {

  /// The list of `intervals` enclosed by parentheses
  public var description: String {
    return "(\(intervals.map({$0.symbol}).joined(separator: ", ")))"
  }

}

extension ChordPattern: ExpressibleByStringLiteral {

  /// Initializing with a known suffix. If the suffix is unknown, initializes to `﹡M`.
  ///
  /// - Parameter value: The suffix for the chord pattern.
  public init(stringLiteral value: String) {

    switch value {

      case "m":         self = .﹡m
      case "+":         self = .﹡aug
      case "°":         self = .﹡dim
      case "sus4":      self = .﹡sus4
      case "(♭5)":      self = .﹡_f5_
      case "sus2":      self = .﹡sus2
      case "6":         self = .﹡6
      case "(add2)":    self = .﹡_add2_
      case "M7":        self = .﹡M7
      case "M7♭5":      self = .﹡M7f5
      case "M7♯5":      self = .﹡M7s5
      case "7":         self = .﹡7
      case "7♭5":       self = .﹡7f5
      case "7♯5":       self = .﹡7s5
      case "7sus4":     self = .﹡7sus4
      case "m(add2)":   self = .﹡m_add2_
      case "m6":        self = .﹡m6
      case "m7":        self = .﹡m7
      case "m(M7)":     self = .﹡m_M7_
      case "m7♭5":      self = .﹡m7f5
      case "°7":        self = .﹡dim7
      case "°7(M7)":    self = .﹡dim7_M7_
      case "5":         self = .﹡5
      case "6╱9":       self = .﹡6_9
      case "M6╱9":      self = .﹡M6_9
      case "M7♯11":     self = .﹡M7s11
      case "M9":        self = .﹡M9
      case "M9♭5":      self = .﹡M9f5
      case "M9♯5":      self = .﹡M9s5
      case "M9♯11":     self = .﹡M9s11
      case "M13":       self = .﹡M13
      case "M13♭5":     self = .﹡M13f5
      case "M13♯11":    self = .﹡M13s11
      case "7♭9":       self = .﹡7f9
      case "7♯9":       self = .﹡7s9
      case "7♯11":      self = .﹡7s11
      case "7♭5(♭9)":   self = .﹡7f5_f9_
      case "7♭5(♯9)":   self = .﹡7f5_s9_
      case "7♯5(♭9)":   self = .﹡7s5_f9_
      case "7♯5(♯9)":   self = .﹡7s5_s9_
      case "7(add13)":  self = .﹡7_add13_
      case "7♭13":      self = .﹡7f13
      case "7♭9(♯11)":  self = .﹡7f9_s11_
      case "7♯9(♯11)":  self = .﹡7s9_s11_
      case "7♭9(♭13)":  self = .﹡7f9_f13_
      case "7♯9(♭13)":  self = .﹡7s9_f13_
      case "7♯11(♭13)": self = .﹡7s11_f13_
      case "9":         self = .﹡9
      case "9(♭5)":     self = .﹡9_f5_
      case "9♯5":       self = .﹡9s5
      case "9♯11":      self = .﹡9s11
      case "9♭13":      self = .﹡9f13
      case "9♯11(♭13)": self = .﹡9s11_f13_
      case "11":        self = .﹡11
      case "13":        self = .﹡13
      case "13♭5":      self = .﹡13f5
      case "13♭9":      self = .﹡13f9
      case "13♯9":      self = .﹡13s9
      case "13♯11":     self = .﹡13s11
      case "13(sus4)":  self = .﹡13_sus4_
      case "m(♯5)":     self = .﹡m_s5_
      case "m6╱9":      self = .﹡m6_9t
      case "m7(add4)":  self = .﹡m7_add4_
      case "m7(add11)": self = .﹡m7_add11_
      case "m7♭5(♭9)":  self = .﹡m7f5_f9_
      case "m9":        self = .﹡m9
      case "m9(M7)":    self = .﹡m9_M7_
      case "m9(♭5)":    self = .﹡m9_f5_
      case "m11":       self = .﹡m11
      case "m13":       self = .﹡m13
      case "°7(add9)":  self = .﹡dim7_add9_
      case "m11♭5":     self = .﹡m11f5
      case "m11(M7)":   self = .﹡m11_M7_
      default:          self = .﹡M

    }

  }

}
