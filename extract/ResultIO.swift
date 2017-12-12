//
//  ResultIO.swift
//  extract
//
//  Created by Jason Cardwell on 12/9/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import AppKit
import SignalProcessing

/// Writes the specified output to the specified URL.
///
/// - Parameters:
///   - result: The output to save to disk.
///   - url: The location to which `result` should be saved.
/// - Throws: Any error thrown `Data.write(to:options:)`.
func write(result: Command.Output, to url: URL) throws {

  let data: Data

  switch arguments.outputFormat {

    case .stdout:
      fatalError("Request to write to disk when the output format has been set to stdout.")

    case .csv:

      // Get the output as csv formatted text.
      let csv = csvFormattedText(from: result)

      // Get the csv text as raw data.
      guard let csvData = csv.data(using: .utf8) else {
        fatalError("Failed to get `csv` as raw data.")
      }

      data = csvData

    case .plot:

      guard result.isPlottable else {
        print("Output format is set to 'plot' but the result is not a plottable.")
        exit(EXIT_FAILURE)
      }

      let image = plotImage(from: result)
      guard let tiff = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiff),
            let imageData = bitmap.representation(using: .png, properties: [:])
      else
      {
        print("Failed to get the underlying data for the plot image.")
        exit(EXIT_FAILURE)
      }

      data = imageData

  }

  try data.write(to: url, options: [.atomic])

}

/// Generates text in the form of comma-separated values from the specified output.
///
/// - Parameter output: The output to convert to comma-separated values.
/// - Returns: A string with `output` as comma-separated values.
func csvFormattedText(from output: Command.Output) -> String {

  func singleColumn<S>(_ sequence: S) -> String
    where S:Sequence, S.Element:CustomStringConvertible
  {
    return sequence.map(\.description).joined(separator: "\n")
  }

  func multiColumn<C>(_ collection: C) -> String
    where C:Collection,
          C.Element:Collection,
          C.Element.Element:CustomStringConvertible,
          C.Index == Int,
          C.Element.Index == Int,
          C.IndexDistance == Int,
          C.Element.IndexDistance == Int
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

  switch output {
    case .real(let value):                return value.description
    case .integer(let value):             return value.description
    case .real64(let value):              return value.description
    case .complexReal(let value):         return value.description
    case .complexReal64(let value):       return value.description
    case .string(let value):              return value.description
    case .realVec(let value):             return singleColumn(value)
    case .real64Vec(let value):           return singleColumn(value)
    case .complexRealVec(let value):      return singleColumn(value)
    case .complexReal64Vec(let value):    return singleColumn(value)
    case .stringVec(let value):           return singleColumn(value)
    case .pitchVector(let value):         return singleColumn(value)
    case .binVector(let value):           return singleColumn(value)
    case .chromaVector(let value):        return singleColumn(value)
    case .realVecVec(let value):          return multiColumn(value)
    case .real64VecVec(let value):        return multiColumn(value)
    case .complexRealVecVec(let value):   return multiColumn(value)
    case .complexReal64VecVec(let value): return multiColumn(value)
    case .stringVecVec(let value):        return multiColumn(value)
    case .pitchVectorVec(let value, _):   return multiColumn(value)
    case .binVectorVec(let value):        return multiColumn(value)
    case .chromaVectorVec(let value, _):  return multiColumn(value)
    case .pool, .image:
      fatalError("Output is not a suitable type for representing as comma-separated values.")
  }

}

/// Generates a plot of the specified output. The output must be plottable.
///
/// - Parameter output: The output to plot.
/// - Returns: The image of the plot.
func plotImage(from output: Command.Output) -> NSImage {

  switch output {

    case .pitchVectorVec(let vectors, let featureRate):
      var vectors: [PitchVector] = []
      vectors.reserveCapacity(21)

      for _ in 0 ..< 21 {

        var vector = PitchVector()
        vector[0] = 1
        vector["c3"] = 1
        vector["e3"] = 1
        vector["g3"] = 1
        vector[63] = 1
        vector[vector.endIndex - 1] = 1
        vectors.append(vector)

      }

      return pitchPlot(features: vectors, featureRate: featureRate, mapKind: .grayscale, title: "extract output")

    case .chromaVectorVec(let vectors, let featureRate):
      var vectors: [ChromaVector] = []
      vectors.reserveCapacity(21)

      for _ in 0 ..< 21 {

        var vector = ChromaVector()
        vector[.c] = 1
        vector[.e] = 1
        vector[.g] = 1
        vector[.b] = 1
        vectors.append(vector)

      }

      return chromaPlot(features: vectors, featureRate: featureRate, mapKind: .grayscale, title: "extract output")

    default:
      fatalError("\(output) is not a case for which plotting is supported.")

  }

}

/// Generates text suitable for printing to a console that contains the specified output.
///
/// - Parameter output: The output to convert to text.
/// - Returns: A string representation of `output` suitable for reading.
func text(from output: Command.Output) -> String {
  //TODO: Implement the  function
  fatalError("\(#function) not yet implemented.")
}
