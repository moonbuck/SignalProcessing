//
//  Arguments.swift
//  generate_chords
//
//  Created by Jason Cardwell on 12/14/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import Docopt

let usage = """
Usage: generate_chords [--octaves=<LIST>] [--variations=<COUNT>] --dir=<DIR> --base=<NAME>
       generate_chords --help

Options:
  --octaves=<LIST>          The octave for root intervals of the chords. For each octave in
                            LIST a MIDI file will be generated. [default: 0,1,2,3,4,5,6,7,8]
  --variations=<COUNT:int>  The number of times a file should be generated per octave. The
                            velocity values for note events are randomized. [default: 1]
  --dir=<DIR:string>        The output directory for generated files.
  --base=<NAME:string>      The base name for generated files.
  --help                    Show this help message and exit.
"""

struct Arguments {

  /// The octaves for which a MIDI file of chords should be generated.
  let octaves: [Int]

  /// The output directory for all generated files.
  let outputDirectory: URL

  /// The base name to use for generated file names.
  let baseName: String

  /// The number of MIDI files to generate per octave.
  let variations: Int

  /// Initialize by parsing the command line arguments.
  init() {

    // Parse the command line arguments.
    let arguments = Docopt.parse(usage, help: true)

    octaves = (arguments["--octaves"] as! String).split(separator: ",").flatMap {
      Int(($0 as NSString).trimmingCharacters(in: .whitespaces))
    }

    guard !octaves.isEmpty else {
      print(usage)
      exit(EXIT_FAILURE)
    }

    variations = (arguments["--variations"] as! NSNumber).intValue

    outputDirectory = URL(fileURLWithPath: arguments["--dir"] as! String)

    baseName = arguments["--base"] as! String

  }

}

extension Arguments: CustomStringConvertible {

  var description: String {

    return """
    octaves: \(octaves.map(\.description).joined(separator: ","))
    variations: \(variations)
    outputDirectory: '\(outputDirectory.path)'
    baseName: '\(baseName)'
    """

  }

}

