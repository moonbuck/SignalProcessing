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

//  ************    Load input audio file.

// Get a buffer filled with the contents of the input audio file.
guard let audioBuffer = try? AVAudioPCMBuffer(contentsOf: URL(fileURLWithPath: arguments.input))
  else
{
  print(Error.invalidInput.rawValue)
  exit(EXIT_FAILURE)
}

// Check the sample rate.
guard audioBuffer.format.sampleRate == 44100 else {
  print("Only audio files with a sample rate of 44100 Hz are currently supported.")
  exit(EXIT_FAILURE)
}

// Downmix to mono, converting to 64bit samples unless Essentia is to be used.
let monoBuffer = arguments.useEssentia ? audioBuffer.mono : audioBuffer.mono64

//  ************    Execute the specified command.

let result = arguments.command.execute(input: monoBuffer)

//  ************    Send output to the specified destination.


// Check whether a file destination path has been provided; otherwise, print to stdout and exit.
guard let fileOut = arguments.output else {
  print(text(from: result))
  exit(EXIT_SUCCESS)
}

// Try writing the result to the specified file.
do {
  try write(result: result, to: URL(fileURLWithPath: fileOut))
  exit(EXIT_SUCCESS)
} catch {
  print("Error encountered writing to file '\(fileOut)': \(error.localizedDescription)")
  exit(EXIT_FAILURE)
}
