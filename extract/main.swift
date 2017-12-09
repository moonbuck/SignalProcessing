//
//  main.swift
//  extract
//
//  Created by Jason Cardwell on 12/9/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import Essentia
import SignalProcessing
import Docopt

let usage = """
Usage: extract <command> [options] <input> [<output>]
       extract --help

Arguments:
  <command>  Specifies the kind of extraction to perform. Valid commands are as follows:
             spectrum  Divides the input signal into its frequency components.

Options:
  -e, --essentia  Use the Essentia framework.
  --win=<ws:int>      The size of the window to use.
  --hop=<hs:int>      The hop size to use.
  -p, --pitch     Requantize bins to correspond with MIDI pitches.
  -h, --help      Show this help message and exit.
"""

/// Prints the specified message to `stdout` followed by `usage` before terminating with
/// an exit status of `EXIT_FAILURE`.
///
/// - Parameter message: The text to preceed `usage`.
func usageError(message: String) -> Never {
  print("\(message)\n\n\(usage)")
  exit(EXIT_FAILURE)
}

// Parse the command line arguments.
let arguments = Docopt.parse(usage, help: true)

print("Parsed command line arguments:")
for (key, value) in arguments {
  print("\"\(key)\": \(value)")
}

let convertToPitch = arguments["--pitch"] as? Bool == true
let useEssentia = arguments["--essentia"] as? Bool == true
let windowSize = (arguments["--win"] as? NSNumber)?.intValue ?? 1024
let hopSize = (arguments["--hop"] as? NSNumber)?.intValue ?? 512

let input = arguments["<input>"] as! String
let output = arguments["<output>"] as? String

print("""
  convertToPitch: \(convertToPitch)
  useEssentia:    \(useEssentia)
  windowSize:     \(windowSize)
  hopSize:        \(hopSize)
  input:          \(input)
  output:         \(output ?? "stdout")
  """)

guard let command = Command(arguments["<command>"] as? String) else {
  guard let specified = arguments["<command>"] as? String else {
    usageError(message: "<command> is a required argument.")
  }
  usageError(message: "\(specified) is not a valid value for <command>.")
}

