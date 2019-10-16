//
//  SignalProcessingTests.swift
//  SignalProcessingTests
//
//  Created by Jason Cardwell on 12/8/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import XCTest
@testable import SignalProcessing
//import Essentia
import AVFoundation
import Accelerate

class SignalProcessingTests: XCTestCase {

//  func testFFT() {
//
//    let bundle = Bundle(for: SignalProcessingTests.self)
//    guard let url = bundle.url(forResource: "Cmaj_boesendorfer_th=3",
//                               withExtension: "aif")
//      else
//    {
//      XCTFail("Failed to retrieve url for audio file.")
//      return
//    }
//
//    var buffer = (try! AVAudioPCMBuffer(contentsOf: url)).mono64
//
//    let signal = SignalVector(storage: buffer.float64ChannelData!.pointee,
//                              count: Int(buffer.frameLength))
//
//    
//
//  }

  /// A test that extracts pitch features, attaching frame data and spectrogram images.
  func testPitchFeatures() {

    let bundle = Bundle(for: SignalProcessingTests.self)
    guard let url = bundle.url(forResource: "16-Bar-Progression_Boesendorfer_Grand_Piano",
                               withExtension: "aif")
    else
    {
      XCTFail("Failed to retrieve url for audio file.")
      return
    }

    let parameters1 = PitchFeatures.Parameters(
      method: .stft(windowSize: 8820, hopSize: 4410, sampleRate: .Fs44100, representation: .magnitude),
      filters: [
        .normalization(settings: .lᵖNorm(space: .l¹, threshold: 0))
      ]
    )

    guard let pitchFeatures1 = try? PitchFeatures(from: url, parameters: parameters1) else {
      XCTFail("Failed to extract pitch features from '\(url)'")
      return
    }

    add(XCTAttachment(image: pitchPlot(features: pitchFeatures1, mapKind: .grayscale),
                      lifetime: .keepAlways,
                      name: "Pitch_Features_w=8820_h=4410_sr=44100_l1=0_001_e=m_.png"))

    let parameters2 = PitchFeatures.Parameters(
      method: .stft(windowSize: 8192, hopSize: 4096, sampleRate: .Fs44100, representation: .magnitude),
      filters: [
        .normalization(settings: .lᵖNorm(space: .l¹, threshold: 0))
      ]
    )

    guard let pitchFeatures2 = try? PitchFeatures(from: url, parameters: parameters2) else {
      XCTFail("Failed to extract pitch features from '\(url)'")
      return
    }

    add(XCTAttachment(image: pitchPlot(features: pitchFeatures2, mapKind: .grayscale),
                      lifetime: .keepAlways,
                      name: "Pitch_Features_w=8192_h=4096_sr=44100_l1=0_001_e=m_.png"))

    let parameters3 = PitchFeatures.Parameters(
      method: .stft(windowSize: 8820, hopSize: 4410, sampleRate: .Fs44100, representation: .magnitudeSquared),
      filters: [
        .normalization(settings: .lᵖNorm(space: .l¹, threshold: 0))
      ]
    )

    guard let pitchFeatures3 = try? PitchFeatures(from: url, parameters: parameters3) else {
      XCTFail("Failed to extract pitch features from '\(url)'")
      return
    }

    add(XCTAttachment(image: pitchPlot(features: pitchFeatures3, mapKind: .grayscale),
                      lifetime: .keepAlways,
                      name: "Pitch_Features_w=8820_h=4410_sr=44100_l1=0_001_e=m2_.png"))

    let parameters4 = PitchFeatures.Parameters(
      method: .stft(windowSize: 8192, hopSize: 4096, sampleRate: .Fs44100, representation: .magnitudeSquared),
      filters: [
        .normalization(settings: .lᵖNorm(space: .l¹, threshold: 0))
      ]
    )

    guard let pitchFeatures4 = try? PitchFeatures(from: url, parameters: parameters4) else {
      XCTFail("Failed to extract pitch features from '\(url)'")
      return
    }

    add(XCTAttachment(image: pitchPlot(features: pitchFeatures4, mapKind: .grayscale),
                      lifetime: .keepAlways,
                      name: "Pitch_Features_w=8192_h=4096_sr=44100_l1=0_001_e=m2_.png"))


  }

}
