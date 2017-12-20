//
//  CAFFileExtensions.swift
//  caf_info
//
//  Created by Jason Cardwell on 12/19/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import AudioToolbox

extension CAFFileHeader {

  public init?(data: Data) {

    guard data.count == MemoryLayout<CAFFileHeader>.size else { return nil }

    self = data.withUnsafeBytes {
      (pointer: UnsafePointer<CAFFileHeader>) -> CAFFileHeader in

      CAFFileHeader(mFileType: pointer.pointee.mFileType.bigEndian,
                    mFileVersion: pointer.pointee.mFileVersion.bigEndian,
                    mFileFlags: pointer.pointee.mFileFlags.bigEndian)

    }

  }

}

extension CAFFileHeader: CustomStringConvertible {

  public var description: String {
    return """
    FileHeader {
      type: '\(String(mFileType.bytes))'
      version: \(mFileVersion)
      flags: \(mFileFlags)
    }
    """
  }

}

extension CAFChunkHeader {

  public init?(data: Data) {

    guard data.count == MemoryLayout<CAFChunkHeader>.size else { return nil }

    self = data.withUnsafeBytes {
      (pointer: UnsafePointer<CAFChunkHeader>) -> CAFChunkHeader in

      CAFChunkHeader(mChunkType: pointer.pointee.mChunkType.bigEndian,
                     mChunkSize: pointer.pointee.mChunkSize.bigEndian)

    }

  }

}

extension CAFChunkHeader: CustomStringConvertible {

  public var description: String {
    return "ChunkHeader { type: '\(String(mChunkType.bytes))'; size: \(mChunkSize) }"
  }

}

extension CAFFormatFlags: CustomStringConvertible {

  public var description: String {
    return """
    formatFlags { isFloat: \(contains(.linearPCMFormatFlagIsFloat)); \
    isLittleEndian: \(contains(.linearPCMFormatFlagIsLittleEndian)) }
    """
  }

}

extension CAFAudioDescription {

  public init?(data: Data) {

    guard data.count == MemoryLayout<CAFAudioDescription>.size else { return nil }

    self = data.withUnsafeBytes {
      (pointer: UnsafePointer<CAFAudioDescription>) -> CAFAudioDescription in

      CAFAudioDescription(
        mSampleRate: Float64(bitPattern: pointer.pointee.mSampleRate.bitPattern.bigEndian),
        mFormatID: pointer.pointee.mFormatID.bigEndian,
        mFormatFlags: CAFFormatFlags(rawValue: pointer.pointee.mFormatFlags.rawValue.bigEndian),
        mBytesPerPacket: pointer.pointee.mBytesPerPacket.bigEndian,
        mFramesPerPacket: pointer.pointee.mFramesPerPacket.bigEndian,
        mChannelsPerFrame: pointer.pointee.mChannelsPerFrame.bigEndian,
        mBitsPerChannel: pointer.pointee.mBitsPerChannel.bigEndian
      )
    }

  }


}

extension CAFAudioDescription: CustomStringConvertible {

  public var description: String {
    return """
    AudioDescription {
      sampleRate: \(mSampleRate)
      formatID: '\(String(mFormatID.bytes))'
      formatFlags: \(mFormatFlags)
      bytesPerPacket: \(mBytesPerPacket)
      framesPerPacket: \(mFramesPerPacket)
      channelsPerFrame: \(mChannelsPerFrame)
      bitsPerChannel: \(mBitsPerChannel)
    }
    """
  }

}

extension AudioChannelLayout {

  public init?(data: Data) {

    guard data.count == MemoryLayout<AudioChannelLayout>.size else { return nil }

    let channelLayoutTag = data[0 ..< 4].withUnsafeBytes {
      (pointer: UnsafePointer<UInt32>) -> UInt32 in pointer.pointee.bigEndian
    }

    let channelBitmap = AudioChannelBitmap(rawValue: data[4 ..< 8].withUnsafeBytes {
      (pointer: UnsafePointer<UInt32>) -> UInt32 in pointer.pointee.bigEndian
    })

    let numberChannelDescriptions = data[8 ..< 12].withUnsafeBytes {
      (pointer: UnsafePointer<UInt32>) -> UInt32 in pointer.pointee.bigEndian
    }

    if numberChannelDescriptions == 0 {
      self.init()
      mChannelLayoutTag = channelLayoutTag
      mChannelBitmap = channelBitmap
      mNumberChannelDescriptions = numberChannelDescriptions
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

      self.init()
      mChannelLayoutTag = channelLayoutTag
      mChannelBitmap = channelBitmap
      mNumberChannelDescriptions = numberChannelDescriptions

      print("Create descriptions I do not know how to set: \(descriptions)")

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

extension AudioChannelLayout: CustomStringConvertible {

  public var description: String {
    var result = """
      ChannelLayout {
        layoutTag: \(channelLayoutTagDescription(mChannelLayoutTag))
        channelBitmap: \(mChannelBitmap)
        numberChannelDescriptions: \(mNumberChannelDescriptions)
      }
      """
    guard mNumberChannelDescriptions > 0 else { return result }

    var mutableSelf = self
    let descriptions = UnsafeBufferPointer(start: &mutableSelf.mChannelDescriptions,
                                           count: Int(mNumberChannelDescriptions))

    result += "channelDescriptions:\n"

    for description in descriptions { result += "  \(description)\n" }

    return result

  }

}

extension AudioChannelDescription {

  public init?(data: Data) {

    guard data.count == MemoryLayout<AudioChannelDescription>.size else { return nil }

    self = data.withUnsafeBytes({
      (pointer: UnsafePointer<AudioChannelDescription>) -> AudioChannelDescription in
      AudioChannelDescription(
        mChannelLabel: pointer.pointee.mChannelLabel.bigEndian,
        mChannelFlags: AudioChannelFlags(rawValue:
                                          pointer.pointee.mChannelFlags.rawValue.bigEndian),
        mCoordinates: (
          Float32(bitPattern: pointer.pointee.mCoordinates.0.bitPattern.bigEndian),
          Float32(bitPattern: pointer.pointee.mCoordinates.1.bitPattern.bigEndian),
          Float32(bitPattern: pointer.pointee.mCoordinates.2.bitPattern.bigEndian)
        )
      )
    })

  }

}

extension AudioChannelDescription: CustomStringConvertible {

  public var description: String {
    return [
      "{label: \(mChannelLabel)",
      "flags: \(mChannelFlags)",
      "coordinates: (\(mCoordinates.0), \(mCoordinates.1) \(mCoordinates.2))}"
      ].joined(separator: "; ")

  }

}

extension AudioChannelBitmap: CustomStringConvertible {

  public var description: String {

    var parts: [String] = []

    if contains(.bit_Center) { parts.append("Center") }
    if contains(.bit_CenterSurround) { parts.append("CenterSurround") }
    if contains(.bit_LFEScreen) { parts.append("LFEScreen") }
    if contains(.bit_Left) { parts.append("Left") }
    if contains(.bit_LeftCenter) { parts.append("LeftCenter") }
    if contains(.bit_LeftSurround) { parts.append("LeftSurround") }
    if contains(.bit_LeftSurroundDirect) { parts.append("LeftSurroundDirect") }
    if contains(.bit_Right) { parts.append("Right") }
    if contains(.bit_RightCenter) { parts.append("RightCenter") }
    if contains(.bit_RightSurround) { parts.append("RightSurround") }
    if contains(.bit_RightSurroundDirect) { parts.append("RightSurroundDirect") }
    if contains(.bit_TopBackCenter) { parts.append("TopBackCenter") }
    if contains(.bit_TopBackLeft) { parts.append("TopBackLeft") }
    if contains(.bit_TopBackRight) { parts.append("TopBackRight") }
    if contains(.bit_TopCenterSurround) { parts.append("TopCenterSurround") }
    if contains(.bit_VerticalHeightCenter) { parts.append("VerticalHeightCenter") }
    if contains(.bit_VerticalHeightLeft) { parts.append("VerticalHeightLeft") }
    if contains(.bit_VerticalHeightRight) { parts.append("VerticalHeightRight") }

    return "(" + parts.joined(separator: "|") + ")"
    
  }

}
