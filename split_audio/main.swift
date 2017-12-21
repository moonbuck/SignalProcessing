//
//  main.swift
//  split_audio
//
//  Created by Jason Cardwell on 12/18/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import SignalProcessing

let arguments = Arguments()

print(arguments)

let file: CAFFile

do {
  guard let fileʹ = try CAFFile(url: arguments.inputURL) else {
    print("The specified file is not a valid CAF file.")
    exit(EXIT_FAILURE)
  }
  file = fileʹ
} catch {
  print("Error reading from '\(arguments.inputURL.path)': \(error.localizedDescription)")
  exit(EXIT_FAILURE)
}

if arguments.splitByMarker {

  guard let markers = file.markers?.data.markers else {
    print("Split by marker specified but the audio file has no markers.")
    exit(EXIT_FAILURE)
  }

  do {

    if let labels = file.strings?.data.strings {
      try split(using: markers, and: labels)
    } else {
      try split(using: markers)
    }

  } catch {
    print("Error encountered splitting the file: \(error.localizedDescription).")
    exit(EXIT_FAILURE)
  }

}
