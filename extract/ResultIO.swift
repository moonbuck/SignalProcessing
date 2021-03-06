//
//  ResultIO.swift
//  extract
//
//  Created by Jason Cardwell on 12/9/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import AppKit
import MoonKit
import SignalProcessing

private var checkedCSVDirectory = false
private var checkedPNGDirectory = false

/// Writes the specified output to the specified URL.
///
/// - Parameters:
///   - result: The output to save to disk.
///   - url: The location to which `result` should be saved.
/// - Throws: Any error thrown `Data.write(to:options:)`.
func write(result: Output) throws {

  // Check whether a CSV file should be generated.
  if arguments.csvOptions.generateCSV {

    // Get the output as csv formatted text.
    let csv = csvFormattedText(from: result)

    // Get the csv text as raw data.
    guard let data = csv.data(using: .utf8) else {
      fatalError("Failed to get `csv` as raw data.")
    }

    if !checkedCSVDirectory {

      // Check the directory specified for the generated CSV file.
      guard try checkDirectory(url: arguments.csvDirectory,
                               createDirectories: arguments.createDirectories)
        else
      {
        print("Invalid directory for the generated CSV files: '\(arguments.csvDirectory.path)'")
        exit(EXIT_FAILURE)
      }

      checkedCSVDirectory = true

    }

    

    // Create the URL for the CSV file.
    let url = arguments.csvDirectory.appendingPathComponent(currentFileBaseName + ".csv")

    // Write the file to disk.
    try data.write(to: url, options: [.atomic])

  }

  // Check whether an image file should be generated.
  if arguments.pngOptions.generateImage {

    let image = plotImage(from: result)
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let data = bitmap.representation(using: .png, properties: [:])
      else
    {
      print("Failed to get the underlying data for the plot image.")
      exit(EXIT_FAILURE)
    }

    if !checkedPNGDirectory {

      // Check the directory specified for the generated PNG file.
      guard try checkDirectory(url: arguments.pngDirectory,
                               createDirectories: arguments.createDirectories)
      else
      {
        print("Invalid directory for the generated PNG files: '\(arguments.csvDirectory.path)'")
        exit(EXIT_FAILURE)
      }

      checkedPNGDirectory = true

    }

    // Create the URL for the CSV file.
    let url = arguments.pngDirectory.appendingPathComponent(currentFileBaseName + ".png")

    // Write the file to disk.
    try data.write(to: url, options: [.atomic])

  }

}

/// Generates text in the form of comma-separated values from the specified output.
///
/// - Parameter output: The output to convert to comma-separated values.
/// - Returns: A string with `output` as comma-separated values.
func csvFormattedText(from output: Output) -> String {

  func rowMajor<C>(_ collection: C) -> String
    where C:Collection,
          C.Element:Collection,
          C.Element.Element:CustomStringConvertible
  {
    return collection.map({$0.map(\.description).joined(separator: ",")}).joined(separator: "\n")
  }

  func columnMajor<C>(_ collection: C) -> String
    where C:Collection,
          C.Element:Collection,
          C.Element.Element:CustomStringConvertible,
          C.Index == Int,
          C.Element.Index == Int
  {
    let rowCount = collection.count
    let maxColumnCount = collection.map(\.count).max() ?? 0

    guard maxColumnCount > 0 else { return "" }

    var transposed: [[String]] = []

    for column in 0..<maxColumnCount {

      var transposedRow: [String] = []

      for row in 0..<rowCount {
        transposedRow.append(collection[row][column].description)
      }

      transposed.append(transposedRow)

    }

    return transposed.map({$0.joined(separator: ",")}).joined(separator: "\n")

  }

  switch (output, arguments.csvOptions.groupBy) {
    case (.pitchFeatures(let value, _), .column):   return columnMajor(value)
    case (.binFeatures(let value, _), .column):     return columnMajor(value)
    case (.chromaFeatures(let value, _), .column):  return columnMajor(value)
    case (.pitchFeatures(let value, _), .row):      return rowMajor(value)
    case (.binFeatures(let value, _), .row):        return rowMajor(value)
    case (.chromaFeatures(let value, _), .row):     return rowMajor(value)
  }

}

/// Generates a plot of the specified output. The output must be plottable.
///
/// - Parameter output: The output to plot.
/// - Returns: The image of the plot.
func plotImage(from output: Output) -> NSImage {

  switch output {

    case .binFeatures(let vectors, let featureRate) where arguments.pngOptions.generateDataPlot:
      return binDataImage(features: vectors, featureRate: featureRate)

    case .binFeatures(let vectors, let featureRate):
      return binPlot(features: vectors,
                     featureRate: featureRate,
                     mapKind: .grayscale,
                     title: arguments.pngOptions.title)

    case .pitchFeatures(let vectors, let featureRate) where arguments.pngOptions.generateDataPlot:
      return pitchDataImage(features: vectors, featureRate: featureRate)

    case .pitchFeatures(let vectors, let featureRate):
      return pitchPlot(features: vectors,
                       featureRate: featureRate,
                       mapKind: .grayscale,
                       title: arguments.pngOptions.title)

    case .chromaFeatures(let vectors, let featureRate) where arguments.pngOptions.generateDataPlot:
      return chromaDataImage(features: vectors, featureRate: featureRate)

    case .chromaFeatures(let vectors, let featureRate):
      return chromaPlot(features: vectors,
                        featureRate: featureRate,
                        mapKind: .grayscale,
                        title: arguments.pngOptions.title)

  }

}

/// Generates text suitable for printing to a console that contains the specified output.
///
/// - Parameter output: The output to convert to text.
/// - Returns: A string representation of `output` suitable for reading.
func text(from output: Output) -> String {

  let features: [[Float64]]
  let featureRate: CGFloat

  switch output {

    case .binFeatures(let vectors, let rate):
      features = vectors.map(Array.init)
      featureRate = rate

    case .pitchFeatures(let vectors, let rate):
      features = vectors.map(Array.init)
      featureRate = rate

    case .chromaFeatures(let vectors, let rate):
      features = vectors.map(Array.init)
      featureRate = rate

  }

  let columnWidth = 18
  let valueWidth = 16
  let indexColumnWidth = 8
  let line = "─" * (columnWidth + indexColumnWidth)
  let indexLabel = "Index".padded(to: indexColumnWidth, alignment: .center)
  let valueLabel = "Value".padded(to: columnWidth, alignment: .center)
  let tableHeader: String = "\(indexLabel)\(valueLabel)\n\(line)"

  func format(index: Int) -> String {
    return index.description.padded(to: indexColumnWidth - 2, alignment: .right, padCharacter: " ")
  }

  func format(value: Float64) -> String {
    let valueDescription = String(describing: value, maxPrecision: 11, minPrecision: 0)
    return valueDescription.padded(to: valueWidth, alignment: .right)
  }

  var result = "Extracted \(features.count) frames with a feature rate of \(featureRate) Hz.\n\n"

  for frameIndex in features.indices {

    print("Frame: \(frameIndex)\n\(tableHeader)", to: &result)

    let frame = features[frameIndex]

    for (index, value) in frame.enumerated() {

      print(format(index: index), format(value: value), separator: "  ", to: &result)

    }

    print("", to: &result)

  }

  return result

}
