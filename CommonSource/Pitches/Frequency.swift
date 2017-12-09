//
//  Frequency.swift
//  Chord Finder
//
//  Created by Jason Cardwell on 8/24/17.
//  Copyright (c) 2017 Moondeer Studios. All rights reserved.
//
import Foundation

/// A structure for representing a frequency as would correspond to a pitch or musical tone.
public struct Frequency: RawRepresentable, CustomStringConvertible {

  /// The value of the frequency given in Hz.
  public let rawValue: Float64

  /// Initialize with the frequency's value in Hz. Uses the absolute value of value provided.
  public init(rawValue: Float64) { self.init(rawValue) }

  /// Initialize with the frequency's value in Hz. Uses the absolute value of value provided.
  public init(_ value: Float64) { rawValue = abs(value) }

  /// Initializing with a pitch. Assigns `pitch.centerFrequency`.
  public init(_ pitch: Pitch) { self = pitch.centerFrequency }

  /// The pitch with the center frequency nearest `rawValue`.
  public var pitch: Pitch {
    return Pitch(rawValue: Int((12 * log2(rawValue/440) + 69).rounded()))
  }

  /// The bin holding the frequency given the specified sample rate and window size.
  ///
  /// - Parameters:
  ///   - sampleRate: The sample rate for the FFT calculation.
  ///   - windowSize: The window size used for the FFT calculation.
  /// - Returns: The bin to which the frequency belongs.
  public func bin(for sampleRate: SampleRate, windowSize: Int) -> Int {

    return Int((rawValue * Float64(windowSize)) / Float64(sampleRate.rawValue))

  }

  public var description: String {

    if let i = Int(exactly: rawValue) { return "\(i) Hz" }
    else { return "\(rawValue) Hz" }

  }

  /// Advances the frequency by the specified amount.
  ///
  /// - Parameter value: The amount to advance the frequency in cents.
  /// - Returns: The frequency `value` cents away.
  public func advanced(by value: Float64) -> Frequency {

    return Frequency(rawValue: rawValue * pow(2, value/1200))


  }

  /// The distance to the specified frequency in cents.
  ///
  /// - Parameter frequency: The frequency for which to calculate the distance.
  /// - Returns: The number of cents from `frequency` to the frequency.
  public func distance(to frequency: Frequency) -> Float64 {

    return log2(frequency.rawValue / rawValue) * 1200

  }

}

extension Frequency: Comparable {

  public static func ==(lhs: Frequency, rhs: Frequency) -> Bool {
    return lhs.rawValue == rhs.rawValue
  }

  public static func <(lhs: Frequency, rhs: Frequency) -> Bool {
    return lhs.rawValue < rhs.rawValue
  }

}

extension Frequency: ExpressibleByFloatLiteral {

  /// Initialize with the frequency's value in Hz. Uses the absolute value of value provided.
  public init(floatLiteral value: Float64) {
    self.init(value)
  }

}

extension Frequency: ExpressibleByIntegerLiteral {

  /// Initializing from an interger value. This initializer simply converts the value into
  /// a `Float64` and intializes via `init(floatLiteral:)`.
  ///
  /// - Parameter value: The frequency in Hz.
  public init(integerLiteral value: Int) {
    self.init(floatLiteral: Float64(value))
  }

}
