//
//  ChordProgression.swift
//  Chord Finder
//
//  Created by Jason Cardwell on 9/01/17.
//  Copyright (c) 2017 Moondeer Studios. All rights reserved.
//
import Foundation

/// A collection of chords coupled with their rate of progression in Hertz.
public struct ChordProgression: Collection {

  public var startIndex: Int { return chords.startIndex }
  public var endIndex: Int { return chords.endIndex }
  public var count: Int { return chords.count }

  public func index(after i: Int) -> Int { return i &+ 1 }

  public subscript(position: Int) -> Chord { return chords[position] }

  /// The chords that make up the progression.
  public let chords: [Chord]

  /// The rate of the chord progression in Hertz.
  public let rate: Float

  /// An array containing a set of pitches for each chord or `nil` if the composition of the a 
  /// chord was not provided.
  public let compositions: [[Pitch]]

  /// The number of notes for each chord.
  public var noteCounts: [Int] { return compositions.map { $0.count } }

  /// The root pitch for each chord.
  public var roots: [Pitch] { return compositions.map { $0[0] } }

  /// Initializing with the chords and their rate of progression.
  ///
  /// - Parameters:
  ///   - chords: The chords that make up the progression.
  ///   - rate: The rate of the chord progression in Hertz.
  ///   - compositions: An array containing pitches for each chord.
  public init(chords: [Chord], rate: Float, compositions: [[Pitch]]) {

    guard rate > 0 else { fatalError("\(#function) `rate` must be > `0`.")}

    guard compositions.first(where: {$0.isEmpty}) == nil else {
      fatalError("Empty chord compositions are not allowed.")
    }

    self.chords = chords
    self.rate = rate
    self.compositions = compositions.map({Array(Set($0)).sorted()})
  }

  /// Returns the chord in the progression that corresponds to the specified frame given the
  /// frame rate.
  ///
  /// - Parameters:
  ///   - frame: The frame for which a chord is to be returned.
  ///   - frameRate: The frame rate in Hertz.
  /// - Returns: The chord corresponding to `frame`.
  public func chord(forFrame frame: Int, frameRate: Float) -> Chord {

    return chords[index(for: frame, at: frameRate)]

  }

  /// Returns the chord composition in the progression that corresponds to the specified frame
  /// given the frame rate.
  ///
  /// - Parameters:
  ///   - frame: The frame for which a composition is to be returned.
  ///   - frameRate: The frame rate in Hertz.
  /// - Returns: The chord composition corresponding to `frame`.
  public func composition(forFrame frame: Int, frameRate: Float) -> [Pitch] {

    return compositions[index(for: frame, at: frameRate)]

  }

  /// Calculates the index that corresponds to a frame given the frame rate.
  ///
  /// - Parameters:
  ///   - frame: The frame for which to calculate an index.
  ///   - frameRate: The rate associated with `frame` in Hz.
  /// - Returns: The index in the collection that corresponds to the given frame and rate.
  private func index(for frame: Int, at frameRate: Float) -> Int {

    // Make sure we don't divide by zero.
    guard frameRate > 0 else { fatalError("\(#function) `frameRate` cannot be `0`.") }

    // Calculate the index.
    let index = Int(Float(frame) / (rate / frameRate))

    // Ensure the index is > than `0`.
    guard index > 0 else { return 0 }

    // Ensure the index is < `endIndex`.
    guard index < endIndex else { return endIndex &- 1 }

    return index

  }

}

/// Extending with various debugging aids.
extension ChordProgression {

  public var allNotes: Set<Pitch> { return Set(compositions.joined()) }

  public var allNotesDescription: String {

    let noteColCount = 7
    let partialColCount = 9
    let freqRangeColCount = 25
    let binRangeColCount = 17
    let nearestColCount = 15


    var result = ""

    "Note".padded(to: noteColCount, alignment: .center).write(to: &result)

    result += "│"

    "Partial".padded(to: partialColCount, alignment: .center).write(to: &result)

    result += "│"

    "±12 cents (Hz)".padded(to: freqRangeColCount, alignment: .center).write(to: &result)

    result += "│"

    "±12 cents (Bin)".padded(to: binRangeColCount, alignment: .center).write(to: &result)

    result += "│"

    "Nearest Pitch".padded(to: nearestColCount, alignment: .center).write(to: &result)

    result += "\n"
    result += "─" * noteColCount
    result += "┼"
    result += "─" * partialColCount
    result += "┼"
    result += "─" * freqRangeColCount
    result += "┼"
    result += "─" * binRangeColCount
    result += "┼"
    result += "─" * nearestColCount
    result += "\n"


    for note in allNotes.sorted() {

      note.description.padded(to: noteColCount, alignment: .center).write(to: &result)

      result += "│"

      let partials = Array(Set(note.partials).sorted().enumerated())

      for (p, partial) in partials {

        (p + 1).description.padded(to: partialColCount, alignment: .center).write(to: &result)

        result += "│"

        let partialFrequency = Frequency(rawValue: note.centerFrequency.rawValue * Float64(p + 1))

        let lowerBound = partialFrequency.advanced(by: -12)
        let upperBound = partialFrequency.advanced(by: 12)

        let lowerBoundDesc = lowerBound.description.padded(to: 10, alignment: .right)
        let upperBoundDesc = upperBound.description.padded(to: 10, alignment: .right)

        "\(lowerBoundDesc) - \(upperBoundDesc)"
          .padded(to: freqRangeColCount, alignment: .center).write(to: &result)

        result += "│"

        let lowerBin = lowerBound.bin(for: 44100, windowSize: 8820)
        let upperBin = upperBound.bin(for: 44100, windowSize: 8820)

        let lowerBinDesc = lowerBin.description.padded(to: 4, alignment: .right)
        let upperBinDesc = upperBin.description.padded(to: 4, alignment: .right)

        "\(lowerBinDesc) - \(upperBinDesc)"
          .padded(to: binRangeColCount, alignment: .center).write(to: &result)

        result += "│"

        partial.description.padded(to: nearestColCount, alignment: .center).write(to: &result)


        if (p + 1) < partials.count {

          result += "\n\(" " * noteColCount)│"

        }

      }

      result += "\n"
      result += " " * noteColCount
      result += "│"
      result += " " * partialColCount
      result += "│"
      result += " " * freqRangeColCount
      result += "│"
      result += " " * binRangeColCount
      result += "│\n"

    }

    return result

  }
  
}
