//
//  FileIO.swift
//  generate_chords
//
//  Created by Jason Cardwell on 12/17/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import SignalProcessing

/// Writes a CSV formatted file composed of the provided column values to the output directory
/// with file name '`arguments.baseName`_info.csv'
///
/// - Parameters:
///   - markers: The list of markers in the order they were inserted into the MIDI file(s).
///   - names: The list of chord names in the order they appear in the MIDI file(s).
///   - values: The raw chord values that correspond with `names`.
/// - Throws: Any error thrown while writing the generated text to disk.
func writeInfo(markers: [String], names: [String], values: [UInt32]) throws {

  // Create the URL.
  let url = arguments.outputDirectory.appendingPathComponent("\(arguments.baseName)_info.csv")

  // Create a string with the column headers.
  var text = "marker,name,value\n"

  guard markers.count == names.count && names.count == values.count else {
    fatalError("`markers`, `names`, and `values` do not all contain the same number of elements.")
  }

  // Append the rows of data to `text`.
  for index in 0 ..< markers.count {
    print(markers[index], names[index], values[index].description, separator: ",", to: &text)
  }

  // Create the data.
  guard let data = text.data(using: .utf8) else {
    fatalError("Failed to get raw data representation of `text`.")
  }

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
  let fileName = "\(arguments.baseName)_octave=\(octave)_variation=\(variation).mid"

  // Create the URL.
  let url = arguments.outputDirectory.appendingPathComponent(fileName)

  // Write the MIDI file's data.
  try midiFile.data.write(to: url)

}
