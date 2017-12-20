//
//  Chunk.swift
//  caf_info
//
//  Created by Jason Cardwell on 12/20/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation

extension CAFFile {

  public struct Chunk: CustomStringConvertible {

    public let header: ChunkHeader

    public let data: CAFFileChunkData

    public init(header: ChunkHeader, data: CAFFileChunkData) {
      self.header = header
      self.data = data
    }
/*      guard data.count >= ChunkHeader.headerSize,
            let header = ChunkHeader(data: data[data.subrange(offset: 0,
                                                              length: ChunkHeader.headerSize)])
        else
      {
        return nil
      }

      guard data.count - ChunkHeader.headerSize >= Int(header.size) else { return nil }

      let dataRange = data.subrange(offset: ChunkHeader.headerSize, length: header.size)
      let dataʹ: CAFFileChunkData

      switch header.type.stringValue {

        case "chan":
          guard let dataʺ = ChannelLayoutChunkData(data: data[dataRange]) else { return nil }
          dataʹ = dataʺ

        case "free":
          guard let dataʺ = FreeChunkData(data: data[dataRange]) else { return nil }
          dataʹ = dataʺ

        case "ovvw":
          guard let dataʺ = OverviewChunkData(data: data[dataRange]) else { return nil }
          dataʹ = dataʺ

        case "mark":
          guard let dataʺ = MarkerChunkData(data: data[dataRange]) else { return nil }
          dataʹ = dataʺ

        case "strg":
          guard let dataʺ = StringsChunkData(data: data[dataRange]) else { return nil }
          dataʹ = dataʺ

        case "data":
          guard let dataʺ = DataChunkData(data: data[dataRange]) else { return nil }
          dataʹ = dataʺ

        default:
          guard let dataʺ = UnrecognizedChunkData(data: data[dataRange]) else { return nil }
          dataʹ = dataʺ

      }

      self.header = header
      self.data = dataʹ

    }
*/

    public var description: String {
      return """
      Chunk {
        \(header)
        \(data)
      }
      """
    }

  }

}
