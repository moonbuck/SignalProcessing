//
//  Command.swift
//  extract
//
//  Created by Jason Cardwell on 12/9/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import class AppKit.NSImage
import class AVFoundation.AVAudioPCMBuffer
import struct Accelerate.DSPComplex
import struct Accelerate.DSPDoubleComplex
import class Essentia.Pool
import struct SignalProcessing.PitchVector
import struct SignalProcessing.BinVector

/// An enumeration of valid argument values for the '<command>' command line argument.
enum Command: String {

  /// Divides the input signal into its frequency components.
  case spectrum

  static var availableCommands: Set<Command> { return [.spectrum] }

  /// Initializing with an optional raw value.
  ///
  /// - Parameter rawValue: The string value of an enumeration case.
  init?(_ rawValue: String?) {
    guard let rawValue = rawValue else { return nil }
    self.init(rawValue: rawValue)
  }

  /// Executes the command with the specified audio input.
  ///
  /// - Parameter input: The buffer of audio input on which to perform feature extraction.
  /// - Returns: The result of the command as a string value.
  func execute(input: AVAudioPCMBuffer) -> Output {

    switch self {
      case .spectrum: return executeSpectrumCommand(using: input)
    }

  }

  enum Output {

    case integer (Int)
    case real (Float)
    case real64 (Float64)
    case complexReal (DSPComplex)
    case complexReal64 (DSPDoubleComplex)
    case string (String)
    case pool (Pool)
    case image (NSImage)

    case realVec ([Float])
    case real64Vec ([Float64])
    case complexRealVec ([DSPComplex])
    case complexReal64Vec ([DSPDoubleComplex])
    case stringVec ([String])
    case pitchVector (PitchVector)
    case binVector (BinVector)

    case realVecVec ([[Float]])
    case real64VecVec ([[Float64]])
    case complexRealVecVec ([[DSPComplex]])
    case complexReal64VecVec ([[DSPDoubleComplex]])
    case stringVecVec ([[String]])
    case pitchVectorVec ([PitchVector])
    case binVectorVec ([BinVector])

  }

}
