//
//  StringsChunk.swift
//  caf_info
//
//  Created by Jason Cardwell on 12/20/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation

extension CAFFile {

  public struct StringsChunkData: CAFFileChunkData {

    public let ids: [StringID]
    public let strings: [String]

    public init(ids: [StringID], strings: [String]) {
      guard ids.count == strings.count else {
        fatalError("\(#function) `ids` and `strings` must have the same number of elements.")
      }
      self.ids = ids
      self.strings = strings
    }

    public var description: String {
      return """
        StringsChunkData { ids: (\(ids.count) elements); strings: (\(strings.count) elements) }
        """
    }

    public init?(data: Data) {

      guard data.count >= 4 else { return nil }

      let numEntries = data[data.subrange(offset: 0, length: 4)].withUnsafeBytes {
        (pointer: UnsafePointer<UInt32>) -> Int in Int(pointer.pointee.bigEndian)
      }

      guard data.count >= MemoryLayout<StringID>.size * numEntries + 4 else { return nil }

      var ids: [StringID] = []

      ids.reserveCapacity(numEntries)

      var start = 4

      while ids.count < numEntries {

        let id = data[data.subrange(start: start, length: 4)].withUnsafeBytes {
          (pointer: UnsafePointer<UInt32>) -> UInt32 in pointer.pointee.bigEndian
        }

        start += 4

        let startByteOffset = data[data.subrange(start: start, length: 8)].withUnsafeBytes {
          (pointer: UnsafePointer<Int64>) -> Int64 in pointer.pointee.bigEndian
        }

        start += 8

        let stringID = StringID(id: id, startByteOffset: startByteOffset)

        ids.append(stringID)

      }

      var strings: [String] = []
      strings.reserveCapacity(numEntries)

      var currentString = ""

      for byte in data[start...] where strings.count < numEntries {

        if byte == 0 {
          strings.append(currentString)
          currentString = ""
        } else {
          currentString.append(Character(Unicode.Scalar(byte)))
        }

      }

      guard strings.count == numEntries else { return nil }

      self.ids = ids
      self.strings = strings

    }

  }

}

extension CAFFile.StringsChunkData {

  public struct StringID: CustomStringConvertible {

    public let id: UInt32
    public let startByteOffset: Int64

    public init(id: UInt32, startByteOffset: Int64) {
      self.id = id
      self.startByteOffset = startByteOffset
    }

    public var description: String {
      return "StringID { id: \(id); startByteOffset: \(startByteOffset) }"
    }

  }

}


