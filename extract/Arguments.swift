//
//  Arguments.swift
//  extract
//
//  Created by Jason Cardwell on 12/9/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import Docopt

let usage = """
Usage: extract spectrum [--win=<ws>] [--hop=<hs>] [-pe] (--csv | --plot) <input> [<output>]
       extract --help

Arguments:
  <input>   The file path for the input audio file.
  <output>  The file path to which output should be written. If not provided, output will be
            written to stdout.

Options:
  -e, --essentia  Use the Essentia framework.
  --win=<ws:int>  The size of the window to use. [default: 1024]
  --hop=<hs:int>  The hop size to use. [default: 512]
  --csv           Output result as csv data.
  --plot          Output result as an image of the plotted data.
  -p, --pitch     Requantize bins to correspond with MIDI pitches.
  -h, --help      Show this help message and exit.
"""

struct Arguments {

  /// Whether to requanitize bins to correspond with MIDI pitches.
  let convertToPitch: Bool

  /// Whether to use the algorithms in the Essentia framework.
  let useEssentia: Bool

  /// The window size to use during extraction.
  let windowSize: Int

  /// The hop size to use during extraction.
  let hopSize: Int

  /// The file path for the input audio file.
  let input: String

  /// The file path for writing the extracted features or `nil` to use stdout.
  let output: String?

  /// The desired output format.
  let outputFormat: OutputFormat

  /// The command to be executed.
  let command: Command

  /// Initialize by parsing the command line arguments.
  init() {

    // Parse the command line arguments.
    let arguments = Docopt.parse(usage, help: true)

    convertToPitch = arguments["--pitch"] as! Bool
    useEssentia = arguments["--essentia"] as! Bool
    windowSize = (arguments["--win"] as! NSNumber).intValue
    hopSize = (arguments["--hop"] as! NSNumber).intValue
    input = arguments["<input>"] as! String
    output = arguments["<output>"] as? String
    command = Command.availableCommands.first(where: {arguments[$0.rawValue] as! Bool})!
    outputFormat = arguments["--csv"] as! Bool ? .csv : .plot

  }

  enum OutputFormat {
    case csv, plot
  }

}
