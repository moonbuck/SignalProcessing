//
//  IO.swift
//  chords
//
//  Created by Jason Cardwell on 1/8/18.
//  Copyright © 2018 Moondeer Studios. All rights reserved.
//
import Foundation
import SignalProcessing
import MoonKit

func dumpInfo(for pattern: ChordPattern) {

  print("""
    Chord Pattern
    ─────────────
    suffix: \(pattern.suffix)
    intervals: \(pattern.intervals.map(\.symbol).joined(separator: ", "))
    # notes: \(pattern.noteCount)
    value: \(String(pattern.rawValue, radix: 2, pad: 24, group: 4)) \(pattern.rawValue)
    """)

}

func dumpInfo(for pattern: ChordPattern, with root: Pitch) {

  let chord = Chord(root: root.chroma, pattern: pattern)
  let pitches = chord.pitches(rootToneHeight: root.toneHeight)

  print("""
    Chord (with root \(root))
    ─────────────────────
    name: \(chord.name)
    intervals: \(chord.pattern.intervals.map(\.symbol).joined(separator: ", "))
    # notes: \(chord.pattern.noteCount)
    value: \(String(chord.rawValue, radix: 2, pad: 32, group: 4)) \(chord.rawValue)
    chromas: \(chord.chromas.map(\.description).joined(separator: ", "))
    pitches: \(pitches.map(\.description).joined(separator: "-"))
    MIDI: \(pitches.map(\.rawValue.description).joined(separator: ", "))
    """)

}

