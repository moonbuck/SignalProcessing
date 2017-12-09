//
//  SampleRate.swift
//  SignalProcessing
//
//  Created by Jason Cardwell on 9/30/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import AVFoundation

/// Represents the three different sample rates utilized by `MultirateAudioPCMBuffer`.
public enum SampleRate: Int, CustomStringConvertible, ExpressibleByIntegerLiteral {

  case Fs44100 = 44100  /// A sample rate of 44100 Hz
  case Fs22050 = 22050  /// A sample rate of 22050 Hz
  case Fs4410 = 4410    /// A sample rate of 4410 Hz
  case Fs882 = 882      /// A sample rate of 882 Hz
  case Fs441 = 441      /// A sample rate of 441 Hz

  /// Initialize with the nearest supported sample rate.
  ///
  /// - Parameter rawValue: The desired sample rate in Hz.
  public init(rawValue: Int) {
    switch rawValue {
      case 44100:           self = .Fs44100
      case 22050:           self = .Fs22050
      case 4410:            self = .Fs4410
      case 882:             self = .Fs882
      case 441:             self = .Fs441
      case 33075..<Int.max: self = .Fs44100
      case 13230..<33075:   self = .Fs22050
      case 2646..<13230:    self = .Fs4410
      case 662..<2646:      self = .Fs882
      default:              self = .Fs441
    }
  }

  /// Initializing with the case corresponding to the sample rate of an audio buffer. If the
  /// specified buffer uses a sample rate that does not correspond to a raw value for one of the
  /// cases, `nil` is returned.
  ///
  /// - Parameter buffer: The buffer whose sample rate shall be used.
  public init?(buffer: AVAudioPCMBuffer) {

    switch buffer.format.sampleRate {
      case 44100: self = .Fs44100
      case 22050: self = .Fs22050
      case 4410:  self = .Fs4410
      case 882:   self = .Fs882
      case 441:   self = .Fs441
      default:    return nil
    }

  }

  public var description: String { return "\(rawValue) Hz" }

  public init(integerLiteral value: Int) { self.init(rawValue: value) }

  /// The range of pitch values for which the sample rate is ideal.
  public var pitchRange: CountableClosedRange<Pitch> {
    switch self {
      case .Fs44100: return 121...127
      case .Fs22050: return 95...120
      case .Fs4410:  return 59...94
      case .Fs882:   return 20...58
      case .Fs441:   return 0...19
    }
  }

}

