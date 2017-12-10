//
//  ResultIO.swift
//  extract
//
//  Created by Jason Cardwell on 12/9/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import AppKit


func write(result: Command.Output, to url: URL) throws {

  switch arguments.outputFormat {

  case .csv:

    // Get the output as csv formatted text.
    let csv = csvFormattedText(from: result)

    // Get the csv text as raw data.
    guard let csvData = csv.data(using: .utf8) else {
      fatalError("Failed to get `csv` as raw data.")
    }

    // Write the data to the specified URL.
    try csvData.write(to: url)

  case .plot:
    //TODO: Implement the  function
    fatalError("\(#function) not yet implemented for `.plot` output format.")

  }


}

func csvFormattedText(from output: Command.Output) -> String {
  //TODO: Implement the  function
  fatalError("\(#function) not yet implemented.")
}

func plotImage(from output: Command.Output) -> NSImage {
  //TODO: Implement the  function
  fatalError("\(#function) not yet implemented.")
}

func text(from output: Command.Output) -> String {
  //TODO: Implement the  function
  fatalError("\(#function) not yet implemented.")
}
