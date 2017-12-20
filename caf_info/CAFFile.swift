//
//  CAFFile.swift
//  caf_info
//
//  Created by Jason Cardwell on 12/19/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import AudioToolbox
import SignalProcessing

/// A simple protocol for types that represent a header chunk in a CAF file.
public protocol CAFFileChunkHeader: CustomStringConvertible {

  /// Initializing with raw bytes.
  init?(data: Data)

}


/// A simple protocol for types that represent a data chunk in a CAF file.
public protocol CAFFileChunkData: CustomStringConvertible {

  /// Initializing with raw bytes.
  init?(data: Data)

}

public struct CAFFile: CustomStringConvertible {

  public let url: URL

  public let header: FileHeader

  public let chunks: [Chunk]

  public init?(url: URL) throws {

    let file = try FileHandle(forReadingFrom: url)

    var data = file.readData(ofLength: FileHeader.headerSize)

    guard let fileHeader = FileHeader(data: data) else { return nil }

    var chunks: [Chunk] = []

    data = file.readData(ofLength: ChunkHeader.headerSize)

    guard let header = ChunkHeader(data: data) else { return nil }

    guard header.type.stringValue == "desc" else { return nil }

    data = file.readData(ofLength: header.size)

    guard let chunkData = AudioDescriptionChunkData(data: data) else { return nil }

    chunks.append(Chunk(header: header, data: chunkData))

    while let header = ChunkHeader(data: file.readData(ofLength: ChunkHeader.headerSize)) {

      let chunkData: CAFFileChunkData?

      switch header.type.stringValue {

        case "chan":
          chunkData = ChannelLayoutChunkData(data: file.readData(ofLength: header.size))

        case  "free":
          chunkData = FreeChunkData(size: header.size)
          file.seek(toFileOffset: file.offsetInFile + UInt64(header.size))

        case "ovvw":
          chunkData = OverviewChunkData(data: file.readData(ofLength: header.size))

        case "mark":
          chunkData = MarkerChunkData(data: file.readData(ofLength: header.size))

        case "strg":
          chunkData = StringsChunkData(data: file.readData(ofLength: header.size))

        case "data":
          chunkData = DataChunkData(size: header.size)
          file.seek(toFileOffset: file.offsetInFile + UInt64(header.size))

        default:
          chunkData = UnrecognizedChunkData(size: header.size)
          file.seek(toFileOffset: file.offsetInFile + UInt64(header.size))

      }

      guard chunkData != nil else { return nil }

      chunks.append(Chunk(header: header, data: chunkData!))

    }

    self.url = url
    self.header = fileHeader
    self.chunks = chunks

  }

  public var description: String {

    let chunkDescriptions = chunks.map({

      var result = "\($0.header)\n  "

      let lines = $0.data.description.split(separator: "\n")

      if lines.count == 1 {
        result += lines[0]
      } else {
        result += lines.joined(separator: "\n  ")
      }

      return result
      
    }).joined(separator: "\n  ")

    return """
    CAFFile {
      url: '\(url.path)'
      \(header)
      \(chunkDescriptions)
    }
    """
  }

}


