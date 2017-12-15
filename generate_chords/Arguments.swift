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
Usage: generate_chords [--octaves=<octave-list>] <output>
       generate_chords --help

Arguments:
  <input>   The file path for the input audio file.
  <output>  The file path to which output should be written.

Options:
  --octaves=<octave-list>  The octave for root intervals of the chords. [default: 0,1,2,3,4,5,6,7,8]
  -h, --help              Show this help message and exit.
"""

struct Arguments {

  /// The octaves for which a MIDI file of chords should be generated.
  let octaves: [Int]

  /// The destination for the generated MIDI file minus tone height information and extension.
  let midiFileDestination: URL

  /// The destination for the list of chords present in the generated MIDI file.
  var listFileDestination: URL {
    return midiFileDestination.deletingPathExtension().appendingPathExtension("txt")
  }

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

    var fileOut = arguments["<output>"] as! String
    if fileOut.hasSuffix(".mid") { fileOut.removeLast(4) }
    
    midiFileDestination = URL(fileURLWithPath: fileOut)

  }

}

extension Arguments: CustomStringConvertible {

  var description: String {

    return """
    octaves: \(octaves.map(\.description).joined(separator: ","))
    destination: \(midiFileDestination)
    """

  }

}

