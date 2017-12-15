//
//  main.swift
//  generate_chords
//
//  Created by Jason Cardwell on 12/14/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import typealias CoreMIDI.MIDITimeStamp
import SignalProcessing

// Parse the command-line arguments.
let arguments = Arguments()

// Create flags for indicating whether marker, name and value files have been written.
var didWriteInfoFiles = false

// Iterate the specified octaves.
for octave in arguments.octaves {

  // Generate the MIDI events.
  let (events, markers, names, values) = generateChordEvents(octave: octave)

  // Create the MIDI file.
  let midiFile = MIDIFile(tracks: [events])

  let fileNamePrefix = arguments.midiFileDestination.lastPathComponent

  let directory = arguments.midiFileDestination.deletingLastPathComponent()

  let midiURL = directory.appendingPathComponent("\(fileNamePrefix)_tone-height=\(octave).mid")

  // Try writing the MIDI file to the specified location.
  do {
    try midiFile.data.write(to: midiURL)
  } catch {
    print("Error writing MIDI file to '\(midiURL)': \(error.localizedDescription)")
    exit(EXIT_FAILURE)
  }

  // Check whether names and values remain to be written to disk.
  guard !didWriteInfoFiles else { continue }

  let markerURL = directory.appendingPathComponent("\(fileNamePrefix)_markers.txt")
  guard let markerData = markers.joined(separator: "\n").data(using: .utf8) else {
    print("Failed to convert list of markers to raw bytes.")
    exit(EXIT_FAILURE)
  }

  do {
    try markerData.write(to: markerURL)
  } catch {
    print("Error writing marker file to '\(markerURL)': \(error.localizedDescription)")
    exit(EXIT_FAILURE)
  }

  let nameURL = directory.appendingPathComponent("\(fileNamePrefix)_names.txt")
  guard let nameData = names.joined(separator: "\n").data(using: .utf8) else {
    print("Failed to convert list of chord names to raw bytes.")
    exit(EXIT_FAILURE)
  }

  do {
    try nameData.write(to: nameURL)
  } catch {
    print("Error writing name file to '\(nameURL)': \(error.localizedDescription)")
    exit(EXIT_FAILURE)
  }

  let valueURL = directory.appendingPathComponent("\(fileNamePrefix)_values.txt")
  guard let valueData = values.map(\.description).joined(separator: "\n").data(using: .utf8) else {
    print("Failed to convert list of chord values to raw bytes.")
    exit(EXIT_FAILURE)
  }

  do {
    try valueData.write(to: valueURL)
  } catch {
    print("Error writing value file to '\(valueURL)': \(error.localizedDescription)")
    exit(EXIT_FAILURE)
  }

  didWriteInfoFiles = true

}

