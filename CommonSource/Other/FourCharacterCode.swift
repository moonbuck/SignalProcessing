//
//  FourCharacterCode.swift
//  SignalProcessing
//
//  Created by Jason Cardwell on 12/19/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation

/// A struct for wrapping a `UInt32` value being used as a four character code.
public struct FourCharacterCode {

  /// The value as an unsigned integer.
  public let value: FourCharCode

  /// The value as as string.
  public var stringValue: String {
    var value = self.value
    return withUnsafeBytes(of: &value) {
      String(String.UnicodeScalarView($0.map(UnicodeScalar.init).reversed()))
    }
  }

  /// Initializing with a number.
  public init(value: FourCharCode) { self.value = value }

  /// Initializing with a string.
  public init(stringValue: String) {

    let scalars = stringValue.unicodeScalars

    var bytes: [UInt32] = []

    for scalar in scalars {
      bytes.append(scalar.value)
      guard bytes.count < 4 else { break }
    }

    while bytes.count < 4 { bytes.append(0) }

    bytes.reverse()

    value = bytes[0] | (bytes[1] << 4) | (bytes[2] << 8) | (bytes[3] << 12)

  }

}

