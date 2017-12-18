//
//  SignalFilter.swift
//  SignalProcessing
//
//  Created by Jason Cardwell on 9/28/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//

import Foundation
import AVFoundation
import Accelerate

public protocol SignalFilter {

  func process(signal x: SignalVector, y: SignalVector)
  func process(signal x: Float64Buffer, y: SignalVector)

}

extension SignalFilter {

  public func process(signal buffer: AVAudioPCMBuffer) {

    guard let float64ChannelData = buffer.float64ChannelData else { return }

    let n = Int(buffer.frameLength)
    let nu = vDSP_Length(n)

    for channel in 0 ..< Int(buffer.format.channelCount) {

//      let unfilteredSignal = SignalVector(count: n)
//      vDSP_mmovD(float64ChannelData[channel], unfilteredSignal.storage, nu, nu, 1, nu)

      // Wrap the data in a vector.
//      let unfilteredSignal = SignalVector(storage: float64ChannelData[channel],
//                                          count: n,
//                                          assumeOwnership: false)

      // Create an empty vector for the filtered signal.
      let filteredSignal = SignalVector(count: n)

      // Filter this channel's signal.
      process(signal: float64ChannelData[channel], y: filteredSignal)

      // Overwrite the buffer's raw data with the filtered signal for this channel.
      vDSP_mmovD(filteredSignal.storage, float64ChannelData[channel], nu, 1, nu, nu)

    }

    // Get the buffer list.
//    let bufferList = UnsafeMutableAudioBufferListPointer(buffer.mutableAudioBufferList)

    // Get the number of samples per channel.
//    let n = Int(buffer.frameLength)

    // Get an unsigned version of the sample count.
//    let nu = vDSP_Length(n)

//    switch buffer.format.commonFormat {

//    case .pcmFormatFloat64:
      // Iterate the channels.
//      for channelBuffer in bufferList {

        // Get the raw data for this channel.
//        guard let rawChannelData = channelBuffer.mData else {
//          fatalError("Failed to get underlying data for one of the buffer's channels.")
//        }

        // Bind the raw data to `Float64`.
//        let float64ChannelData = rawChannelData.assumingMemoryBound(to: Float64.self)

        // Wrap the data in a vector.
//        let unfilteredSignal = SignalVector(storage: float64ChannelData, count: n)

        // Create an empty vector for the filtered signal.
//        var filteredSignal = SignalVector(count: n)

        // Filter this channel's signal.
//        process(signal: unfilteredSignal, y: &filteredSignal)

        // Overwrite the buffer's raw data with the filtered signal for this channel.
//        vDSP_mmovD(filteredSignal.storage, float64ChannelData, nu, 1, nu, nu)

//      }

//    default:
//      fatalError("Buffer's underlying data must be 64 bit floating point.")

//    }

  }

}
