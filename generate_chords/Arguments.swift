//
//  Arguments.swift
//  generate_chords
//
//  Created by Jason Cardwell on 12/14/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import SignalProcessing
import Docopt

let usage = """
Usage: generate_chords [options] --dir=<DIR> --base=<NAME>
       generate_chords --help

Arguments:
  --dir=<DIR:string>        The output directory for generated files.
  --base=<NAME:string>      The base name for generated files.

Options:
  --octaves=<LIST>          The octave for root intervals of the chords. For each octave in
                            LIST a MIDI file will be generated. [default: 0,1,2,3,4,5,6,7,8]
  --join-octaves            Specifies that events generated for the octaves should be added
                            to the same track in the same MIDI file.
  --variations=<COUNT:int>  The number of times a file should be generated per octave. The
                            velocity values for note events are randomized. [default: 1]
  --join-variations         Specifies that velocity variations for a chord should appear
                            consecutively on the same track in the same MIDI file.
  --create-directory        Whether to create DIR if it does not exist.
  --number-markers          Whether to prefix marker names with their one-based index.
  --event-list              Also generate a list of all MIDI events for each file.
  --help                    Show this help message and exit.
"""

struct Arguments: CustomStringConvertible {

  /// The octaves for which a MIDI file of chords should be generated.
  let octaves: [Int]

  /// The output directory for all generated files.
  let outputDirectory: URL

  /// Whether to create `outputDirectory` if it does not exist.
  let createDirectory: Bool

  /// Whether to prefix marker names with their one-based index.
  let numberMarkers: Bool

  /// Whether events generated for the list of octaves should all go in the same file.
  let joinOctaves: Bool

  /// Whether events generated for `variation` should be inserted consecutively into the same file.
  let joinVariations: Bool

  /// The base name to use for generated file names.
  let baseName: String

  /// The number of MIDI files to generate per octave.
  let variations: Int

  /// Whether to create a list of all MIDI events for each file.
  let eventList: Bool

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

    createDirectory = arguments["--create-directory"] as! Bool

    numberMarkers = arguments["--number-markers"] as! Bool

    joinOctaves = arguments["--join-octaves"] as! Bool

    joinVariations = arguments["--join-variations"] as! Bool

    eventList = arguments["--event-list"] as! Bool

    baseName = arguments["--base"] as! String

    // Check `outputDirectory`.
    var isDirectory: ObjCBool = false
    let exists = FileManager.`default`.fileExists(atPath: outputDirectory.path,
                                                  isDirectory: &isDirectory)


    switch (exists, isDirectory.boolValue) {
      case (true, true):
        break
      case (true, false):
        print("'\(outputDirectory.path)' is not a directory.")
        exit(EXIT_FAILURE)
      case (false, _) where !createDirectory:
        print("""
              Specified directory does not exist. Pass --create-directory to have
              '\(outputDirectory.path)' created automatically.
              """)
        exit(EXIT_FAILURE)
      default:
        do {
          try FileManager.`default`.createDirectory(at: outputDirectory,
                                                    withIntermediateDirectories: true)
        } catch {
          print("""
            Error encountered creating directory '\(outputDirectory.path)': \
            \(error.localizedDescription)
            """)
        }

    }

  }

  var description: String {

    return """
      octaves: \(octaves.map(\.description).joined(separator: ","))
      joinOctaves: \(joinOctaves)
      joinVariations: \(joinVariations)
      variations: \(variations)
      outputDirectory: '\(outputDirectory.path)'
      createDirectory: \(createDirectory)
      baseName: '\(baseName)'
      numberMarkers: \(numberMarkers)
      eventList: \(eventList)
      """

  }

}

