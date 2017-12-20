//
//  main.swift
//  caf_info
//
//  Created by Jason Cardwell on 12/19/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import AudioToolbox

let arguments = Arguments()

do {
  guard let cafFile = try CAFFile(url: arguments.inputURL) else {
    print("The specified file is not a valid CAF file.")
    exit(EXIT_FAILURE)
  }
  print(cafFile)
} catch {
  print("Error reading from '\(arguments.inputURL.path)': \(error.localizedDescription)")
  exit(EXIT_FAILURE)
}

