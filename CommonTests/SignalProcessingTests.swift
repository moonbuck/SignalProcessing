//
//  SignalProcessingTests.swift
//  SignalProcessingTests
//
//  Created by Jason Cardwell on 12/8/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import XCTest
@testable import SignalProcessing


class SignalProcessingTests: XCTestCase {

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

  /// A test that extracts pitch features and attaches spectrogram images.
  func testPitchFeatures() {

    let bundle = Bundle(for: SignalProcessingTests.self)
    guard let url = bundle.url(forResource: "16-Bar-Progression_Boesendorfer_Grand_Piano",
                               withExtension: "aif")
    else
    {
      XCTFail("Failed to retrieve url for audio file.")
      return
    }

    let parameters = PitchFeatures.Parameters(
      method: .stft(windowSize: 8820, hopSize: 4410, sampleRate: .Fs44100),
      filters: [
        //.compression(settings: CompressionSettings(term: 1, factor: 1)),
        .normalization(settings: .lᵖNorm(space: .l¹, threshold: 0.001))
      ]
    )

    guard let pitchFeatures = try? PitchFeatures(from: url, parameters: parameters) else {
      XCTFail("Failed to extract pitch features from '\(url)'")
      return
    }

    add(XCTAttachment(image: pitchPlot(features: pitchFeatures),
                      lifetime: .keepAlways,
                      name: "Pitch_Features_w=8820_h=4410_sr=44100_l1=0_001_map=heat.png"))

    add(XCTAttachment(image: pitchPlot(features: pitchFeatures, mapKind: .grayscale),
                      lifetime: .keepAlways,
                      name: "Pitch_Features_w=8820_h=4410_sr=44100_l1=0_001_map=grayscale.png"))

  }

}
