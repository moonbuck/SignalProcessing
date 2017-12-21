//
//  FileHeader.swift
//  SignalProcessing
//
//  Created by Jason Cardwell on 12/20/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import struct AudioToolbox.CAFFileHeader

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
        (pointer: UnsafePointer<CAFFileHeader>) -> FileHeader in

        FileHeader(type: FourCharacterCode(value: pointer.pointee.mFileType.bigEndian),
                   version: pointer.pointee.mFileVersion.bigEndian,
                   flags: pointer.pointee.mFileFlags.bigEndian)

      }

      guard type.stringValue == "caff" && version > 0 else { return nil }

    }

    public var description: String {
      return "FileHeader { type: '\(type.stringValue)'; version: \(version); flags: \(flags) }"
    }

  }

}

