//
//  ChordTests.swift
//  SignalProcessing
//
//  Created by Jason Cardwell on 12/15/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import XCTest
@testable import SignalProcessing

class ChordTests: XCTestCase {

  /// Tests `Chroma` creation, partial subscripting and retrieving the chroma for an interval.
  func testChroma() {

    XCTAssertEqual(Chroma(rawValue: 0), .C)
    XCTAssertEqual(Chroma(rawValue: 6), .Gb)
    XCTAssertEqual(Chroma(rawValue: 11), .B)
    XCTAssertEqual(Chroma(rawValue: 12), .C)
    XCTAssertEqual(Chroma(rawValue: -6), .Gb)
    XCTAssertEqual(Chroma(rawValue: 15), .Eb)

    XCTAssertEqual(Chroma.F[1], .F)
    XCTAssertEqual(Chroma.F[2], .F)
    XCTAssertEqual(Chroma.F[3], .C)
    XCTAssertEqual(Chroma.F[4], .F)
    XCTAssertEqual(Chroma.F[5], .A)
    XCTAssertEqual(Chroma.F[6], .C)
    XCTAssertEqual(Chroma.F[7], .Eb)
    XCTAssertEqual(Chroma.F[8], .F)
    XCTAssertEqual(Chroma.F[9], .G)
    XCTAssertEqual(Chroma.F[10], .A)
    XCTAssertEqual(Chroma.F[11], .B)
    XCTAssertEqual(Chroma.F[12], .C)
    XCTAssertEqual(Chroma.F[13], .Db)
    XCTAssertEqual(Chroma.F[14], .Eb)
    XCTAssertEqual(Chroma.F[15], .E)
    XCTAssertEqual(Chroma.F[16], .F)
    XCTAssertEqual(Chroma.F[17], .Gb)
    XCTAssertEqual(Chroma.F[18], .G)
    XCTAssertEqual(Chroma.F[19], .Ab)
    XCTAssertEqual(Chroma.F[20], .A)

    XCTAssertEqual(Chroma.C[.m2], .Db)
    XCTAssertEqual(Chroma.C[.M2], .D)
    XCTAssertEqual(Chroma.C[.A2], .Eb)
    XCTAssertEqual(Chroma.C[.m3], .Eb)
    XCTAssertEqual(Chroma.C[.M3], .E)
    XCTAssertEqual(Chroma.C[.A3], .F)
    XCTAssertEqual(Chroma.C[.d4], .E)
    XCTAssertEqual(Chroma.C[.P4], .F)
    XCTAssertEqual(Chroma.C[.A4], .Gb)
    XCTAssertEqual(Chroma.C[.d5], .Gb)
    XCTAssertEqual(Chroma.C[.P5], .G)
    XCTAssertEqual(Chroma.C[.A5], .Ab)
    XCTAssertEqual(Chroma.C[.m6], .Ab)
    XCTAssertEqual(Chroma.C[.M6], .A)
    XCTAssertEqual(Chroma.C[.A6], .Bb)
    XCTAssertEqual(Chroma.C[.m7], .Bb)
    XCTAssertEqual(Chroma.C[.M7], .B)
    XCTAssertEqual(Chroma.C[.A7], .C)
    XCTAssertEqual(Chroma.C[.d8], .B)
    XCTAssertEqual(Chroma.C[.P8], .C)
    XCTAssertEqual(Chroma.C[.A8], .Db)
    XCTAssertEqual(Chroma.C[.m9], .Db)
    XCTAssertEqual(Chroma.C[.M9], .D)
    XCTAssertEqual(Chroma.C[.A9], .Eb)
    XCTAssertEqual(Chroma.C[.m10], .Eb)
    XCTAssertEqual(Chroma.C[.M10], .E)
    XCTAssertEqual(Chroma.C[.A10], .F)
    XCTAssertEqual(Chroma.C[.d11], .E)
    XCTAssertEqual(Chroma.C[.P11], .F)
    XCTAssertEqual(Chroma.C[.A11], .Gb)
    XCTAssertEqual(Chroma.C[.d12], .Gb)
    XCTAssertEqual(Chroma.C[.P12], .G)
    XCTAssertEqual(Chroma.C[.A12], .Ab)
    XCTAssertEqual(Chroma.C[.m13], .Ab)
    XCTAssertEqual(Chroma.C[.M13], .A)
    XCTAssertEqual(Chroma.C[.A13], .Bb)

  }

  /// Tests the basic chord interval properties.
  func testChordInterval() {

    XCTAssertTrue(ChordInterval.M2.isNatural)
    XCTAssertFalse(ChordInterval.M2.isSharp)
    XCTAssertFalse(ChordInterval.M2.isFlat)
    XCTAssertFalse(ChordInterval.m2.isNatural)
    XCTAssertFalse(ChordInterval.m2.isSharp)
    XCTAssertTrue(ChordInterval.m2.isFlat)
    XCTAssertFalse(ChordInterval.A2.isNatural)
    XCTAssertTrue(ChordInterval.A2.isSharp)
    XCTAssertFalse(ChordInterval.A2.isFlat)
    XCTAssertTrue(ChordInterval.M3.isNatural)
    XCTAssertFalse(ChordInterval.M3.isSharp)
    XCTAssertFalse(ChordInterval.M3.isFlat)
    XCTAssertFalse(ChordInterval.m3.isNatural)
    XCTAssertFalse(ChordInterval.m3.isSharp)
    XCTAssertTrue(ChordInterval.m3.isFlat)
    XCTAssertFalse(ChordInterval.A3.isNatural)
    XCTAssertTrue(ChordInterval.A3.isSharp)
    XCTAssertFalse(ChordInterval.A3.isFlat)
    XCTAssertTrue(ChordInterval.P4.isNatural)
    XCTAssertFalse(ChordInterval.P4.isSharp)
    XCTAssertFalse(ChordInterval.P4.isFlat)
    XCTAssertFalse(ChordInterval.d4.isNatural)
    XCTAssertFalse(ChordInterval.d4.isSharp)
    XCTAssertTrue(ChordInterval.d4.isFlat)
    XCTAssertFalse(ChordInterval.A4.isNatural)
    XCTAssertTrue(ChordInterval.A4.isSharp)
    XCTAssertFalse(ChordInterval.A4.isFlat)
    XCTAssertTrue(ChordInterval.P5.isNatural)
    XCTAssertFalse(ChordInterval.P5.isSharp)
    XCTAssertFalse(ChordInterval.P5.isFlat)
    XCTAssertFalse(ChordInterval.d5.isNatural)
    XCTAssertFalse(ChordInterval.d5.isSharp)
    XCTAssertTrue(ChordInterval.d5.isFlat)
    XCTAssertFalse(ChordInterval.A5.isNatural)
    XCTAssertTrue(ChordInterval.A5.isSharp)
    XCTAssertFalse(ChordInterval.A5.isFlat)
    XCTAssertTrue(ChordInterval.M6.isNatural)
    XCTAssertFalse(ChordInterval.M6.isSharp)
    XCTAssertFalse(ChordInterval.M6.isFlat)
    XCTAssertFalse(ChordInterval.m6.isNatural)
    XCTAssertFalse(ChordInterval.m6.isSharp)
    XCTAssertTrue(ChordInterval.m6.isFlat)
    XCTAssertFalse(ChordInterval.A6.isNatural)
    XCTAssertTrue(ChordInterval.A6.isSharp)
    XCTAssertFalse(ChordInterval.A6.isFlat)
    XCTAssertTrue(ChordInterval.M7.isNatural)
    XCTAssertFalse(ChordInterval.M7.isSharp)
    XCTAssertFalse(ChordInterval.M7.isFlat)
    XCTAssertFalse(ChordInterval.m7.isNatural)
    XCTAssertFalse(ChordInterval.m7.isSharp)
    XCTAssertTrue(ChordInterval.m7.isFlat)
    XCTAssertFalse(ChordInterval.A7.isNatural)
    XCTAssertTrue(ChordInterval.A7.isSharp)
    XCTAssertFalse(ChordInterval.A7.isFlat)
    XCTAssertTrue(ChordInterval.P8.isNatural)
    XCTAssertFalse(ChordInterval.P8.isSharp)
    XCTAssertFalse(ChordInterval.P8.isFlat)
    XCTAssertFalse(ChordInterval.d8.isNatural)
    XCTAssertFalse(ChordInterval.d8.isSharp)
    XCTAssertTrue(ChordInterval.d8.isFlat)
    XCTAssertFalse(ChordInterval.A8.isNatural)
    XCTAssertTrue(ChordInterval.A8.isSharp)
    XCTAssertFalse(ChordInterval.A8.isFlat)
    XCTAssertTrue(ChordInterval.M9.isNatural)
    XCTAssertFalse(ChordInterval.M9.isSharp)
    XCTAssertFalse(ChordInterval.M9.isFlat)
    XCTAssertFalse(ChordInterval.m9.isNatural)
    XCTAssertFalse(ChordInterval.m9.isSharp)
    XCTAssertTrue(ChordInterval.m9.isFlat)
    XCTAssertFalse(ChordInterval.A9.isNatural)
    XCTAssertTrue(ChordInterval.A9.isSharp)
    XCTAssertFalse(ChordInterval.A9.isFlat)
    XCTAssertTrue(ChordInterval.M10.isNatural)
    XCTAssertFalse(ChordInterval.M10.isSharp)
    XCTAssertFalse(ChordInterval.M10.isFlat)
    XCTAssertFalse(ChordInterval.m10.isNatural)
    XCTAssertFalse(ChordInterval.m10.isSharp)
    XCTAssertTrue(ChordInterval.m10.isFlat)
    XCTAssertFalse(ChordInterval.A10.isNatural)
    XCTAssertTrue(ChordInterval.A10.isSharp)
    XCTAssertFalse(ChordInterval.A10.isFlat)
    XCTAssertTrue(ChordInterval.P11.isNatural)
    XCTAssertFalse(ChordInterval.P11.isSharp)
    XCTAssertFalse(ChordInterval.P11.isFlat)
    XCTAssertFalse(ChordInterval.d11.isNatural)
    XCTAssertFalse(ChordInterval.d11.isSharp)
    XCTAssertTrue(ChordInterval.d11.isFlat)
    XCTAssertFalse(ChordInterval.A11.isNatural)
    XCTAssertTrue(ChordInterval.A11.isSharp)
    XCTAssertFalse(ChordInterval.A11.isFlat)
    XCTAssertTrue(ChordInterval.P12.isNatural)
    XCTAssertFalse(ChordInterval.P12.isSharp)
    XCTAssertFalse(ChordInterval.P12.isFlat)
    XCTAssertFalse(ChordInterval.d12.isNatural)
    XCTAssertFalse(ChordInterval.d12.isSharp)
    XCTAssertTrue(ChordInterval.d12.isFlat)
    XCTAssertFalse(ChordInterval.A12.isNatural)
    XCTAssertTrue(ChordInterval.A12.isSharp)
    XCTAssertFalse(ChordInterval.A12.isFlat)
    XCTAssertTrue(ChordInterval.M13.isNatural)
    XCTAssertFalse(ChordInterval.M13.isSharp)
    XCTAssertFalse(ChordInterval.M13.isFlat)
    XCTAssertFalse(ChordInterval.m13.isNatural)
    XCTAssertFalse(ChordInterval.m13.isSharp)
    XCTAssertTrue(ChordInterval.m13.isFlat)
    XCTAssertFalse(ChordInterval.A13.isNatural)
    XCTAssertTrue(ChordInterval.A13.isSharp)
    XCTAssertFalse(ChordInterval.A13.isFlat)


    XCTAssertEqual(ChordInterval.M2.semitones, 2)
    XCTAssertEqual(ChordInterval.m2.semitones, 1)
    XCTAssertEqual(ChordInterval.A2.semitones, 3)
    XCTAssertEqual(ChordInterval.M3.semitones, 4)
    XCTAssertEqual(ChordInterval.m3.semitones, 3)
    XCTAssertEqual(ChordInterval.A3.semitones, 5)
    XCTAssertEqual(ChordInterval.P4.semitones, 5)
    XCTAssertEqual(ChordInterval.d4.semitones, 4)
    XCTAssertEqual(ChordInterval.A4.semitones, 6)
    XCTAssertEqual(ChordInterval.P5.semitones, 7)
    XCTAssertEqual(ChordInterval.d5.semitones, 6)
    XCTAssertEqual(ChordInterval.A5.semitones, 8)
    XCTAssertEqual(ChordInterval.M6.semitones, 9)
    XCTAssertEqual(ChordInterval.m6.semitones, 8)
    XCTAssertEqual(ChordInterval.A6.semitones, 10)
    XCTAssertEqual(ChordInterval.M7.semitones, 11)
    XCTAssertEqual(ChordInterval.m7.semitones, 10)
    XCTAssertEqual(ChordInterval.A7.semitones, 12)
    XCTAssertEqual(ChordInterval.P8.semitones, 12)
    XCTAssertEqual(ChordInterval.d8.semitones, 11)
    XCTAssertEqual(ChordInterval.A8.semitones, 13)
    XCTAssertEqual(ChordInterval.M9.semitones, 14)
    XCTAssertEqual(ChordInterval.m9.semitones, 13)
    XCTAssertEqual(ChordInterval.A9.semitones, 15)
    XCTAssertEqual(ChordInterval.M10.semitones, 16)
    XCTAssertEqual(ChordInterval.m10.semitones, 15)
    XCTAssertEqual(ChordInterval.A10.semitones, 17)
    XCTAssertEqual(ChordInterval.P11.semitones, 17)
    XCTAssertEqual(ChordInterval.d11.semitones, 16)
    XCTAssertEqual(ChordInterval.A11.semitones, 18)
    XCTAssertEqual(ChordInterval.P12.semitones, 19)
    XCTAssertEqual(ChordInterval.d12.semitones, 18)
    XCTAssertEqual(ChordInterval.A12.semitones, 20)
    XCTAssertEqual(ChordInterval.M13.semitones, 21)
    XCTAssertEqual(ChordInterval.m13.semitones, 20)
    XCTAssertEqual(ChordInterval.A13.semitones, 22)

  }

  /// Tests `ChordPattern` creation, pattern suffix and interval retrieval.
  func testChordPattern() {

    XCTAssertEqual(ChordPattern(.M3, .P5), .﹡M)
    XCTAssertEqual(ChordPattern.﹡M.intervals, [.M3, .P5])
    XCTAssertEqual(ChordPattern(.M3, .P5).suffix, "M")
    XCTAssertEqual("M" as ChordPattern, .﹡M)

    XCTAssertEqual(ChordPattern(.M3, .P5, .m7, .M9, .A11, .m13), .﹡9s11_f13_)
    XCTAssertEqual(ChordPattern.﹡9s11_f13_.intervals, [.M3, .P5, .m7, .M9, .A11, .m13])
    XCTAssertEqual(ChordPattern(.M3, .P5, .m7, .M9, .A11, .m13).suffix, "9♯11(♭13)")
    XCTAssertEqual("9♯11(♭13)" as ChordPattern, .﹡9s11_f13_)


  }

  /// Tests `Chord` creation, raw value composition, chroma and pitch retrieval.
  func testChord() {

    let chord1 = Chord(root: .C, pattern: .﹡M)

    XCTAssertEqual(chord1.rawValue,
                   (UInt32(Chroma.C.rawValue) << 24) | ChordPattern.﹡M.rawValue)
    XCTAssertEqual(Chord(rawValue: (UInt32(Chroma.C.rawValue) << 24) | ChordPattern.﹡M.rawValue),
                   chord1)
    XCTAssertEqual(chord1.root, .C)
    XCTAssertEqual(chord1.pattern, .﹡M)
    XCTAssertEqual(chord1.chromas, [.C, .E, .G])

    XCTAssertEqual(chord1[.C], .P1)
    XCTAssertEqual(chord1[.E], .M3)
    XCTAssertEqual(chord1[.G], .P5)
    XCTAssertNil(chord1[.Db])
    XCTAssertNil(chord1[.D])
    XCTAssertNil(chord1[.F])
    XCTAssertNil(chord1[.Eb])
    XCTAssertNil(chord1[.Gb])
    XCTAssertNil(chord1[.Ab])
    XCTAssertNil(chord1[.A])
    XCTAssertNil(chord1[.Bb])
    XCTAssertNil(chord1[.B])

    XCTAssertEqual(chord1[.P1], .C)
    XCTAssertEqual(chord1[.M3], .E)
    XCTAssertEqual(chord1[.P5], .G)
    XCTAssertNil(chord1[.M2])
    XCTAssertNil(chord1[.m2])
    XCTAssertNil(chord1[.A2])
    XCTAssertNil(chord1[.m3])
    XCTAssertNil(chord1[.A3])
    XCTAssertNil(chord1[.P4])
    XCTAssertNil(chord1[.d4])
    XCTAssertNil(chord1[.A4])
    XCTAssertNil(chord1[.d5])
    XCTAssertNil(chord1[.A5])
    XCTAssertNil(chord1[.M6])
    XCTAssertNil(chord1[.m6])
    XCTAssertNil(chord1[.A6])
    XCTAssertNil(chord1[.M7])
    XCTAssertNil(chord1[.m7])
    XCTAssertNil(chord1[.A7])
    XCTAssertNil(chord1[.P8])
    XCTAssertNil(chord1[.d8])
    XCTAssertNil(chord1[.A8])
    XCTAssertNil(chord1[.M9])
    XCTAssertNil(chord1[.m9])
    XCTAssertNil(chord1[.A9])
    XCTAssertNil(chord1[.M10])
    XCTAssertNil(chord1[.m10])
    XCTAssertNil(chord1[.A10])
    XCTAssertNil(chord1[.P11])
    XCTAssertNil(chord1[.d11])
    XCTAssertNil(chord1[.A11])
    XCTAssertNil(chord1[.P12])
    XCTAssertNil(chord1[.d12])
    XCTAssertNil(chord1[.A12])
    XCTAssertNil(chord1[.M13])
    XCTAssertNil(chord1[.m13])
    XCTAssertNil(chord1[.A13])

    XCTAssertEqual(chord1.pitches(rootToneHeight: 3), ["C3", "E3", "G3"])
    XCTAssertEqual(chord1.pitches(rootToneHeight: 6), ["C6", "E6", "G6"])
    XCTAssertEqual(chord1.pitches(rootToneHeight: 4), ["C4", "E4", "G4"])

    let chord2 = Chord(root: .F, pattern: .﹡9s11_f13_)

    XCTAssertEqual(chord2.rawValue,
                   (UInt32(Chroma.F.rawValue) << 24) | ChordPattern.﹡9s11_f13_.rawValue)
    XCTAssertEqual(
      Chord(rawValue: (UInt32(Chroma.F.rawValue) << 24) | ChordPattern.﹡9s11_f13_.rawValue),
      chord2
    )
    XCTAssertEqual(chord2.root, .F)
    XCTAssertEqual(chord2.pattern, .﹡9s11_f13_)
    XCTAssertEqual(chord2.chromas, [.F, .A, .C, .Eb, .G, .B, .Db])

    XCTAssertEqual(chord2[.F], .P1)
    XCTAssertEqual(chord2[.A], .M3)
    XCTAssertEqual(chord2[.C], .P5)
    XCTAssertEqual(chord2[.Eb], .m7)
    XCTAssertEqual(chord2[.G], .M9)
    XCTAssertEqual(chord2[.B], .A11)
    XCTAssertEqual(chord2[.Db], .m13)
    XCTAssertNil(chord2[.Gb])
    XCTAssertNil(chord2[.Ab])
    XCTAssertNil(chord2[.Bb])
    XCTAssertNil(chord2[.D])
    XCTAssertNil(chord2[.E])

    XCTAssertEqual(chord2[.P1], .F)
    XCTAssertEqual(chord2[.M3], .A)
    XCTAssertEqual(chord2[.P5], .C)
    XCTAssertEqual(chord2[.m7], .Eb)
    XCTAssertEqual(chord2[.M9], .G)
    XCTAssertEqual(chord2[.A11], .B)
    XCTAssertEqual(chord2[.m13], .Db)
    XCTAssertNil(chord2[.M2])
    XCTAssertNil(chord2[.m2])
    XCTAssertNil(chord2[.A2])
    XCTAssertNil(chord2[.m3])
    XCTAssertNil(chord2[.A3])
    XCTAssertNil(chord2[.P4])
    XCTAssertNil(chord2[.d4])
    XCTAssertNil(chord2[.A4])
    XCTAssertNil(chord2[.d5])
    XCTAssertNil(chord2[.A5])
    XCTAssertNil(chord2[.M6])
    XCTAssertNil(chord2[.m6])
    XCTAssertNil(chord2[.A6])
    XCTAssertNil(chord2[.M7])
    XCTAssertNil(chord2[.A7])
    XCTAssertNil(chord2[.P8])
    XCTAssertNil(chord2[.d8])
    XCTAssertNil(chord2[.A8])
    XCTAssertNil(chord2[.m9])
    XCTAssertNil(chord2[.A9])
    XCTAssertNil(chord2[.M10])
    XCTAssertNil(chord2[.m10])
    XCTAssertNil(chord2[.A10])
    XCTAssertNil(chord2[.P11])
    XCTAssertNil(chord2[.d11])
    XCTAssertNil(chord2[.P12])
    XCTAssertNil(chord2[.d12])
    XCTAssertNil(chord2[.A12])
    XCTAssertNil(chord2[.M13])
    XCTAssertNil(chord2[.A13])

    XCTAssertEqual(chord2.pitches(rootToneHeight: 3), ["F3", "A3", "C4", "E♭4", "G4", "B4", "D♭5"])
    XCTAssertEqual(chord2.pitches(rootToneHeight: 6), ["F6", "A6", "C7", "E♭7", "G7", "B7", "D♭8"])
    XCTAssertEqual(chord2.pitches(rootToneHeight: 4), ["F4", "A4", "C5", "E♭5", "G5", "B5", "D♭6"])

  }

  /// A test that simple dumps a description of the chord library to a text attachment.
  func testDumpChordLibrary() {

    var text = ""

    for (rootChroma, chords) in ChordLibrary.chords {

      print("chords for root chroma '\(rootChroma)':", to: &text)

      for chord in chords {
        print("\(rootChroma.rawValue):\(chord.chromaRepresentation)", to: &text)
      }

      print("", to: &text)
    }

    add(XCTAttachment(data: text.data(using: .utf8)!,
                      uniformTypeIdentifier: "public.text",
                      lifetime: .keepAlways,
                      name: "Chord Library.txt"))

  }

}
