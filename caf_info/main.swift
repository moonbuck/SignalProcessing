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

print(arguments)

let file: FileHandle

do {
  file = try FileHandle(forReadingFrom: arguments.inputURL)
} catch {
  print("Error reading from '\(arguments.inputURL.path)': \(error.localizedDescription)")
  exit(EXIT_FAILURE)
}

var headerData = file.readData(ofLength: MemoryLayout<CAFFileHeader>.size)

guard let fileHeader = CAFFile.FileHeader(data: headerData),
      fileHeader.type.stringValue == "caff",
      fileHeader.version > 0
  else
{
  print("Failed to decode file header.")
  exit(EXIT_FAILURE)
}

print(fileHeader)

let headerSize = MemoryLayout<CAFChunkHeader>.size
headerData = file.readData(ofLength: headerSize)

guard let audioDescriptionHeader = CAFFile.ChunkHeader(data: headerData),
      audioDescriptionHeader.type.stringValue == "desc"
else
{
  print("Failed to decode audio description header chunk.")
  exit(EXIT_FAILURE)
}

print(audioDescriptionHeader)

var data = file.readData(ofLength: MemoryLayout<CAFAudioDescription>.size)

guard let audioDescription = CAFFile.AudioDescriptionChunk(data: data) else {
  print("Failed to decode audio description chunk.")
  exit(EXIT_FAILURE)
}

print(audioDescription)

while let header = CAFFile.ChunkHeader(data: file.readData(ofLength: headerSize)) {

  print(header)

  switch header.type.stringValue {

  case "chan":
    let channelLayoutData = file.readData(ofLength: Int(header.size))
    guard let channelLayout = CAFFile.ChannelLayoutChunk(data: channelLayoutData) else {
      print("Failed to decode channel layout chunk.")
      exit(EXIT_FAILURE)
    }
    print(channelLayout)

  case  "free":
    let freeChunk = CAFFile.FreeChunk(size: header.size)
    file.seek(toFileOffset: file.offsetInFile + UInt64(header.size))
    print(freeChunk)

  case "ovvw":
    let overviewData = file.readData(ofLength: Int(header.size))
    guard let overview = CAFFile.OverviewChunk(data: overviewData) else {
      print("Failed to decode overview chunk.")
      exit(EXIT_FAILURE)
    }
    print(overview)

  case "mark":
    let markerData = file.readData(ofLength: Int(header.size))
    guard let marker = CAFFile.MarkerChunk(data: markerData) else {
      print("Failed to decode marker chunk.")
      exit(EXIT_FAILURE)
    }
    print(marker)

  case "strg":
    let stringsData = file.readData(ofLength: Int(header.size))
    guard let strings = CAFFile.StringsChunk(data: stringsData) else {
      print("Failed to decode string chunk.")
      exit(EXIT_FAILURE)
    }
    print(strings)

  case "data":
    let dataChunk = CAFFile.DataChunk(size: header.size)
    file.seek(toFileOffset: file.offsetInFile + UInt64(header.size))
    print(dataChunk)

  default:
    file.seek(toFileOffset: file.offsetInFile + UInt64(header.size))

  }

}

