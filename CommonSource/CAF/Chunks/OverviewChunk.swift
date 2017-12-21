//
//  OverviewChunk.swift
//  SignalProcessing
//
//  Created by Jason Cardwell on 12/20/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation

extension CAFFile {

  public struct OverviewChunkData: CAFFileChunkData {

    public let editCount: Int
    public let framesPerSample: Int
    public let size: Int

    public init(editCount: Int, framesPerSample: Int, size: Int) {
      self.editCount = editCount
      self.framesPerSample = framesPerSample
      self.size = size
    }

    public init?(data: Data) {

      guard data.count >= 8 else { return nil }

      editCount = data[data.subrange(offset: 0, length: 4)].withUnsafeBytes {
        (pointer: UnsafePointer<UInt32>) -> Int in Int(pointer.pointee.bigEndian)
      }

      framesPerSample = data[data.subrange(offset: 4, length: 4)].withUnsafeBytes {
        (pointer: UnsafePointer<UInt32>) -> Int in Int(pointer.pointee.bigEndian)
      }

      size = data.count - 8

    }

    public var description: String {
      return """
        OverviewChunkData { editCount: \(editCount); framesPerSample: \(framesPerSample); \
        size: \(size) bytes }
        """
    }

  }

}
