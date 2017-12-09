//
//  Window.swift
//  SignalProcessing
//
//  Created by Jason Cardwell on 9/27/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import Accelerate

public struct Window {

  public let size: Int

  public let zeroPhase: Bool

  public init(size: Int, zeroPhase: Bool = true) {

    self.size = size
    self.zeroPhase = zeroPhase

    _window = Float64Buffer.allocate(capacity: size)
    for i in 0 ..< size {
      (_window + i).initialize(to: 0.5 - 0.5 * cos((2 * .pi * Float64(i)) / Float64(size - 1)))
    }

    var sum = 0.0
    vDSP_svemgD(_window, 1, &sum, vDSP_Length(size))

    var scale = 2 / sum
    vDSP_vsmulD(_window, 1, &scale, _window, 1, vDSP_Length(size))

  }

  private let _window: Float64Buffer

  public func window(signal: SignalVector) -> SignalVector {

    let windowedSignal = SignalVector(count: size)

    switch zeroPhase {

    case true:

      var i = 0

      // first half of the windowed signal is the
      // second half of the signal with windowing!
      for j in signal.count/2..<signal.count {
        windowedSignal.storage[i] = signal[j] * _window[j]
        i += 1
      }

      // second half of the signal
      for j in 0 ..< signal.count/2 {
        windowedSignal.storage[i] = signal[j] * _window[j]
        i += 1
      }

    case false:

      for i in 0 ..< signal.count {
        windowedSignal.storage[i] *= _window[i]
      }

    }

    return windowedSignal
    
  }

}

