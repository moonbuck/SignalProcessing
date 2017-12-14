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
Usage: extract (--spectrum | --pitch | --chroma) [options] <input> [<output>]
       extract (--spectrum | --pitch | --chroma) [options] <input> --csv [--group-by=<grp>] [<output>]
       extract (--spectrum | --pitch | --chroma) [options] <input> --plot [(--title=<t> | --data)] [<output>]
       extract --help

Command:
  --spectrum  Extracts the frequency spectrum without further quantization.
  --pitch     Extracts the frequency spectrum and requantizes to correspond with MIDI pitches.
  --chroma    Extracts the frequency spectrum and requantizes to correspond with the 12 chromas.

Arguments:
  <input>   The file path for the input audio file.
  <output>  The file path to which output should be written. If not provided, output will be
            written to stdout.

CSV Options:
  --csv                    Output result as csv data.
  --group-by=<grp:string>  Group csv data by row or column. [default: row]

Plot Options:
  --plot              Output result as an image of the plotted data.
  --title=<t:string>  The title to display at the top of the plot.
  --data              The image will consist of only the features with each value mapped to a pixel.

Options:
  --essentia      Use algorithms from the Essentia framework.
  --win=<ws:int>  The size of the window to use. [default: 8820]
  --hop=<hs:int>  The hop size to use. [default: 4410]
  -h, --help      Show this help message and exit.
"""

struct Arguments {

  /// Whether to use the algorithms in the Essentia framework.
  let useEssentia: Bool

  /// The window size to use during extraction.
  let windowSize: Int

  /// The hop size to use during extraction.
  let hopSize: Int

  /// The file path for the input audio file.
  let input: String

  /// The destination for the extracted features.
  let destination: Destination

  /// The desired output format.
  let outputFormat: OutputFormat

  /// The bin quantization.
  let quantization: Quantization

  /// The plot title.
  let title: String

  /// Whether the image should only consist of the data.
  let naked: Bool

  let groupBy: GroupBy

  /// Initialize by parsing the command line arguments.
  init() {

    // Parse the command line arguments.
    let arguments = Docopt.parse(usage, help: true)

    useEssentia = arguments["--essentia"] as! Bool
    windowSize = (arguments["--win"] as! NSNumber).intValue
    hopSize = (arguments["--hop"] as! NSNumber).intValue
    input = arguments["<input>"] as! String

    outputFormat = arguments["--csv"] as! Bool
                     ? .csv
                     : arguments["--plot"] as! Bool
                       ? .plot
                       : .text

    if let fileOut = arguments["<output>"] as? String {
      switch outputFormat {
        case .csv where !fileOut.hasSuffix(".csv"):
          destination = .file(fileOut + ".csv")
        case .plot where !fileOut.hasSuffix(".png"):
          destination = .file(fileOut + ".png")
        case .text where !fileOut.hasSuffix(".txt"):
          destination = .file(fileOut + ".txt")
        default:
          destination = .file(fileOut)
      }
    } else {
      destination = .stdout
    }
    
    title = arguments["--title"] as? String ?? ""
    naked = arguments["--data"] as! Bool
    
    guard let groupBy = GroupBy(rawValue: arguments["--group-by"] as! String) else {
      print(usage)
      exit(EXIT_FAILURE)
    }
    self.groupBy = groupBy

    quantization = arguments["--pitch"] as! Bool
                     ? .pitch
                     : arguments["--chroma"] as! Bool
                       ? .chroma
                       : .bin


  }

  enum GroupBy: String { case row, column }


  enum Destination: CustomStringConvertible {
    case stdout
    case file (String)

    var description: String {
      switch self {
        case .stdout: return "stdout"
        case .file(let path): return path
      }
    }
  }

  enum OutputFormat: String {
    case text, csv, plot
  }

  enum Quantization: String {
    case bin, pitch, chroma
  }

}

extension Arguments: CustomStringConvertible {

  var description: String {

    return """
    useEssentia: \(useEssentia)
    windowSize: \(windowSize)
    hopSize: \(hopSize)
    input: \(input)
    destination: \(destination)
    outputFormat: \(outputFormat)
    quantization: \(quantization)
    title: "\(title)"
    groupBy: \(groupBy)
    """

  }

}
