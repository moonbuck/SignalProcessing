//
//  ChordMIDIEvents.swift
//  generate_chords
//
//  Created by Jason Cardwell on 12/14/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import typealias CoreMIDI.MIDITimeStamp
import SignalProcessing

/// Generates a random velocity value from `45` through `127`.
///
/// - Returns: The randomly generated velocity value.
private func randomVelocity() -> UInt8 { return UInt8(arc4random_uniform(83) + 45) }

/// Generates an ASCII friendly chord name from the given chord name.
///
/// - Parameter name: The non-ASCII chord name.
/// - Returns: A version of `name` with all ASCII characters.
func asciiChordName(_ name: String) -> String {
  var result = ""
  for character in name {
    switch character {
      case "♭": result.append("b")
      case "♯": result.append("#")
      case "╱": result.append("/")
      case "°": result.append("dim")
      default:  result.append(character)
    }
  }
  return result

}

/// Generates MIDI events that amounts to each chord in the chord library being played
/// consecutively with each chord playing for two seconds.
///
/// - Parameter octave: The tone height for the root pitch of each chord.
/// - Returns: The generated MIDI events, the names used in marker events, the chord names,
///            and chord raw values.
func generateChordEvents(octave: Int) -> (events: [MIDIEvent],
                                          markers: [String],
                                          names: [String],
                                          values: [UInt32] )
{

  var midiEvents: [MIDIEvent] = []
  var currentOffset: MIDITimeStamp = 0
  let duration: MIDITimeStamp = 1920

  var names: [String] = [], markers: [String] = [], values: [UInt32] = []

  for chord in ChordLibrary.chords.values.joined() {

    values.append(chord.rawValue)
    names.append(chord.name)

    let asciiName = asciiChordName(chord.name)

    midiEvents.append(.meta(MIDIEvent.MetaEvent(time: currentOffset,
                                                data: .marker(name: asciiName))))

    let pitches = chord.pitches(rootToneHeight: octave)

    markers.append(asciiName)

    for pitch in pitches {

      midiEvents.append(.channel(try! MIDIEvent.ChannelEvent(type: .noteOn,
                                                             channel: 0,
                                                             data1: UInt8(pitch.rawValue),
                                                             data2: randomVelocity(),
                                                             time: currentOffset)))

    }

    currentOffset += duration

    for pitch in pitches {

      midiEvents.append(.channel(try! MIDIEvent.ChannelEvent(type: .noteOff,
                                                             channel: 0,
                                                             data1: UInt8(pitch.rawValue),
                                                             data2: randomVelocity(),
                                                             time: currentOffset)))

    }

  }

  return (events: midiEvents, markers: markers, names: names, values: values)

}
