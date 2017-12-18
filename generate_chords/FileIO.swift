//
//  FileIO.swift
//  generate_chords
//
//  Created by Jason Cardwell on 12/17/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import SignalProcessing

/// Writes a text file to composed of the specified list of value descriptions joined by '\n'
/// to the output directory with a file name composed of `arguments.baseName` and
/// the specified suffix.
///
/// - Parameters:
///   - list: The values whose descriptions will be joined to serve as the file's content.
///   - suffix: The suffix to tack on to the end of the file name.
/// - Throws: Any error encountered writing the data to disk.
func write<T:CustomStringConvertible>(list: [T], suffix: String) throws {

  // Create the URL.
  let url = arguments.outputDirectory.appendingPathComponent("\(arguments.baseName)_\(suffix).txt")

  // Create the data.
  let data = list.map(\.description).joined(separator: "\n").data(using: .utf8)!

  // Write the data.
  try data.write(to: url)

}

/// Writes a MIDI file composed of the specified events to the output directory with a file name
/// composed of `arguments.baseName` and the specified octave and variation values.
///
/// - Parameters:
///   - events: The MIDI events to serve as the file's content.
///   - octave: The octave value used to generate `events`.
///   - variation: Specifies which variation for `octave` these events represent.
/// - Throws: Any error encountered writing the data to disk.
func write(events: [MIDIEvent], octave: Int, variation: Int) throws {

  // Create the MIDI file.
  let midiFile = MIDIFile(tracks: [events])

  // Compose the file name.
  let fileName = "\(arguments.baseName)octave=\(octave)_variation=\(variation).mid"

  // Create the URL.
  let url = arguments.outputDirectory.appendingPathComponent(fileName)

  // Write the MIDI file's data.
  try midiFile.data.write(to: url)

}
