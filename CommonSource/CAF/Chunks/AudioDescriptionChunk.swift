//
//  AudioDescriptionChunk.swift
//  SignalProcessing
//
//  Created by Jason Cardwell on 12/20/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import struct AudioToolbox.CAFFormatFlags
import struct AudioToolbox.CAFAudioDescription
import MoonKit

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

  public struct AudioDescriptionChunkData: CAFFileChunkData {

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
      self = data.withUnsafeBytes({
        guard let description = ($0.baseAddress?.assumingMemoryBound(to: CAFAudioDescription.self)
                                  ?? nil)?.pointee
          else { fatalError("\(#function) ") }

        let formatFlags = CAFFormatFlags(rawValue: description.mFormatFlags.rawValue.bigEndian)

        return AudioDescriptionChunkData(
          sampleRate: Float64(bitPattern: description.mSampleRate.bitPattern.bigEndian),
          formatID: FourCharacterCode(value: description.mFormatID.bigEndian),
          formatFlags: LinearPCMFormatFlags(flags: formatFlags),
          bytesPerPacket: description.mBytesPerPacket.bigEndian,
          framesPerPacket: description.mFramesPerPacket.bigEndian,
          channelsPerFrame: description.mChannelsPerFrame.bigEndian,
          bitsPerChannel: description.mBitsPerChannel.bigEndian
        )

      })

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
