//
//  main.swift
//  split_audio
//
//  Created by Jason Cardwell on 12/18/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import SignalProcessing

// Parse the command-line arguments.
let arguments = Arguments()

if arguments.verbose {
  print("splitting \(arguments.fileURLs.count) files...")
}

// Iterate the list of input files.
for fileURL in arguments.fileURLs {


  do {

    // Parse the contents of `fileURL` into a `CAFFile`.
    guard let file = try CAFFile(url: fileURL) else {
      print("The specified file is not a valid CAF file.")
      exit(EXIT_FAILURE)
    }

    // Split the file.
    try split(file: file)

  } catch {

    print("Error reading from '\(fileURL.path)': \(error.localizedDescription)")
    exit(EXIT_FAILURE)

  }

}

if arguments.verbose {
  print("finished splitting \(arguments.fileURLs.count) files")
}


