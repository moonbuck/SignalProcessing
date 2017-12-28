//
//  FileIO.swift
//  generate_chords
//
//  Created by Jason Cardwell on 12/17/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import SignalProcessing

/// Generates a file name from the `baseName` argument and the specified parameter values.
///
/// - Parameters:
///   - ext: The extension for the file name.
///   - suffix: The text to appear in the file name after `baseName` but before the extension.
///   - octave: The octave or `nil`.
///   - variation: The variation or `nil`.
/// - Returns: The composed file name.
private func fileName(ext: String,
                      suffix: String,
                      octave: Int? = nil,
                      variation: Int? = nil) -> String
{

  var fileName = arguments.baseName
  if let octave = octave { fileName += "_octave=\(octave)" }
  if let variation = variation { fileName += "_variation=\(variation)" }
  fileName += "\(suffix).\(ext)"
  return fileName

}

/// Writes to disk a CSV formatted file composed of the specified infos.
///
/// - Parameters:
///   - infos: The infos to serve as the file's content.
///   - octave: The octave value used to generate `events` or `nil`.
///   - variation: Specifies which variation for `octave` these events represent or `nil`.
/// - Throws: Any error thrown while writing the generated text to disk.
func write(infos: [Info], octave: Int? = nil, variation: Int? = nil) throws {

  // Create a file name.
  let name = fileName(ext: "csv", suffix: "_info", octave: octave, variation: variation)

  // Create the URL.
  let url = arguments.outputDirectory.appendingPathComponent(name)

  // Create a string with the column headers.
  var text = "index,offset,marker,name,value\n"

  // Append the rows of data to `text`.
  for (index, offset, marker, name, value) in infos {
    print(index, offset.description, marker, name, value.description, separator: ",", to: &text)
  }

  // Create the data.
  guard let data = text.data(using: .utf8) else {
    fatalError("Failed to get raw data representation of `text`.")
  }

  // Write the data.
  try data.write(to: url)

  if arguments.verbose {
    print("info table written to '\(name)'")
  }

}

/// Writes to disk a MIDI file composed of the specified events.
///
/// - Parameters:
///   - events: The MIDI events to serve as the file's content.
///   - octave: The octave value used to generate `events` or `nil`.
///   - variation: Specifies which variation for `octave` these events represent or `nil`.
/// - Throws: Any error encountered writing the data to disk.
func write(events: [MIDIEvent], octave: Int? = nil, variation: Int? = nil) throws {

  // Create the MIDI file.
  let midiFile = MIDIFile(tracks: [events])

  // Create a file name.
  let name = fileName(ext: "mid", suffix: "", octave: octave, variation: variation)

  // Create the URL.
  let url = arguments.outputDirectory.appendingPathComponent(name)

  // Write the MIDI file's data.
  try midiFile.data.write(to: url)

  if arguments.verbose {
    print("MIDI file written to '\(name)'")
  }

  guard arguments.eventList else { return }

  try writeList(of: events, octave: octave, variation: variation)

}

/// Writes to disk a list of note and marker events.
///
/// - Parameters:
///   - events: The events to write to a text file.
///   - octave: The octave value used to generate `events` or `nil`.
///   - variation: Specifies which variation for `octave` these events represent or `nil`.
/// - Throws: Any error encountered writing the data to disk.
func writeList(of events: [MIDIEvent], octave: Int? = nil, variation: Int? = nil) throws {

  var text = ""

  for event in events {

    switch event {

      case .channel(let event):

        let kind: String
        switch event.status.kind {
          case .noteOn: kind = "on"
          case .noteOff: kind = "off"
          default: fatalError("Unexpected kind of channel event.")
        }

        let pitch = Pitch(rawValue: Int(event.data1))
        let velocity = event.data2!

        print(event.time.description, kind, pitch.description, velocity.description,
              separator: " ", to: &text)

      case .meta(let event):
        print(event.time.description, event.data.description, to: &text)

    }

  }

  // Create a file name.
  let name = fileName(ext: "txt", suffix: "_events", octave: octave, variation: variation)

  // Create the URL.
  let url = arguments.outputDirectory.appendingPathComponent(name)

  // Create the data.
  guard let data = text.data(using: .utf8) else {
    fatalError("Failed to get raw data representation of `text`.")
  }

  // Write the data.
  try data.write(to: url)

  if arguments.verbose {
    print("list of MIDI events written to '\(name)'")
  }

}
