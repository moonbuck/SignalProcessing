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
Usage: caf_info INPUT
       caf_info --help

Arguments:
  INPUT  The audio file to parse.

Options:
  --help  Show this help message and exit.
"""

struct Arguments: CustomStringConvertible {

  /// The URL for the input audio file.
  let inputURL: URL

  /// Initialize by parsing the command line arguments.
  init() {

    // Parse the command line arguments.
    let arguments = Docopt.parse(usage, help: true)

    inputURL = URL(fileURLWithPath: arguments["INPUT"] as! String)

  }

  var description: String {

    return """
      inputURL: \(inputURL.path)
      """

  }

}



