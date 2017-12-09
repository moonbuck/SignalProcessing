//
//  Command.swift
//  extract
//
//  Created by Jason Cardwell on 12/9/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation

/// An enumeration of valid argument values for the '<command>' command line argument.
enum Command: String {

  /// Divides the input signal into its frequency components.
  case spectrum

  /// Initializing with an optional raw value.
  ///
  /// - Parameter rawValue: The string value of an enumeration case.
  init?(_ rawValue: String?) {
    guard let rawValue = rawValue else { return nil }
    self.init(rawValue: rawValue)
  }

}
