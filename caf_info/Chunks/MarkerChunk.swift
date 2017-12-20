//
//  MarkerChunk.swift
//  caf_info
//
//  Created by Jason Cardwell on 12/20/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import struct AudioToolbox.CAF_SMPTE_Time
import struct AudioToolbox.CAFMarker

private func timeDescription(_ time: CAF_SMPTE_Time?) -> String {
  guard let time = time else { return "nil" }
  return """
    SMPTE { hours: \(time.mHours); minutes: \(time.mMinutes); seconds: \(time.mSeconds); \
    frames: \(time.mFrames); subFrameSampleOffset: \(time.mSubFrameSampleOffset) }
    """
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

    public var description: String {
      return """
        Marker { type: \(type); framePosition: \(framePosition); id: \(id); \
        time: \(timeDescription(time)); channel: \(channel) }
        """
    }

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

    public var description: String {
      return "MarkerChunk { timeType: \(timeType); markers: (\(markers.count) elements) } "
    }

  }


}
