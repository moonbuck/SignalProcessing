//
//  Arguments.swift
//  extract
//
//  Created by Jason Cardwell on 12/9/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import Docopt
import MoonKit

let usage = """
Usage: extract [options] FILE...
       extract --help

Arguments:
  FILE The audio file(s) from which to extract features.

Options:
  --output-dir=<DIR:string>          The file path for the directory to which generated files
                                     will be written. [default: ./]
  --csv-dir=<CSV_DIR:string>         The file path for the directory to which the generated CSV
                                     file will be written. When used in combination with DIR,
                                     CSV_DIR will be treated as a subdirectory path within DIR.
  --png-dir=<PNG_DIR:string>         The file path for the directory to which the generated PNG
                                     file will be written. When used in combination with DIR,
                                     PNG_DIR will be treated as a subdirectory path within DIR.
  --create-directories               Create specified directories if they do not exist.
  --output-name=<NAME:string>        The base file name for generated files. If not specified,
                                     The base name of the input file will be used.
  --essentia                         Use algorithms from the Essentia framework.
  --quantization=<KIND:string>       How the bins should be quantized. KIND can be 'bin',
                                     'pitch', or 'chroma'. [default: pitch]
  --window-size=<WINDOW_SIZE:int>    The size of the window to use. [default: 8820]
  --hop-size=<HOP_SIZE:int>          The hop size to use. [default: 4410]
  --dB                               Convert energies to decibels.
  --compress=<FACTOR:float>          Perform log compression on the feature values using FACTOR.
                                     [default: 0]
  --csv                              Output result as csv data.
  --group-by=<GROUP:string>          Group csv data by row or column. [default: row]
  --plot                             Output result as an image of the plotted data.
  --data                             Image output will consist of only the features with each
                                     value mapped to a single pixel.
  --title=<TITLE:string>             The title to display at the top of the plot.
  --verbose                          Whether to print informative messages to stdout while
                                     processing.
  --help                             Show this help message and exit.
"""


struct Arguments {

  /// The URLs of all the input audio files.
  let fileURLs: [URL]

  /// The root directory for output files.
  let outputDirectory: URL

  /// The directory to which the CSV file should be written.
  let csvDirectory: URL

  /// The directory to which the PNG file should be written.
  let pngDirectory: URL

  /// Whether non-existent directories should be created.
  let createDirectories: Bool

  /// Options relating to feature extraction.
  let extractionOptions: ExtractionOptions

  /// Options relating to the generated PNG file.
  let pngOptions: PNGOptions

  /// Options relating to the generated CSV file.
  let csvOptions: CSVOptions

  /// Whether to print informative messages to stdout while processing.
  let verbose: Bool

  /// Initialize by parsing the command line arguments.
  init() {

    // Parse the command line arguments.
    let arguments = Docopt.parse(usage, help: true)

    verbose = (arguments["--verbose"] as! NSNumber).boolValue

    // Make sure the quantization value is valid.
    guard let quantization =
                ExtractionOptions.Quantization(rawValue: arguments["--quantization"] as! String)
    else
    {
      print(usage)
      exit(EXIT_FAILURE)
    }

    // Initialize the extraction options.
    extractionOptions = ExtractionOptions(
      useEssentia: arguments["--essentia"] as! Bool,
      windowSize: (arguments["--window-size"] as! NSNumber).intValue,
      hopSize: (arguments["--hop-size"] as! NSNumber).intValue,
      compressionFactor: (arguments["--compress"] as? NSNumber)?.doubleValue ?? 0,
      convertToDecibels: arguments["--dB"] as! Bool,
      quantization: quantization
    )

    // Make sure the group-by value is valid.
    guard let groupBy =
                CSVOptions.GroupBy(rawValue: arguments["--group-by"] as! String)
      else
    {
      print(usage)
      exit(EXIT_FAILURE)
    }

    // Initialize the CSV options.
    csvOptions = CSVOptions(generateCSV: arguments["--csv"] as! Bool, groupBy: groupBy)

    // Initialize the PNG options.
    pngOptions = PNGOptions(generateImage: arguments["--plot"] as! Bool,
                            generateDataPlot: arguments["--data"] as! Bool,
                            title: arguments["--title"] as? String)

    let fileList = expandGlobPatterns(in: arguments["FILE"] as! [String])

    // Initialize the list of file URLs.
    fileURLs = fileList.map(URL.init(fileURLWithPath:))

    // Get the root directory for generated files.
    let directory = arguments["--output-dir"] as? String

    // Initialize the output directory.
    let outputDirectory = URL(fileURLWithPath: directory
                                ?? FileManager.`default`.currentDirectoryPath)
    self.outputDirectory = outputDirectory

    // Switch on the directory provided for the generated CSV file.
    switch arguments["--csv-dir"] {
      case let subirectory as String where directory != nil:
        csvDirectory = outputDirectory.appendingPathComponent(subirectory)
      case let directory as String:
        csvDirectory = URL(fileURLWithPath: directory)
      default:
        csvDirectory = outputDirectory
    }

    // Switch on the directory provided for the generated PNG file.
    switch arguments["--png-dir"] {
      case let subdirectory as String where directory != nil:
        pngDirectory = outputDirectory.appendingPathComponent(subdirectory)
      case let directory as String:
        pngDirectory = URL(fileURLWithPath: directory)
      default:
        pngDirectory = outputDirectory
    }

    // Initialize the flag for creating directories.
    createDirectories = arguments["--create-directories"] as! Bool

  }

  /// Type encapsulating options relating to feature extraction.
  struct ExtractionOptions: CustomStringConvertible {

    /// Whether to use the algorithms in the Essentia framework.
    let useEssentia: Bool

    /// The window size to use during extraction.
    let windowSize: Int

    /// The hop size to use during extraction.
    let hopSize: Int

    /// Compress using compression factor.
    let compressionFactor: Double

    /// Whether to convert energy values to decibel equivalents.
    let convertToDecibels: Bool

    /// The bin quantization.
    let quantization: Quantization

    /// An enumeration of the possible quantizations of the extracted bins.
    ///
    /// - bin: Leaves the bins unquantized.
    /// - pitch: Quantizes the bins into pitches.
    /// - chroma: Quantizes the bins into chromas.
    enum Quantization: String { case bin, pitch, chroma }

    var description: String {
      return """
        useEssentia: \(useEssentia)
        windowSize: \(windowSize)
        hopSize: \(hopSize)
        convertToDecibels: \(convertToDecibels)
        compressionFactor: \(compressionFactor)
        quantization: \(quantization.rawValue)
        """
    }

  }

  /// Type encapsulating options relating to the generated CSV file.
  struct PNGOptions: CustomStringConvertible {

    /// Whether an image should be generated.
    let generateImage: Bool

    /// Whether the generated image should only consist of the data.
    let generateDataPlot: Bool

    /// The plot title.
    let title: String?

    var description: String {
      return """
        generateImage: \(generateImage)
        generateDataPlot: \(generateDataPlot)
        title: \(title != nil ? "'\(title!)'" : "nil")
        """
    }

  }

  /// Type encasulating options relating to the generated CSV file.
  struct CSVOptions: CustomStringConvertible {

    /// Whether a CSV file should be generated.
    let generateCSV: Bool

    /// The way frames should be grouped.
    let groupBy: GroupBy

    /// An enumeration for specifying the way frames are grouped in the CSV file.
    /// - row: Each line contains an entire frame.
    /// - column: Each line contains a column value from each frame.
    enum GroupBy: String { case row, column }

    var description: String {
      return """
        generateCSV: \(generateCSV)
        groupBy: \(groupBy.rawValue)
        """
    }

  }



}

extension Arguments: CustomStringConvertible {

  var description: String {

    return """
      verbose: \(verbose)
      fileURLs: \(fileURLs.map(\.path))
      outputDirectory: '\(outputDirectory.path)'
      csvDirectory: '\(csvDirectory.path)'
      pngDirectory: '\(pngDirectory.path)'
      createDirectories: \(createDirectories)
      \(extractionOptions)
      \(csvOptions)
      \(pngOptions)
      """

  }

}
