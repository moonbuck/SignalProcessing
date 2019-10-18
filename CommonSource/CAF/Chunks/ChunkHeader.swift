//
//  ChunkHeader.swift
//  SignalProcessing
//
//  Created by Jason Cardwell on 12/20/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import struct AudioToolbox.CAFChunkHeader
import MoonKit

extension CAFFile {

  public struct ChunkHeader: CAFFileChunkHeader {

    public static let headerSize: Int = MemoryLayout<CAFChunkHeader>.size

    public let type: FourCharacterCode
    public let size: Int

    public init(type: FourCharacterCode, size: Int) { self.type = type; self.size = size }

    public init?(data: Data) {

      guard data.count == ChunkHeader.headerSize else { return nil }

      self = data.withUnsafeBytes({
        guard let chunk = ($0.baseAddress?.assumingMemoryBound(to: CAFChunkHeader.self)
                                  ?? nil)?.pointee
          else { fatalError("\(#function) ") }

        return ChunkHeader(type: FourCharacterCode(value: chunk.mChunkType.bigEndian),
                           size: Int(chunk.mChunkSize.bigEndian))

      })


    }

    public var description: String {
      return "ChunkHeader { type: '\(type.stringValue)'; size: \(size) bytes }"
    }

  }

}

