//
//  Arguments.swift
//  split_audio
//
//  Created by Jason Cardwell on 12/18/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import AudioToolbox
import SignalProcessing
import Docopt
import MoonKit

let usage = """
Usage: split_audio [options] [(--suffix=<SUFFIX> | --regex-suffix=<REGEX>)] FILE...
       split_audio --help

Arguments:
  FILE  The audio file(s) to split.

Options:
  --dir=<DIR:string>             The output directory for generated files.
  --create-directory             Whether to create DIR if it does not exist.
  --create-subdirectories        Whether to place segments in a subdirectory of DIR with a name
                                 generated from the file name of the segments' source.
  --suffix=<SUFFIX:string>       A suffix to append to file names before the extension.
  --regex-suffix=>REGEX:string>  A regular expression with a single capture group that when
                                 matched to an input file's name extracts the desired suffix.
  --verbose                      Whether to print informative messages to stdout while processing.
  --help                         Show this help message and exit.
"""

struct Arguments: CustomStringConvertible {

  /// The URLs for the audio files to split.
  let fileURLs: [URL]

  /// The output directory for all generated files.
  let outputDirectory: URL

  /// Whether to create `outputDirectory` if it does not exist.
  let createDirectory: Bool

  /// Whether to place segments in per-file subdirectory under `outputDirectory`.
  let createSubdirectories: Bool

  /// Whether to print informative messages to stdout while processing.
  let verbose: Bool

  /// A suffix to append to file names before the extension.
  let fileNameSuffix: String?

  /// A regular expression to match against the input file names to generate segment suffixes.
  let fileNameSuffixRegEx: RegularExpression?

  /// Initialize by parsing the command line arguments.
  init() {

    // Parse the command line arguments.
    let arguments = Docopt.parse(usage, help: true)

    // Get the glob-expanded list of file paths.
    let fileList = expandGlobPatterns(in: arguments["FILE"] as! [String])

    // Initialize the list of file URLs.
    fileURLs = fileList.map(URL.init(fileURLWithPath:))

    // Set the output directory, using './' if the directory was not specified.
    outputDirectory = URL(fileURLWithPath: (arguments["--dir"] as? String) ?? "./")

    createDirectory = (arguments["--create-directory"] as! NSNumber).boolValue

    verbose = (arguments["--verbose"] as! NSNumber).boolValue

    createSubdirectories = (arguments["--create-subdirectories"] as! NSNumber).boolValue

    fileNameSuffix = arguments["--suffix"] as? String

    if let pattern = arguments["--regex-suffix"] as? String {

      guard let regex = try? RegularExpression(pattern: pattern) else {
        print("Invalid pattern for file name suffix regular expression: '\(pattern)'.")
        exit(EXIT_FAILURE)
      }

      fileNameSuffixRegEx = regex

    } else {
      fileNameSuffixRegEx = nil
    }

    // Make sure the output directory exists or can be created.
    do {
      guard try checkDirectory(url: outputDirectory, createDirectories: createDirectory) else {
        print("""
          Specified directory does not exist. Pass --create-directory to have \
          '\(outputDirectory.path)' created automatically.
          """)
        exit(EXIT_FAILURE)
      }
    } catch {
      print("Error encountered checking directory: \(error.localizedDescription)")
      exit(EXIT_FAILURE)
    }

  }

  var description: String {

    return """
      fileURLs: \(fileURLs.map(\.path))
      outputDirectory: '\(outputDirectory.path)'
      createDirectory: \(createDirectory)
      createSubdirectories: \(createSubdirectories)
      fileNameSuffix: \(fileNameSuffix ?? "nil")
      fileNameSuffixPattern: \(fileNameSuffixRegEx?.pattern ?? "nil")
      verbose: \(verbose)
      """

  }

}


