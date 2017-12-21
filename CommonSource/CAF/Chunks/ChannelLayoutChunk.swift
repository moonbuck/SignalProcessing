//
//  ChannelLayoutChunk.swift
//  SignalProcessing
//
//  Created by Jason Cardwell on 12/20/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import AudioToolbox

private func _channelLayoutTagDescription(_ tag: AudioChannelLayoutTag) -> String {
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

private func _bitmapDescription(_ bitmap: AudioChannelBitmap) -> String {

  var parts: [String] = []

  if bitmap.contains(.bit_Center) { parts.append("Center") }
  if bitmap.contains(.bit_CenterSurround) { parts.append("CenterSurround") }
  if bitmap.contains(.bit_LFEScreen) { parts.append("LFEScreen") }
  if bitmap.contains(.bit_Left) { parts.append("Left") }
  if bitmap.contains(.bit_LeftCenter) { parts.append("LeftCenter") }
  if bitmap.contains(.bit_LeftSurround) { parts.append("LeftSurround") }
  if bitmap.contains(.bit_LeftSurroundDirect) { parts.append("LeftSurroundDirect") }
  if bitmap.contains(.bit_Right) { parts.append("Right") }
  if bitmap.contains(.bit_RightCenter) { parts.append("RightCenter") }
  if bitmap.contains(.bit_RightSurround) { parts.append("RightSurround") }
  if bitmap.contains(.bit_RightSurroundDirect) { parts.append("RightSurroundDirect") }
  if bitmap.contains(.bit_TopBackCenter) { parts.append("TopBackCenter") }
  if bitmap.contains(.bit_TopBackLeft) { parts.append("TopBackLeft") }
  if bitmap.contains(.bit_TopBackRight) { parts.append("TopBackRight") }
  if bitmap.contains(.bit_TopCenterSurround) { parts.append("TopCenterSurround") }
  if bitmap.contains(.bit_VerticalHeightCenter) { parts.append("VerticalHeightCenter") }
  if bitmap.contains(.bit_VerticalHeightLeft) { parts.append("VerticalHeightLeft") }
  if bitmap.contains(.bit_VerticalHeightRight) { parts.append("VerticalHeightRight") }

  return "(" + parts.joined(separator: "|") + ")"

}

extension CAFFile {

  public struct ChannelLayoutChunkData: CAFFileChunkData {

    public let layoutTag: AudioChannelLayoutTag
    public let bitmap: AudioChannelBitmap
    public let descriptions: [ChannelDescription]

    public init(layoutTag: AudioChannelLayoutTag,
                bitmap: AudioChannelBitmap,
                descriptions: [ChannelDescription])
    {
      self.layoutTag = layoutTag
      self.bitmap = bitmap
      self.descriptions = descriptions
    }

    public init?(data: Data) {

      guard data.count == MemoryLayout<AudioChannelLayout>.size else { return nil }

      let layoutTag = data[data.subrange(offset: 0, length: 4)].withUnsafeBytes {
        (pointer: UnsafePointer<UInt32>) -> UInt32 in pointer.pointee.bigEndian
      }

      let bitmap =
        AudioChannelBitmap(rawValue: data[data.subrange(offset: 4, length: 4)].withUnsafeBytes {
          (pointer: UnsafePointer<UInt32>) -> UInt32 in pointer.pointee.bigEndian
      })

      let numberChannelDescriptions = data[data.subrange(offset: 8, length: 4)].withUnsafeBytes {
        (pointer: UnsafePointer<UInt32>) -> Int in Int(pointer.pointee.bigEndian)
      }

      if numberChannelDescriptions == 0 {

        self.init(layoutTag: layoutTag, bitmap: bitmap, descriptions: [])

      } else {

        var descriptions: [ChannelDescription] = []
        descriptions.reserveCapacity(numberChannelDescriptions)

        let size = MemoryLayout<AudioChannelDescription>.size
        var start = 12

        while descriptions.count < numberChannelDescriptions {

          let description = data[data.subrange(start: start, length: size)].withUnsafeBytes({
            (pointer: UnsafePointer<AudioChannelDescription>) -> ChannelDescription in
            ChannelDescription(
              label: pointer.pointee.mChannelLabel.bigEndian,
              flags: AudioChannelFlags(rawValue: pointer.pointee.mChannelFlags.rawValue.bigEndian),
              coordinates: (
                Float32(bitPattern: pointer.pointee.mCoordinates.0.bitPattern.bigEndian),
                Float32(bitPattern: pointer.pointee.mCoordinates.1.bitPattern.bigEndian),
                Float32(bitPattern: pointer.pointee.mCoordinates.2.bitPattern.bigEndian)
              )
            )
          })

          descriptions.append(description)

          start += size

        }

        self.init(layoutTag: layoutTag, bitmap: bitmap, descriptions: descriptions)

      }

    }

    public var bitmapDescription: String { return _bitmapDescription(bitmap) }
    public var layoutTagDescription: String { return _channelLayoutTagDescription(layoutTag) }

    public var description: String {
      return """
        ChannelLayoutChunk { layoutTag: \(layoutTagDescription); \
        bitmap: \(bitmapDescription); descriptions: (\(descriptions.count) elements) }
        """
    }

  }

}

extension CAFFile.ChannelLayoutChunkData {

  public struct ChannelDescription: CustomStringConvertible {

    public let label: AudioChannelLabel
    public let flags: AudioChannelFlags
    public let coordinates: (Float, Float, Float)

    public init(label: AudioChannelLabel,
                flags: AudioChannelFlags,
                coordinates: (Float, Float, Float))
    {
      self.label = label
      self.flags = flags
      self.coordinates = coordinates
    }

    public var labelDescription: String { return _channelLabelDescription(label) }
    public var flagsDescription: String { return _channelFlagsDescription(flags) }

    public var description: String {
      return """
        ChannelDescription { label: \(labelDescription); \
        flags: \(_channelFlagsDescription); coordinates: (\
        \(coordinates.0), \(coordinates.1), \(coordinates.2)) }
        """
    }

  }


}

private func _channelFlagsDescription(_ flags: AudioChannelFlags) -> String {
  var parts: [String] = []
  if flags.contains(.meters) { parts.append("Meters") }
  if flags.contains(.rectangularCoordinates) { parts.append("Rectangular") }
  if flags.contains(.sphericalCoordinates) { parts.append("Spherical") }

  return "(" + parts.joined(separator: "|") + ")"
}

private func _channelLabelDescription(_ label: AudioChannelLabel) -> String {
  switch label {
    case kAudioChannelLabel_Unused:               return "Unused"
    case kAudioChannelLabel_UseCoordinates:       return "UseCoordinates"
    case kAudioChannelLabel_Left:                 return "Left"
    case kAudioChannelLabel_Right:                return "Right"
    case kAudioChannelLabel_Center:               return "Center"
    case kAudioChannelLabel_LFEScreen:            return "LFEScreen"
    case kAudioChannelLabel_LeftSurround:         return "LeftSurround"
    case kAudioChannelLabel_RightSurround:        return "RightSurround"
    case kAudioChannelLabel_LeftCenter:           return "LeftCenter"
    case kAudioChannelLabel_RightCenter:          return "RightCenter"
    case kAudioChannelLabel_CenterSurround:       return "CenterSurround"
    case kAudioChannelLabel_LeftSurroundDirect:   return "LeftSurroundDirect"
    case kAudioChannelLabel_RightSurroundDirect:  return "RightSurroundDirect"
    case kAudioChannelLabel_TopCenterSurround:    return "TopCenterSurround"
    case kAudioChannelLabel_VerticalHeightLeft:   return "VerticalHeightLeft"
    case kAudioChannelLabel_VerticalHeightCenter: return "VerticalHeightCenter"
    case kAudioChannelLabel_VerticalHeightRight:  return "VerticalHeightRight"
    case kAudioChannelLabel_TopBackLeft:          return "TopBackLeft"
    case kAudioChannelLabel_TopBackCenter:        return "TopBackCenter"
    case kAudioChannelLabel_TopBackRight:         return "TopBackRight"
    case kAudioChannelLabel_RearSurroundLeft:     return "RearSurroundLeft"
    case kAudioChannelLabel_RearSurroundRight:    return "RearSurroundRight"
    case kAudioChannelLabel_LeftWide:             return "LeftWide"
    case kAudioChannelLabel_RightWide:            return "RightWide"
    case kAudioChannelLabel_LFE2:                 return "LFE2"
    case kAudioChannelLabel_LeftTotal:            return "LeftTotal"
    case kAudioChannelLabel_RightTotal:           return "RightTotal"
    case kAudioChannelLabel_HearingImpaired:      return "HearingImpaired"
    case kAudioChannelLabel_Narration:            return "Narration"
    case kAudioChannelLabel_Mono:                 return "Mono"
    case kAudioChannelLabel_DialogCentricMix:     return "DialogCentricMix"
    case kAudioChannelLabel_CenterSurroundDirect: return "CenterSurroundDirect"
    case kAudioChannelLabel_Haptic:               return "Haptic"
    case kAudioChannelLabel_Ambisonic_W:          return "Ambisonic_W"
    case kAudioChannelLabel_Ambisonic_X:          return "Ambisonic_X"
    case kAudioChannelLabel_Ambisonic_Y:          return "Ambisonic_Y"
    case kAudioChannelLabel_Ambisonic_Z:          return "Ambisonic_Z"
    case kAudioChannelLabel_MS_Mid:               return "MS_Mid"
    case kAudioChannelLabel_MS_Side:              return "MS_Side"
    case kAudioChannelLabel_XY_X:                 return "XY_X"
    case kAudioChannelLabel_XY_Y:                 return "XY_Y"
    case kAudioChannelLabel_HeadphonesLeft:       return "HeadphonesLeft"
    case kAudioChannelLabel_HeadphonesRight:      return "HeadphonesRight"
    case kAudioChannelLabel_ClickTrack:           return "ClickTrack"
    case kAudioChannelLabel_ForeignLanguage:      return "ForeignLanguage"
    case kAudioChannelLabel_Discrete:             return "Discrete"
    case kAudioChannelLabel_Discrete_0:           return "Discrete_0"
    case kAudioChannelLabel_Discrete_1:           return "Discrete_1"
    case kAudioChannelLabel_Discrete_2:           return "Discrete_2"
    case kAudioChannelLabel_Discrete_3:           return "Discrete_3"
    case kAudioChannelLabel_Discrete_4:           return "Discrete_4"
    case kAudioChannelLabel_Discrete_5:           return "Discrete_5"
    case kAudioChannelLabel_Discrete_6:           return "Discrete_6"
    case kAudioChannelLabel_Discrete_7:           return "Discrete_7"
    case kAudioChannelLabel_Discrete_8:           return "Discrete_8"
    case kAudioChannelLabel_Discrete_9:           return "Discrete_9"
    case kAudioChannelLabel_Discrete_10:          return "Discrete_10"
    case kAudioChannelLabel_Discrete_11:          return "Discrete_11"
    case kAudioChannelLabel_Discrete_12:          return "Discrete_12"
    case kAudioChannelLabel_Discrete_13:          return "Discrete_13"
    case kAudioChannelLabel_Discrete_14:          return "Discrete_14"
    case kAudioChannelLabel_Discrete_15:          return "Discrete_15"
    case kAudioChannelLabel_Discrete_65535:       return "Discrete_65535"
    case kAudioChannelLabel_HOA_ACN:              return "HOA_ACN"
    case kAudioChannelLabel_HOA_ACN_0:            return "HOA_ACN_0"
    case kAudioChannelLabel_HOA_ACN_1:            return "HOA_ACN_1"
    case kAudioChannelLabel_HOA_ACN_2:            return "HOA_ACN_2"
    case kAudioChannelLabel_HOA_ACN_3:            return "HOA_ACN_3"
    case kAudioChannelLabel_HOA_ACN_4:            return "HOA_ACN_4"
    case kAudioChannelLabel_HOA_ACN_5:            return "HOA_ACN_5"
    case kAudioChannelLabel_HOA_ACN_6:            return "HOA_ACN_6"
    case kAudioChannelLabel_HOA_ACN_7:            return "HOA_ACN_7"
    case kAudioChannelLabel_HOA_ACN_8:            return "HOA_ACN_8"
    case kAudioChannelLabel_HOA_ACN_9:            return "HOA_ACN_9"
    case kAudioChannelLabel_HOA_ACN_10:           return "HOA_ACN_10"
    case kAudioChannelLabel_HOA_ACN_11:           return "HOA_ACN_11"
    case kAudioChannelLabel_HOA_ACN_12:           return "HOA_ACN_12"
    case kAudioChannelLabel_HOA_ACN_13:           return "HOA_ACN_13"
    case kAudioChannelLabel_HOA_ACN_14:           return "HOA_ACN_14"
    case kAudioChannelLabel_HOA_ACN_15:           return "HOA_ACN_15"
    case kAudioChannelLabel_HOA_ACN_65024:        return "HOA_ACN_65024"
    default:                                      return "Unknown"
  }
}
