//
//  Pitch.swift
//  Chord Finder
//
//  Created by Jason Cardwell on 8/24/17.
//  Copyright (c) 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import MoonKit

/// A structure for representing a pitch in twelve-tone equal temperament.
public struct Pitch: RawRepresentable {

  /// The index assigned to the pitch where 0-127 represent C-1-G9.
  public let rawValue: Int

  public static let pianoKeys: CountableRange<Pitch> = 21..<109

  /// Initialize with a pitch index.
  public init(rawValue: Int) { self.rawValue = rawValue }

  /// Initialize with the chroma and tone height values.
  public init(chroma: Chroma, toneHeight: Int) {
    rawValue = (toneHeight + 1) * 12 + chroma.rawValue
  }

  public init?(stringValue: String) {

    // Capture the chroma and tone height or intialize with a default of C4 and return.
    guard let match = (~/"([a-gA-G][♭b]?)(-?[0-9])").firstMatch(in: stringValue),
      let chromaLiteral = match.captures[1]?.substring,
      let toneHeightLiteral = match.captures[2]?.substring
      else
    {
      return nil
    }

    self.init(chroma: Chroma(stringLiteral: String(chromaLiteral)),
              toneHeight: Int(toneHeightLiteral)!)
  }

  /// The pitch's center frequency given in Hz.
  public var centerFrequency: Frequency {
    return Frequency(rawValue: exp2(Float64(rawValue - 69) / 12) * 440)
  }

  /// The ideal sample rate for frequency filtering.
  public var sampleRate: SampleRate {
    switch rawValue {
      case 0...19:   return 441
      case 20...58:  return 882
      case 59...94:  return 4410
      case 95...120: return 22050
      default:       return 44100
    }
  }

  /// The pitch's octave.
  public var toneHeight: Int { return rawValue / 12 - 1 }

  /// The pitch's chroma.
  public var chroma: Chroma { return Chroma(rawValue: rawValue % 12) }

  /// Initializing with a frequency.
  public init(_ frequency: Frequency) { self = frequency.pitch }

  /// The partials for the pitch within the MIDI pitches.
  public var partials: [Pitch] {

    // Create an array for the partials.
    var partials: [Pitch] = []

    // Get the center frequency of the pitch as a float value.
    let frequency = centerFrequency.rawValue

    // Create a variable to hold which is the current partial.
    var partialNumber = 1.0

    // Create a variable to hold the actual partial.
    var partial: Pitch = self

    // Iterate while the partial is still a valid MIDI pitch.
    while partial.rawValue < 128 {

      // Append the current partial.
      partials.append(partial)

      // Increment the partial number.
      partialNumber += 1

      // Update `partial` by multiplying the frequency by the number for the next partial.
      partial = Pitch(Frequency(rawValue: frequency * partialNumber))

    }

    return partials

  }

}

extension Pitch: CustomPlaygroundDisplayConvertible {

  public var playgroundDescription: Any {  return description  }

}

extension Pitch: CustomStringConvertible {

  public var description: String {
    return "\(chroma)\(toneHeight >= 0 ? "\(toneHeight)" : "-\(abs(toneHeight))")"
  }

}

extension Pitch: ExpressibleByIntegerLiteral {

  public init(integerLiteral value: Int) { self.init(rawValue: value) }

}

extension Pitch: ExpressibleByStringLiteral {

  public init(stringLiteral value: String) {

    // Capture the chroma and tone height or intialize with a default of C4 and return.
    guard let match = (~/"([a-gA-G][♭b]?)(-?[0-9])").firstMatch(in: value),
          let chromaLiteral = match.captures[1]?.substring,
          let toneHeightLiteral = match.captures[2]?.substring
    else
    {
      self.init(chroma: .C, toneHeight: 4)
      return
    }

    self.init(chroma: Chroma(stringLiteral: String(chromaLiteral)),
              toneHeight: Int(toneHeightLiteral)!)

  }

}

extension Pitch: Comparable {

  public static func ==(lhs: Pitch, rhs: Pitch) -> Bool {
    return lhs.rawValue == rhs.rawValue
  }

  public static func <(lhs: Pitch, rhs: Pitch) -> Bool {
    return lhs.rawValue < rhs.rawValue
  }

}

extension Pitch: Hashable {

  public var hashValue: Int { return rawValue }
  
}

extension Pitch: Strideable {

  public func advanced(by n: Int) -> Pitch {
    return Pitch(rawValue: rawValue.advanced(by: n))
  }

  public func distance(to other: Pitch) -> Int {
    return rawValue.distance(to: other.rawValue)
  }

}
