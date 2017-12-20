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

let usage = """
Usage: split_audio --segment-markers [options] INPUT
       split_audio --segment-samples=<SAMPLES> [options] INPUT
       split_audio --segment-seconds=<SECONDS> [options] INPUT
       split_audio --segment-total=<TOTAL> [options] INPUT
       split_audio --help

Arguments:
  INPUT  The audio file to split.

Options:
  --segment-markers                  Use markers in INPUT to segment the file.
  --segment-samples=<SAMPLES:int>    The number of samples per segment.
  --segment-seconds=<SECONDS:float>  The number of seconds per segment.
  --zero-pad                         Whether to add zeros to the last segment if SIZE is not a factor
                                     of the total sample count.
  --segment-total=<TOTAL:int>        The total number of segments to create.
  --dir=<DIR:string>                 The output directory for generated files.
  --create-directory                 Whether to create DIR if it does not exist.
  --file-names=<NAMES>               The list of base file names for the segments created.
  --file-index=<INDEX:string>        The path to a file with newline delimited file names for the
                                     segments created.
  --number-prefix                    Whether to prefix output files with the segment index.
  --help                             Show this help message and exit.
"""

struct Arguments: CustomStringConvertible {

  /// The URL for the input audio file.
  let inputURL: URL

  /// The file ID for the input audio file.
  let inputFile: AudioFileID

  /// The output directory for all generated files.
  let outputDirectory: URL

  /// Whether to create `outputDirectory` if it does not exist.
  let createDirectory: Bool

  /// Whether to prefix marker names with their one-based index.
  let numberPrefix: Bool

  /// Whether to use markers to segment the file.
  let splitByMarker: Bool

  /// The number of samples per segment.
  let samplesPerSegment: Int?

  /// The number of seconds per segment.
  let secondsPerSegment: Float?

  /// Whether to add zeros to the last segment if SIZE is not a factor of the total sample count.
  let zeroPad: Bool

  /// The total number of segments to create.
  let totalSegments: Int?

  /// The list of base file names for the segments created.
  let fileNames: [String]?

  /// The path to a file with newline delimited file names for the segments created.
  let fileIndex: String?

  /// Initialize by parsing the command line arguments.
  init() {

    // Parse the command line arguments.
    let arguments = Docopt.parse(usage, help: true)

    let inputURL = URL(fileURLWithPath: arguments["INPUT"] as! String)
    self.inputURL = inputURL

    inputFile = openAudioFile(url: inputURL)

    outputDirectory = URL(fileURLWithPath: (arguments["--dir"] as? String) ?? "./")

    createDirectory = arguments["--create-directory"] as! Bool

    numberPrefix = arguments["--number-prefix"] as! Bool

    splitByMarker = arguments["--segment-markers"] as! Bool

    samplesPerSegment = (arguments["--segment-samples"] as? NSNumber)?.intValue

    secondsPerSegment = (arguments["--segment-seconds"] as? NSNumber)?.floatValue

    zeroPad = arguments["--zero-pad"] as! Bool

    totalSegments = (arguments["--segment-total"] as? NSNumber)?.intValue

    fileNames = arguments["--file-names"] as? [String]

    fileIndex = arguments["--file-index"] as? String

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
      inputURL: \(inputURL.path)
      outputDirectory: '\(outputDirectory.path)'
      createDirectory: \(createDirectory)
      numberPrefix: \(numberPrefix)
      splitByMarker: \(splitByMarker)
      samplesPerSegment: \(samplesPerSegment?.description ?? "nil")
      secondsPerSegment: \(secondsPerSegment?.description ?? "nil")
      zeroPad: \(zeroPad)
      totalSegments: \(totalSegments?.description ?? "nil")
      fileNames: \(fileNames?.description ?? "nil")
      fileIndex: \(fileIndex ?? "nil")
      """

  }

}


