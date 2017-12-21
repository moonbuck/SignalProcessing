//
//  MarkerChunk.swift
//  SignalProcessing
//
//  Created by Jason Cardwell on 12/20/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import AudioToolbox

private func _timeDescription(_ time: CAF_SMPTE_Time?) -> String {
  guard let time = time else { return "nil" }
  return """
    \(time.mHours):\(time.mMinutes):\(time.mSeconds):\(time.mFrames).\(time.mSubFrameSampleOffset)
    """
}

private func _typeDescription(_ type: UInt32) -> String {

  switch type {
    case kCAFMarkerType_ProgramStart:         return "ProgramStart"
    case kCAFMarkerType_ProgramEnd:           return "ProgramEnd"
    case kCAFMarkerType_TrackStart:           return "TrackStart"
    case kCAFMarkerType_TrackEnd:             return "TrackEnd"
    case kCAFMarkerType_Index:                return "Index"
    case kCAFMarkerType_RegionStart:          return "RegionStart"
    case kCAFMarkerType_RegionEnd:            return "RegionEnd"
    case kCAFMarkerType_RegionSyncPoint:      return "RegionSyncPoint"
    case kCAFMarkerType_SelectionStart:       return "SelectionStart"
    case kCAFMarkerType_SelectionEnd:         return "SelectionEnd"
    case kCAFMarkerType_EditSourceBegin:      return "EditSourceBegin"
    case kCAFMarkerType_EditSourceEnd:        return "EditSourceEnd"
    case kCAFMarkerType_EditDestinationBegin: return "EditDestinationBegin"
    case kCAFMarkerType_EditDestinationEnd:   return "EditDestinationEnd"
    case kCAFMarkerType_SustainLoopStart:     return "SustainLoopStart"
    case kCAFMarkerType_SustainLoopEnd:       return "SustainLoopEnd"
    case kCAFMarkerType_ReleaseLoopStart:     return "ReleaseLoopStart"
    case kCAFMarkerType_ReleaseLoopEnd:       return "ReleaseLoopEnd"
    case kCAFMarkerType_SavedPlayPosition:    return "SavedPlayPosition"
    case kCAFMarkerType_Tempo:                return "Tempo"
    case kCAFMarkerType_TimeSignature:        return "TimeSignature"
    case kCAFMarkerType_KeySignature:         return "KeySignature"
    default:                                  return "Generic"

  }

}

extension CAFFile {

  public struct Marker: CustomStringConvertible {

    public let type: UInt32
    public let framePosition: Float64
    public let id: UInt32
    public let time: CAF_SMPTE_Time?
    public let channel: UInt32

    public init(type: UInt32,
                framePosition: Float64,
                id: UInt32,
                time: CAF_SMPTE_Time?,
                channel: UInt32)
    {
      self.type = type
      self.framePosition = framePosition
      self.id = id
      self.time = time
      self.channel = channel
    }

    public var typeDescription: String { return _typeDescription(type) }
    public var timeDescription: String { return _timeDescription(time)}
    public var description: String {
      return """
        Marker { type: \(typeDescription); framePosition: \(framePosition); id: \(id); \
        time: \(timeDescription); channel: \(channel) }
        """
    }

  }

}

private func _timeTypeDescription(_ timeType: UInt32) -> String {

  switch timeType {
    case kCAF_SMPTE_TimeType24:       return "24"
    case kCAF_SMPTE_TimeType25:       return "25"
    case kCAF_SMPTE_TimeType30Drop:   return "30Drop"
    case kCAF_SMPTE_TimeType30:       return "30"
    case kCAF_SMPTE_TimeType2997:     return "2997"
    case kCAF_SMPTE_TimeType2997Drop: return "2997Drop"
    case kCAF_SMPTE_TimeType60:       return "60"
    case kCAF_SMPTE_TimeType5994:     return "5994"
    case kCAF_SMPTE_TimeType60Drop:   return "60Drop"
    case kCAF_SMPTE_TimeType5994Drop: return "5994Drop"
    case kCAF_SMPTE_TimeType50:       return "50"
    case kCAF_SMPTE_TimeType2398:     return "2398"
    default:                          return "None"
  }

}

extension CAFFile {

  public struct MarkerChunkData: CAFFileChunkData {

    public let timeType: UInt32

    public let markers: [Marker]

    public init(timeType: UInt32, markers: [Marker]) {
      self.timeType = timeType
      self.markers = markers
    }

    public init?(data: Data) {

      guard data.count >= 8 else { return nil }

      timeType = data[data.subrange(offset: 0, length: 4)].withUnsafeBytes {
        (pointer: UnsafePointer<UInt32>) -> UInt32 in pointer.pointee.bigEndian
      }

      let markerCount = data[data.subrange(offset: 4, length: 4)].withUnsafeBytes {
        (pointer: UnsafePointer<UInt32>) -> Int in Int(pointer.pointee.bigEndian)
      }

      guard data.count - 8 == MemoryLayout<CAFMarker>.size * markerCount else { return nil }

      var markers: [Marker] = []
      markers.reserveCapacity(markerCount)

      var start = 8

      while markers.count < markerCount {

        let type = data[data.subrange(start: start, length: 4)].withUnsafeBytes {
          (pointer: UnsafePointer<UInt32>) -> UInt32 in pointer.pointee.bigEndian
        }

        start += 4

        let framePosition = data[data.subrange(start: start, length: 8)].withUnsafeBytes {
          (pointer: UnsafePointer<Float64>) -> Float64 in
          Float64(bitPattern: pointer.pointee.bitPattern.bigEndian)
        }

        start += 8

        let id = data[data.subrange(start: start, length: 4)].withUnsafeBytes {
          (pointer: UnsafePointer<UInt32>) -> UInt32 in pointer.pointee.bigEndian
        }

        start += 4

        let timeRange = data.subrange(start: start, length: MemoryLayout<CAF_SMPTE_Time>.size)

        let time: CAF_SMPTE_Time? =
          data[timeRange].filter({$0 != 0xFF}).isEmpty
            ? nil
            : data[timeRange].withUnsafeBytes({
              (pointer: UnsafePointer<CAF_SMPTE_Time>) -> CAF_SMPTE_Time in
              CAF_SMPTE_Time(
                mHours: pointer.pointee.mHours.bigEndian,
                mMinutes: pointer.pointee.mMinutes.bigEndian,
                mSeconds: pointer.pointee.mSeconds.bigEndian,
                mFrames: pointer.pointee.mFrames.bigEndian,
                mSubFrameSampleOffset: pointer.pointee.mSubFrameSampleOffset.bigEndian)
            })

        start += MemoryLayout<CAF_SMPTE_Time>.size

        let channel = data[data.subrange(start: start, length: 4)].withUnsafeBytes {
          (pointer: UnsafePointer<UInt32>) -> UInt32 in pointer.pointee.bigEndian
        }

        start += 4

        let marker = Marker(type: type,
                            framePosition: framePosition,
                            id: id,
                            time: time,
                            channel: channel)

        markers.append(marker)

      }

      self.markers = markers

    }

    public var timeTypeDescription: String { return _timeTypeDescription(timeType) }

    public var description: String {
      return """
      MarkerChunk { timeType: \(timeTypeDescription); \
      markers: (\(markers.count) elements) }
      """
    }

  }


}
