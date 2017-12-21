//
//  CAFFile.swift
//  SignalProcessing
//
//  Created by Jason Cardwell on 12/19/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import AudioToolbox

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

  public let audioDescription: AudioDescriptionChunk

  public let data: DataChunk

  public let strings: StringsChunk?

  public let channelLayout: ChannelLayoutChunk?

  public let overview: OverviewChunk?

  public let markers: MarkerChunk?

  public let free: FreeChunk?

  public let unrecognized: [UnrecognizedChunk]

  public init?(url: URL) throws {

    // Open the file for reading.
    let file = try FileHandle(forReadingFrom: url)

    // Read the file header bytes.
    var bytes = file.readData(ofLength: FileHeader.headerSize)

    // Parse the file header.
    guard let fileHeader = FileHeader(data: bytes) else { return nil }

    // Read the audio description header bytes.
    bytes = file.readData(ofLength: ChunkHeader.headerSize)

    // Parse the audio description header
    guard let header = ChunkHeader(data: bytes) else { return nil }

    // Check the type declared by the header.
    guard header.type.stringValue == "desc" else { return nil }

    // Read the audio description bytes.
    bytes = file.readData(ofLength: header.size)

    // Parse the audio description bytes.
    guard let chunkData = AudioDescriptionChunkData(data: bytes) else { return nil }

    // Create the audio description chunk.
    let audioDescription = AudioDescriptionChunk(header: header, data: chunkData)

    // Create variables for parsed chunks.
    var strings: StringsChunk? = nil
    var channelLayout: ChannelLayoutChunk? = nil
    var overview: OverviewChunk? = nil
    var markers: MarkerChunk? = nil
    var free: FreeChunk? = nil
    var data: DataChunk? = nil
    var unrecognized: [UnrecognizedChunk] = []

    // Iterate while another chunk header can be parsed.
    while let header = ChunkHeader(data: file.readData(ofLength: ChunkHeader.headerSize)) {

      switch header.type.stringValue {

        case "chan":
          // Parse the channel layout chunk data.

          guard let chunkData =
            ChannelLayoutChunkData(data: file.readData(ofLength: header.size))
            else
          {
            return nil
          }
          channelLayout = ChannelLayoutChunk(header: header, data: chunkData)

        case  "free":
          // Create the free chunk and skip past the data.

          free = FreeChunk(header: header, data: FreeChunkData(size: header.size))
          file.seek(toFileOffset: file.offsetInFile + UInt64(header.size))

        case "ovvw":
          // Parse the overview chunk data.

          guard let chunkData =
            OverviewChunkData(data: file.readData(ofLength: header.size))
            else
          {
            return nil
          }
          overview = OverviewChunk(header: header, data: chunkData)

        case "mark":
          // Parse the marker chunk data.

          guard let chunkData =
            MarkerChunkData(data: file.readData(ofLength: header.size))
            else
          {
            return nil
          }
          markers = MarkerChunk(header: header, data: chunkData)

        case "strg":
          // Parse the strings chunk data.

          guard let chunkData =
            StringsChunkData(data: file.readData(ofLength: header.size))
            else
          {
            return nil
          }
          strings = StringsChunk(header: header, data: chunkData)

        case "data":
          // Create the data chunk and skip past the samples.

          data = DataChunk(header: header, data: DataChunkData(size: header.size))
          file.seek(toFileOffset: file.offsetInFile + UInt64(header.size))

        default:
          // Create an unrecognzied chunk and skip past the chunk data.

          unrecognized.append(UnrecognizedChunk(header: header,
                                                data: UnrecognizedChunkData(size: header.size)))
          file.seek(toFileOffset: file.offsetInFile + UInt64(header.size))

      }

    }

    // Make sure there was a data chunk.
    guard data != nil else { return nil }

    self.url = url
    self.header = fileHeader
    self.audioDescription = audioDescription
    self.data = data!
    self.channelLayout = channelLayout
    self.strings = strings
    self.markers = markers
    self.free = free
    self.overview = overview
    self.unrecognized = unrecognized

  }

  public var chunks: [AnyChunk] {

    var result: [AnyChunk] = []

    result.append(AnyChunk(audioDescription))
    result.append(AnyChunk(data))

    if let channelLayout = channelLayout { result.append(AnyChunk(channelLayout)) }
    if let strings = strings             { result.append(AnyChunk(strings))       }
    if let markers = markers             { result.append(AnyChunk(markers))       }
    if let free = free                   { result.append(AnyChunk(free))          }
    if let overview = overview           { result.append(AnyChunk(overview))      }

    result.append(contentsOf: unrecognized.map(AnyChunk.init))

    return result

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


