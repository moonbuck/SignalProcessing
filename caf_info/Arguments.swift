//
//  Arguments.swift
//  caf_info
//
//  Created by Jason Cardwell on 12/19/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import Docopt

let usage = """
Usage: caf_info -m [-sdcS] INPUT
       caf_info -s [-mdcS] INPUT
       caf_info -d [-mscS] INPUT
       caf_info -c [-msdS] INPUT
       caf_info -S [-msdc] INPUT
       caf_info -h

Arguments:
  INPUT  The audio file to parse. This must be a CAF file.

Options:
  -m, --markers            Print all markers found in INPUT to stdout.
  -s, --strings            Print all strings found in INPUT to stdout.
  -d, --audio-description  Print the audio description to stdout.
  -c, --channel-layout     Print the channel layout to stdout.
  -S, --structure          Print an overview of the file's structure to stdout.
  -h, --help               Show this help message and exit.
"""

struct Arguments: CustomStringConvertible {

  /// The URL for the input audio file.
  let inputURL: URL

  /// Whether to print all markers found in the file to stdout.
  let dumpMarkers: Bool

  /// Whether to print the audio description found in the file to stdout.
  let dumpAudioDescription: Bool

  /// Whether to print all strings found in the file to stdout.
  let dumpStrings: Bool

  /// Whether to print the file's channel layout information to stdout.
  let dumpChannelLayout: Bool

  /// Whether to print the general structure of the file to stdout.
  let dumpStructure: Bool

  /// Initialize by parsing the command line arguments.
  init() {

    // Parse the command line arguments.
    let arguments = Docopt.parse(usage, help: true)

    inputURL = URL(fileURLWithPath: arguments["INPUT"] as! String)
    dumpMarkers = (arguments["--markers"] as! NSNumber).boolValue
    dumpStrings = (arguments["--strings"] as! NSNumber).boolValue
    dumpAudioDescription = (arguments["--audio-description"] as! NSNumber).boolValue
    dumpChannelLayout = (arguments["--channel-layout"] as! NSNumber).boolValue
    dumpStructure = (arguments["--structure"] as! NSNumber).boolValue

  }

  var description: String {

    return """
      inputURL: \(inputURL.path)
      dumpMarkers: \(dumpMarkers)
      dumpStrings: \(dumpStrings)
      dumpAudioDescription: \(dumpAudioDescription)
      dumpChannelLayout: \(dumpChannelLayout)
      dumpStructure: \(dumpStructure)
      """

  }

}



