//
//  FileHeader.swift
//  SignalProcessing
//
//  Created by Jason Cardwell on 12/20/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import struct AudioToolbox.CAFFileHeader
import MoonKit

extension CAFFile {

  public struct FileHeader: CAFFileChunkHeader {

    public static let headerSize = MemoryLayout<CAFFileHeader>.size

    public let type: FourCharacterCode
    public let version: UInt16
    public let flags: UInt16

    public init(type: FourCharacterCode, version: UInt16, flags: UInt16) {
      self.type = type
      self.version = version
      self.flags = flags
    }

    public init?(data: Data) {

      guard data.count == MemoryLayout<CAFFileHeader>.size else { return nil }

      self = data.withUnsafeBytes {
        guard let header = ($0.baseAddress?.assumingMemoryBound(to: CAFFileHeader.self)
                                ?? nil)?.pointee
        else { fatalError("\(#function) ") }

        return FileHeader(type: FourCharacterCode(value: header.mFileType.bigEndian),
                          version: header.mFileVersion.bigEndian,
                          flags: header.mFileFlags.bigEndian)

      }

      guard type.stringValue == "caff" && version > 0 else { return nil }

    }

    public var description: String {
      return "FileHeader { type: '\(type.stringValue)'; version: \(version); flags: \(flags) }"
    }

  }

}

