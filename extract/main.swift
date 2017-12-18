//
//  main.swift
//  extract
//
//  Created by Jason Cardwell on 12/9/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import AVFoundation
import SignalProcessing

let arguments = Arguments()

var currentFileBaseName = ""

print("extracting features from \(arguments.fileURLs.count) files...")

// Iterate the input audio files
for (index, inputFile) in arguments.fileURLs.enumerated() {

  currentFileBaseName = inputFile.deletingPathExtension().lastPathComponent

  print("processing file \(index + 1): \(inputFile.lastPathComponent)...", terminator: "")

  //  ************    Load input audio file.

  // Get a buffer filled with the contents of the input audio file.
  guard let audioBuffer = try? AVAudioPCMBuffer(contentsOf: inputFile) else {
    print(Error.invalidInput.rawValue)
    exit(EXIT_FAILURE)
  }

  // Check the sample rate.
  guard audioBuffer.format.sampleRate == 44100 else {
    print("Only audio files with a sample rate of 44100 Hz are currently supported.")
    exit(EXIT_FAILURE)
  }

  // Downmix to mono, converting to 64bit samples unless Essentia is to be used.
  let monoBuffer = arguments.extractionOptions.useEssentia ? audioBuffer.mono : audioBuffer.mono64

  //  ************    Execute the specified command.

  let result = extractFeatures(using: monoBuffer)

  //  ************    Generate output file(s).

  do {

    // Try writing the result to disk.
    try write(result: result)

  } catch {

    print("Error encountered writing to disk: \(error.localizedDescription)")
    exit(EXIT_FAILURE)

  }

  print("finished")

}

print("finished processing \(arguments.fileURLs.count) files.")
