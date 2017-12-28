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

/// All chords in the chord library. Establishes the order in which chords will appear.
let allChords: [Chord] = Array(ChordLibrary.chords.values.joined())

/// Generates a random velocity value from `45` through `127`.
///
/// - Returns: The randomly generated velocity value.
private func randomVelocity() -> UInt8 { return UInt8(arc4random_uniform(83) + 45) }

/// Generates an ASCII friendly chord name from the given chord name.
///
/// - Parameter name: The non-ASCII chord name.
/// - Returns: A version of `name` with all ASCII characters.
private func asciiChordName(_ name: String) -> String {
  var result = ""
  for character in name {
    switch character {
      case "♭": result.append("b")
      case "♯": result.append("#")
      case "╱": result.append("/")
      case "+": result.append("aug")
      case "°": result.append("dim")
      default:  result.append(character)
    }
  }
  return result

}

/// The number of ticks per chord.
private let eventDuration: MIDITimeStamp = 1920

private typealias ChannelEvent = MIDIEvent.ChannelEvent
private typealias MetaEvent = MIDIEvent.MetaEvent

/// Generates a two-byte channel event for the specified pitch.
///
/// - Parameters:
///   - pitch: The pitch to stop.
///   - offset: The timestamp for the event.
///   - type: The event type. Should be an event that uses both data bytes.
/// - Returns: The generated MIDI event.
private func noteEvent(pitch: Pitch,
                       offset: MIDITimeStamp,
                       type: ChannelEvent.Status.Kind) -> MIDIEvent
{
  return .channel(try! ChannelEvent(type: type,
                                    channel: 0,
                                    data1: UInt8(pitch.rawValue),
                                    data2: randomVelocity(),
                                    time: offset))
}

typealias Info = (index: Int, offset: MIDITimeStamp, marker: String, name: String, value: UInt32)

/// Generates MIDI events that amounts to each chord in the chord library being played
/// consecutively with each chord playing for two seconds.
///
/// - Parameters:
///   - offset: The current offset.
///   - octave: The tone height for the root pitch of each chord.
///   - count: The number of times each chord should be played.
/// - Returns: The ending offset, the generated MIDI events and the corresponding infos.
func generateChordEvents(offset: MIDITimeStamp,
                         chordIndex: Int,
                         octave: Int,
                         count: Int) -> (MIDITimeStamp, Int, [MIDIEvent], [Info])
{

  var midiEvents: [MIDIEvent] = []
  var offset = offset

  var infos: [(index: Int, offset: MIDITimeStamp, marker: String, name: String, value: UInt32)] = []

  var chordIndex = chordIndex

  for chord in allChords {

    let name = chord.name
    let value = chord.rawValue
    let markerPrefix = asciiChordName(name)
    let pitches = chord.pitches(rootToneHeight: octave)

    for variation in 0 ..< count {

      let index = chordIndex * count + variation + 1
      let marker = "\(index)_\(markerPrefix)_octave=\(octave)_variation=\(variation + 1)"
      infos.append((index: index, offset: offset, marker: marker, name: name, value: value))

      midiEvents.append(.meta(MetaEvent(time: offset, data: .marker(name: marker))))


      for pitch in pitches {
        midiEvents.append(noteEvent(pitch: pitch, offset: offset, type: .noteOn))
      }

      offset += eventDuration

      for pitch in pitches {
        midiEvents.append(noteEvent(pitch: pitch, offset: offset, type: .noteOff))
      }

    }

    chordIndex += 1

  }

  return (offset, chordIndex, midiEvents, infos)

}
