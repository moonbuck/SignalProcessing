//
//  Chunk.swift
//  SignalProcessing
//
//  Created by Jason Cardwell on 12/20/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation

extension CAFFile {

  public struct AnyChunk: CustomStringConvertible {

    public let header: ChunkHeader

    public let data: CAFFileChunkData

    public init(header: ChunkHeader, data: CAFFileChunkData) {
      self.header = header
      self.data = data
    }

    public init<Data>(_ chunk: Chunk<Data>) {
      self.init(header: chunk.header, data: chunk.data as CAFFileChunkData)
    }

    public var description: String {
      return """
        AnyChunk {
          \(header)
          \(data)
        }
        """
    }


  }

  public struct Chunk<Data:CAFFileChunkData>: CustomStringConvertible {

    public let header: ChunkHeader

    public let data: Data

    public init(header: ChunkHeader, data: Data) {
      self.header = header
      self.data = data
    }

    public var description: String {
      return """
      Chunk {
        \(header)
        \(data)
      }
      """
    }

  }

  public typealias AudioDescriptionChunk = Chunk<AudioDescriptionChunkData>
  public typealias StringsChunk = Chunk<StringsChunkData>
  public typealias ChannelLayoutChunk = Chunk<ChannelLayoutChunkData>
  public typealias FreeChunk = Chunk<FreeChunkData>
  public typealias MarkerChunk = Chunk<MarkerChunkData>
  public typealias DataChunk = Chunk<DataChunkData>
  public typealias OverviewChunk = Chunk<OverviewChunkData>
  public typealias UnrecognizedChunk = Chunk<UnrecognizedChunkData>




}
