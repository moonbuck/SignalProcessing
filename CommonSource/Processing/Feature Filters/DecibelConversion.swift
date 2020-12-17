//
//  DecibelConversion.swift
//  SignalProcessing
//
//  Created by Jason Cardwell on 12/16/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import Accelerate


/// A simple structure encapsulating settings for decibel conversion.
public struct DecibelConversionSettings {

  /// The multipier to use during conversion.
  public var multiplier: Multiplier

  /// The value to serve as the 0dB reference during conversion.
  public var zeroReference: Float64

  /// Initializing with default property values.
  public init(multiplier: Multiplier = .power, zeroReference: Float64 = 0) {

    self.multiplier = multiplier
    self.zeroReference = zeroReference

  }

  public static var `default`: DecibelConversionSettings { DecibelConversionSettings() }

  /// An enumeration for specifying the multiplier used for conversion to decibels.
  ///
  /// - power: Uses a multiplier value of `10`.
  /// - amplitude: Uses a multiplier value of `20`.
  public enum Multiplier: UInt32 {
    case power = 10
    case amplitude = 20
  }

}

/// Converts values in the specified vector to their decibel equivalents.
///
/// - Parameters:
///   - vector: The vector of values to convert.
///   - settings: The conversion settings.
public func decibelConversion(vector: Float64Vector,
                              settings: DecibelConversionSettings)
{

  // Get a mutable copy of the zero reference value.
  var zeroReference = settings.zeroReference

  let count = vDSP_Length(vector.count)

  vDSP_vdbconD(vector.storage, 1,
               &zeroReference,
               vector.storage, 1,
               count,
               settings.multiplier.rawValue)

}

/// Converts values in the specified buffer to their decibel equivalents.
///
/// - Parameters:
///   - buffer: The buffer of values to convert.
///   - settings: The conversion settings.
public func decibelConversion<Buffer>(buffer: Buffer, settings: DecibelConversionSettings)
  where Buffer: Float64VectorBufferWrapper
{
  for index in 0 ..< buffer.count {
    decibelConversion(vector: buffer.buffer[index], settings: settings)
  }
}

/// Converts values in the specified buffer to their decibel equivalents.
///
/// - Parameters:
///   - buffer: The buffer of values to convert.
///   - settings: The conversion settings.
public func decibelConversion<Vector>(buffer: [Vector], settings: DecibelConversionSettings)
  where Vector:Float64Vector
{
  for index in buffer.indices {
    decibelConversion(vector: buffer[index], settings: settings)
  }
}
