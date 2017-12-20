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

// Switch on the octave and variation joining argument values.
switch (arguments.joinOctaves, arguments.joinVariations) {

  case (true, true):
    // Create one MIDI file with all the events.

    var allEvents: [MIDIEvent] = []
    var allInfos: [Info] = []

    let count = arguments.variations
    var offset: MIDITimeStamp = 0
    var chordIndex: Int = 0

    for octave in arguments.octaves {

      let (newOffset, newChordIndex, events, infos) = generateChordEvents(offset: offset,
                                                                          chordIndex: chordIndex,
                                                                          octave: octave,
                                                                          count: count)

      allEvents += events
      allInfos += infos
      offset = newOffset
      chordIndex = newChordIndex

    }

    // Try writing the MIDI file to disk.
    do {
      try write(events: allEvents)
    } catch {
      print("Error writing MIDI file to disk: \(error.localizedDescription)")
      exit(EXIT_FAILURE)
    }

    // Try writing the info files to disk and updating the flag.
    do {
      try write(infos: allInfos)
    } catch {
      print("Error writing info file to disk: \(error.localizedDescription)")
      exit(EXIT_FAILURE)
  }


  case (false, true):
    // Create a MIDI file for each octave that contains events for all the variations.

    for octave in arguments.octaves {

      let (_, _, events, infos) = generateChordEvents(offset: 0,
                                                      chordIndex: 0,
                                                      octave: octave,
                                                      count: arguments.variations)

      // Try writing the MIDI file to disk.
      do {
        try write(events: events, octave: octave)
      } catch {
        print("Error writing MIDI file to disk: \(error.localizedDescription)")
        exit(EXIT_FAILURE)
      }

      // Try writing the info files to disk and updating the flag.
      do {
        try write(infos: infos, octave: octave)
      } catch {
        print("Error writing info file to disk: \(error.localizedDescription)")
        exit(EXIT_FAILURE)
      }

    }

  case (true, false):
    // Create a MIDI file for each variation that contains events for all octaves.

    for variation in 0 ..< arguments.variations {

      var allEvents: [MIDIEvent] = []
      var allInfos: [Info] = []
      var offset: MIDITimeStamp = 0
      var chordIndex: Int = 0

      for octave in arguments.octaves {

        let (newOffset, newChordIndex, events, infos) = generateChordEvents(offset: offset,
                                                                            chordIndex: chordIndex,
                                                                            octave: octave,
                                                                            count: 1)
        allEvents += events
        allInfos += infos
        offset = newOffset
        chordIndex = newChordIndex

      }

      // Try writing the MIDI file to disk.
      do {
        try write(events: allEvents, variation: variation)
      } catch {
        print("Error writing MIDI file to disk: \(error.localizedDescription)")
        exit(EXIT_FAILURE)
      }

      // Try writing the info files to disk and updating the flag.
      do {
        try write(infos: allInfos, variation: variation)
      } catch {
        print("Error writing info file to disk: \(error.localizedDescription)")
        exit(EXIT_FAILURE)
      }


    }

  case (false, false):
    // For each variation, create a MIDI file for each octave.

    // Iterate the specified octaves.
    for octave in arguments.octaves {

      // Iterate the variations
      for variation in 0 ..< arguments.variations {

        // Generate the MIDI events.
        let (_, _, events, infos) = generateChordEvents(offset: 0,
                                                        chordIndex: 0,
                                                        octave: octave,
                                                        count: 1)

        // Try writing the MIDI file to disk.
        do {
          try write(events: events, octave: octave, variation: variation)
        } catch {
          print("Error writing MIDI file to disk: \(error.localizedDescription)")
          exit(EXIT_FAILURE)
        }

        // Try writing the info files to disk and updating the flag.
        do {
          try write(infos: infos, octave: octave, variation: variation)
        } catch {
          print("Error writing info file to disk: \(error.localizedDescription)")
          exit(EXIT_FAILURE)
        }


      }

    }

}


