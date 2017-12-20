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

public struct CAFFile {



}


extension CAFFile {

  public struct FileHeader: CustomStringConvertible {

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

    }

    public var description: String {
      return "FileHeader { type: '\(type.stringValue)'; version: \(version); flags: \(flags) }"
    }

  }

}

extension CAFFile {

  public struct ChunkHeader: CustomStringConvertible {

    public let type: FourCharacterCode
    public let size: Int64

    public init(type: FourCharacterCode, size: Int64) { self.type = type; self.size = size }

    public init?(data: Data) {

      guard data.count == MemoryLayout<CAFChunkHeader>.size else { return nil }

      self = data.withUnsafeBytes {
        (pointer: UnsafePointer<CAFChunkHeader>) -> ChunkHeader in

        ChunkHeader(type: FourCharacterCode(value: pointer.pointee.mChunkType.bigEndian),
                    size: pointer.pointee.mChunkSize.bigEndian)

      }

    }

    public var description: String {
      return "ChunkHeader { type: '\(type.stringValue)'; size: \(size) bytes }"
    }

  }

}

extension CAFFile {

  public struct LinearPCMFormatFlags: CustomStringConvertible {

    public var isFloat: Bool
    public var isLittleEndian: Bool

    public init(flags: CAFFormatFlags) {
      isFloat = flags.contains(.linearPCMFormatFlagIsFloat)
      isLittleEndian = flags.contains(.linearPCMFormatFlagIsLittleEndian)
    }

    public init(isFloat: Bool, isLittleEndian: Bool) {
      self.isFloat = isFloat
      self.isLittleEndian = isLittleEndian
    }

    public var description: String {
      return "LinearPCMFormatFlags { isFloat: \(isFloat); isLittleEndian: \(isLittleEndian) }"
    }

  }

}

extension CAFFile {

  public struct AudioDescriptionChunk: CustomStringConvertible {

    public let sampleRate: Float64
    public let formatID: FourCharacterCode
    public let formatFlags: LinearPCMFormatFlags
    public let bytesPerPacket: UInt32
    public let framesPerPacket: UInt32
    public let channelsPerFrame: UInt32
    public let bitsPerChannel: UInt32

    public init(sampleRate: Float64,
                formatID: FourCharacterCode,
                formatFlags: LinearPCMFormatFlags,
                bytesPerPacket: UInt32,
                framesPerPacket: UInt32,
                channelsPerFrame: UInt32,
                bitsPerChannel: UInt32)
    {
      self.sampleRate = sampleRate
      self.formatID = formatID
      self.formatFlags = formatFlags
      self.bytesPerPacket = bytesPerPacket
      self.framesPerPacket = framesPerPacket
      self.channelsPerFrame = channelsPerFrame
      self.bitsPerChannel = bitsPerChannel
    }

    public init?(data: Data) {

      guard data.count == MemoryLayout<CAFAudioDescription>.size else { return nil }

      self = data.withUnsafeBytes {
        (pointer: UnsafePointer<CAFAudioDescription>) -> AudioDescriptionChunk in

        let formatFlags = CAFFormatFlags(rawValue: pointer.pointee.mFormatFlags.rawValue.bigEndian)

        return AudioDescriptionChunk(
          sampleRate: Float64(bitPattern: pointer.pointee.mSampleRate.bitPattern.bigEndian),
          formatID: FourCharacterCode(value: pointer.pointee.mFormatID.bigEndian),
          formatFlags: LinearPCMFormatFlags(flags: formatFlags),
          bytesPerPacket: pointer.pointee.mBytesPerPacket.bigEndian,
          framesPerPacket: pointer.pointee.mFramesPerPacket.bigEndian,
          channelsPerFrame: pointer.pointee.mChannelsPerFrame.bigEndian,
          bitsPerChannel: pointer.pointee.mBitsPerChannel.bigEndian
        )
      }

    }

    public var description: String {
      return """
        AudioDescriptionChunk {
          sampleRate: \(sampleRate)
          formatID: '\(formatID.stringValue)'
          formatFlags: \(formatFlags)
          bytesPerPacket: \(bytesPerPacket)
          framesPerPacket: \(framesPerPacket)
          channelsPerFrame: \(channelsPerFrame)
          bitsPerChannel: \(bitsPerChannel)
        }
        """
    }

  }

}

private func channelLayoutTagDescription(_ tag: AudioChannelLayoutTag) -> String {
  switch tag {
      case kAudioChannelLayoutTag_UseChannelDescriptions: return "UseChannelDescriptions"
      case kAudioChannelLayoutTag_UseChannelBitmap: return "UseChannelBitmap"
      case kAudioChannelLayoutTag_Mono: return "Mono"
      case kAudioChannelLayoutTag_Stereo: return "Stereo"
      case kAudioChannelLayoutTag_StereoHeadphones: return "StereoHeadphones"
      case kAudioChannelLayoutTag_MatrixStereo: return "MatrixStereo"
      case kAudioChannelLayoutTag_MidSide: return "MidSide"
      case kAudioChannelLayoutTag_XY: return "XY"
      case kAudioChannelLayoutTag_Binaural: return "Binaural"
      case kAudioChannelLayoutTag_Ambisonic_B_Format: return "Ambisonic_B_Format"
      case kAudioChannelLayoutTag_Quadraphonic: return "Quadraphonic"
      case kAudioChannelLayoutTag_Pentagonal: return "Pentagonal"
      case kAudioChannelLayoutTag_Hexagonal: return "Hexagonal"
      case kAudioChannelLayoutTag_Octagonal: return "Octagonal"
      case kAudioChannelLayoutTag_Cube: return "Cube"
      case kAudioChannelLayoutTag_MPEG_1_0: return "MPEG_1_0"
      case kAudioChannelLayoutTag_MPEG_2_0: return "MPEG_2_0"
      case kAudioChannelLayoutTag_MPEG_3_0_A: return "MPEG_3_0_A"
      case kAudioChannelLayoutTag_MPEG_3_0_B: return "MPEG_3_0_B"
      case kAudioChannelLayoutTag_MPEG_4_0_A: return "MPEG_4_0_A"
      case kAudioChannelLayoutTag_MPEG_4_0_B: return "MPEG_4_0_B"
      case kAudioChannelLayoutTag_MPEG_5_0_A: return "MPEG_5_0_A"
      case kAudioChannelLayoutTag_MPEG_5_0_B: return "MPEG_5_0_B"
      case kAudioChannelLayoutTag_MPEG_5_0_C: return "MPEG_5_0_C"
      case kAudioChannelLayoutTag_MPEG_5_0_D: return "MPEG_5_0_D"
      case kAudioChannelLayoutTag_MPEG_5_1_A: return "MPEG_5_1_A"
      case kAudioChannelLayoutTag_MPEG_5_1_B: return "MPEG_5_1_B"
      case kAudioChannelLayoutTag_MPEG_5_1_C: return "MPEG_5_1_C"
      case kAudioChannelLayoutTag_MPEG_5_1_D: return "MPEG_5_1_D"
      case kAudioChannelLayoutTag_MPEG_6_1_A: return "MPEG_6_1_A"
      case kAudioChannelLayoutTag_MPEG_7_1_A: return "MPEG_7_1_A"
      case kAudioChannelLayoutTag_MPEG_7_1_B: return "MPEG_7_1_B"
      case kAudioChannelLayoutTag_MPEG_7_1_C: return "MPEG_7_1_C"
      case kAudioChannelLayoutTag_Emagic_Default_7_1: return "Emagic_Default_7_1"
      case kAudioChannelLayoutTag_SMPTE_DTV: return "SMPTE_DTV"
      case kAudioChannelLayoutTag_ITU_1_0: return "ITU_1_0"
      case kAudioChannelLayoutTag_ITU_2_0: return "ITU_2_0"
      case kAudioChannelLayoutTag_ITU_2_1: return "ITU_2_1"
      case kAudioChannelLayoutTag_ITU_2_2: return "ITU_2_2"
      case kAudioChannelLayoutTag_ITU_3_0: return "ITU_3_0"
      case kAudioChannelLayoutTag_ITU_3_1: return "ITU_3_1"
      case kAudioChannelLayoutTag_ITU_3_2: return "ITU_3_2"
      case kAudioChannelLayoutTag_ITU_3_2_1: return "ITU_3_2_1"
      case kAudioChannelLayoutTag_ITU_3_4_1: return "ITU_3_4_1"
      case kAudioChannelLayoutTag_DVD_0: return "DVD_0"
      case kAudioChannelLayoutTag_DVD_1: return "DVD_1"
      case kAudioChannelLayoutTag_DVD_2: return "DVD_2"
      case kAudioChannelLayoutTag_DVD_3: return "DVD_3"
      case kAudioChannelLayoutTag_DVD_4: return "DVD_4"
      case kAudioChannelLayoutTag_DVD_5: return "DVD_5"
      case kAudioChannelLayoutTag_DVD_6: return "DVD_6"
      case kAudioChannelLayoutTag_DVD_7: return "DVD_7"
      case kAudioChannelLayoutTag_DVD_8: return "DVD_8"
      case kAudioChannelLayoutTag_DVD_9: return "DVD_9"
      case kAudioChannelLayoutTag_DVD_10: return "DVD_10"
      case kAudioChannelLayoutTag_DVD_11: return "DVD_11"
      case kAudioChannelLayoutTag_DVD_12: return "DVD_12"
      case kAudioChannelLayoutTag_DVD_13: return "DVD_13"
      case kAudioChannelLayoutTag_DVD_14: return "DVD_14"
      case kAudioChannelLayoutTag_DVD_15: return "DVD_15"
      case kAudioChannelLayoutTag_DVD_16: return "DVD_16"
      case kAudioChannelLayoutTag_DVD_17: return "DVD_17"
      case kAudioChannelLayoutTag_DVD_18: return "DVD_18"
      case kAudioChannelLayoutTag_DVD_19: return "DVD_19"
      case kAudioChannelLayoutTag_DVD_20: return "DVD_20"
      case kAudioChannelLayoutTag_AudioUnit_4: return "AudioUnit_4"
      case kAudioChannelLayoutTag_AudioUnit_5: return "AudioUnit_5"
      case kAudioChannelLayoutTag_AudioUnit_6: return "AudioUnit_6"
      case kAudioChannelLayoutTag_AudioUnit_8: return "AudioUnit_8"
      case kAudioChannelLayoutTag_AudioUnit_5_0: return "AudioUnit_5_0"
      case kAudioChannelLayoutTag_AudioUnit_6_0: return "AudioUnit_6_0"
      case kAudioChannelLayoutTag_AudioUnit_7_0: return "AudioUnit_7_0"
      case kAudioChannelLayoutTag_AudioUnit_7_0_Front: return "AudioUnit_7_0_Front"
      case kAudioChannelLayoutTag_AudioUnit_5_1: return "AudioUnit_5_1"
      case kAudioChannelLayoutTag_AudioUnit_6_1: return "AudioUnit_6_1"
      case kAudioChannelLayoutTag_AudioUnit_7_1: return "AudioUnit_7_1"
      case kAudioChannelLayoutTag_AudioUnit_7_1_Front: return "AudioUnit_7_1_Front"
      case kAudioChannelLayoutTag_AAC_3_0: return "AAC_3_0"
      case kAudioChannelLayoutTag_AAC_Quadraphonic: return "AAC_Quadraphonic"
      case kAudioChannelLayoutTag_AAC_4_0: return "AAC_4_0"
      case kAudioChannelLayoutTag_AAC_5_0: return "AAC_5_0"
      case kAudioChannelLayoutTag_AAC_5_1: return "AAC_5_1"
      case kAudioChannelLayoutTag_AAC_6_0: return "AAC_6_0"
      case kAudioChannelLayoutTag_AAC_6_1: return "AAC_6_1"
      case kAudioChannelLayoutTag_AAC_7_0: return "AAC_7_0"
      case kAudioChannelLayoutTag_AAC_7_1: return "AAC_7_1"
      case kAudioChannelLayoutTag_AAC_7_1_B: return "AAC_7_1_B"
      case kAudioChannelLayoutTag_AAC_7_1_C: return "AAC_7_1_C"
      case kAudioChannelLayoutTag_AAC_Octagonal: return "AAC_Octagonal"
      case kAudioChannelLayoutTag_TMH_10_2_std: return "TMH_10_2_std"
      case kAudioChannelLayoutTag_TMH_10_2_full: return "TMH_10_2_full"
      case kAudioChannelLayoutTag_AC3_1_0_1: return "AC3_1_0_1"
      case kAudioChannelLayoutTag_AC3_3_0: return "AC3_3_0"
      case kAudioChannelLayoutTag_AC3_3_1: return "AC3_3_1"
      case kAudioChannelLayoutTag_AC3_3_0_1: return "AC3_3_0_1"
      case kAudioChannelLayoutTag_AC3_2_1_1: return "AC3_2_1_1"
      case kAudioChannelLayoutTag_AC3_3_1_1: return "AC3_3_1_1"
      case kAudioChannelLayoutTag_EAC_6_0_A: return "EAC_6_0_A"
      case kAudioChannelLayoutTag_EAC_7_0_A: return "EAC_7_0_A"
      case kAudioChannelLayoutTag_EAC3_6_1_A: return "EAC3_6_1_A"
      case kAudioChannelLayoutTag_EAC3_6_1_B: return "EAC3_6_1_B"
      case kAudioChannelLayoutTag_EAC3_6_1_C: return "EAC3_6_1_C"
      case kAudioChannelLayoutTag_EAC3_7_1_A: return "EAC3_7_1_A"
      case kAudioChannelLayoutTag_EAC3_7_1_B: return "EAC3_7_1_B"
      case kAudioChannelLayoutTag_EAC3_7_1_C: return "EAC3_7_1_C"
      case kAudioChannelLayoutTag_EAC3_7_1_D: return "EAC3_7_1_D"
      case kAudioChannelLayoutTag_EAC3_7_1_E: return "EAC3_7_1_E"
      case kAudioChannelLayoutTag_EAC3_7_1_F: return "EAC3_7_1_F"
      case kAudioChannelLayoutTag_EAC3_7_1_G: return "EAC3_7_1_G"
      case kAudioChannelLayoutTag_EAC3_7_1_H: return "EAC3_7_1_H"
      case kAudioChannelLayoutTag_DTS_3_1: return "DTS_3_1"
      case kAudioChannelLayoutTag_DTS_4_1: return "DTS_4_1"
      case kAudioChannelLayoutTag_DTS_6_0_A: return "DTS_6_0_A"
      case kAudioChannelLayoutTag_DTS_6_0_B: return "DTS_6_0_B"
      case kAudioChannelLayoutTag_DTS_6_0_C: return "DTS_6_0_C"
      case kAudioChannelLayoutTag_DTS_6_1_A: return "DTS_6_1_A"
      case kAudioChannelLayoutTag_DTS_6_1_B: return "DTS_6_1_B"
      case kAudioChannelLayoutTag_DTS_6_1_C: return "DTS_6_1_C"
      case kAudioChannelLayoutTag_DTS_7_0: return "DTS_7_0"
      case kAudioChannelLayoutTag_DTS_7_1: return "DTS_7_1"
      case kAudioChannelLayoutTag_DTS_8_0_A: return "DTS_8_0_A"
      case kAudioChannelLayoutTag_DTS_8_0_B: return "DTS_8_0_B"
      case kAudioChannelLayoutTag_DTS_8_1_A: return "DTS_8_1_A"
      case kAudioChannelLayoutTag_DTS_8_1_B: return "DTS_8_1_B"
      case kAudioChannelLayoutTag_DTS_6_1_D: return "DTS_6_1_D"
      case kAudioChannelLayoutTag_HOA_ACN_SN3D: return "HOA_ACN_SN3D"
      case kAudioChannelLayoutTag_HOA_ACN_N3D: return "HOA_ACN_N3D"
      case kAudioChannelLayoutTag_DiscreteInOrder: return "DiscreteInOrder"
      default: return "Unknown"
  }

}

extension CAFFile {

  public struct ChannelLayoutChunk: CustomStringConvertible {

    public let layoutTag: AudioChannelLayoutTag
    public let bitmap: AudioChannelBitmap
    public let descriptions: [AudioChannelDescription]

    public init(layoutTag: AudioChannelLayoutTag,
                bitmap: AudioChannelBitmap,
                descriptions: [AudioChannelDescription])
    {
      self.layoutTag = layoutTag
      self.bitmap = bitmap
      self.descriptions = descriptions
    }

    public init?(data: Data) {

      guard data.count == MemoryLayout<AudioChannelLayout>.size else { return nil }

      let layoutTag = data[0 ..< 4].withUnsafeBytes {
        (pointer: UnsafePointer<UInt32>) -> UInt32 in pointer.pointee.bigEndian
      }

      let bitmap = AudioChannelBitmap(rawValue: data[4 ..< 8].withUnsafeBytes {
        (pointer: UnsafePointer<UInt32>) -> UInt32 in pointer.pointee.bigEndian
      })

      let numberChannelDescriptions = data[8 ..< 12].withUnsafeBytes {
        (pointer: UnsafePointer<UInt32>) -> UInt32 in pointer.pointee.bigEndian
      }

      if numberChannelDescriptions == 0 {

        self.init(layoutTag: layoutTag, bitmap: bitmap, descriptions: [])

      } else {

        var remaining = numberChannelDescriptions
        let size = MemoryLayout<AudioChannelDescription>.size

        var descriptions: [AudioChannelDescription] = []
        var offset = 12
        while remaining > 0 {

          let descriptionData = data.subdata(in: offset ..< (offset + size))

          guard let description = AudioChannelDescription(data: descriptionData) else {
            return nil
          }

          descriptions.append(description)

          remaining -= 1
          offset += size

        }

        self.init(layoutTag: layoutTag, bitmap: bitmap, descriptions: descriptions)

      }

    }

    public var description: String {
      return """
        ChannelLayoutChunk { layoutTag: \(channelLayoutTagDescription(layoutTag)); \
        bitmap: \(bitmap); descriptions: (\(descriptions.count) elements) }
        """
    }

  }

}

extension CAFFile {

  public struct FreeChunk: CustomStringConvertible {
    public let size: Int64
    public init(size: Int64) { self.size = size }
    public var description: String { return "FreeChunk { size: \(size) bytes }" }
  }

}

extension CAFFile {

  public struct OverviewChunk: CustomStringConvertible {

    public var description: String {
      return "OverviewChunk { ??? } "
    }

    public init?(data: Data) {

    }

  }


}

extension CAFFile {

  public struct DataChunk: CustomStringConvertible {
    public let size: Int64
    public init(size: Int64) { self.size = size }
    public var description: String { return "DataChunk { size: \(size) bytes }" }
  }

}

extension CAFFile {

  public struct MarkerChunk: CustomStringConvertible {

    public var description: String {
      return "MarkerChunk { ??? } "
    }

    public init?(data: Data) {

    }

  }


}

extension CAFFile {

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

extension CAFFile {

  public struct StringsChunk: CustomStringConvertible {

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
      return "StringsChunk { ids: (\(ids.count) elements); strings: (\(strings.count) elements) }"
    }

    public init?(data: Data) {

      guard data.count >= 4 else { return nil }

      let numEntries = data[0..<4].withUnsafeBytes {
        (pointer: UnsafePointer<UInt32>) -> Int in Int(pointer.pointee.bigEndian)
      }

      guard data.count >= MemoryLayout<StringID>.size * numEntries + 4 else { return nil }

      var ids: [StringID] = []

      ids.reserveCapacity(numEntries)

      var start = 4

      while ids.count < numEntries {

        let id = data[start..<(start + 4)].withUnsafeBytes {
          (pointer: UnsafePointer<UInt32>) -> UInt32 in pointer.pointee.bigEndian
        }

        start += 4

        let startByteOffset = data[start..<(start + 8)].withUnsafeBytes {
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

