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
var didWriteInfoFile = false

// Iterate the specified octaves.
for octave in arguments.octaves {

  // Iterate the variations
  for variation in 0 ..< arguments.variations {

    // Generate the MIDI events.
    let (events, markers, names, values) = generateChordEvents(octave: octave)

    // Try writing the MIDI file to disk.
    do {
      try write(events: events, octave: octave, variation: variation)
    } catch {
      print("Error writing MIDI file to disk: \(error.localizedDescription)")
      exit(EXIT_FAILURE)
    }

    // Check whether names and values remain to be written to disk.
    guard !didWriteInfoFile else { continue }

    // Try writing the info files to disk and updating the flag.
    do {
      try writeInfo(markers: markers, names: names, values: values)
      didWriteInfoFile = true
    } catch {
      print("Error writing info file to disk: \(error.localizedDescription)")
      exit(EXIT_FAILURE)
    }

    
  }

}

