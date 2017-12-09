//
//  Filter.swift
//  SignalProcessing
//
//  Created by Jason Cardwell on 9/24/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import Accelerate

public final class Filter {

  public let a: [Float64]
  public let b: [Float64]

  public let order: Int
  public let size: Int

  public init(a: [Float64], b: [Float64]) {

    assert(a.count == b.count, "`a` and `b` must have the same count.")

    self.a = a
    self.b = b

    size = b.count
    order = size - 1

    aBuffer = Float64Buffer.allocate(capacity: order + maxOffset)
    vDSP_vclrD(aBuffer, 1, vDSP_Length(order + maxOffset))

    bBuffer = Float64Buffer.allocate(capacity: size + maxOffset)
    vDSP_vclrD(bBuffer, 1, vDSP_Length(size + maxOffset))

  }

  private let maxOffset = 20
  private var aOffset = 20
  private var bOffset = 20

  private var aBuffer: Float64Buffer
  private var bBuffer: Float64Buffer

  public func reset() {

    aOffset = maxOffset
    bOffset = maxOffset

    vDSP_vclrD(aBuffer, 1, vDSP_Length(order + maxOffset))
    vDSP_vclrD(bBuffer, 1, vDSP_Length(size + maxOffset))

  }

  public func process(signal: Float64Buffer, output: Float64Buffer, count: Int) {

    for signalIndex in 0 ..< count {

      if bOffset > 0 { bOffset -= 1 }
      else {

        for index in (0 ..< (size - 2)).reversed() {

          bBuffer[index + maxOffset + 1] = bBuffer[index]

        }

        bOffset = maxOffset

      }

      bBuffer[bOffset] = signal[signalIndex]

      var bSum = 0.0

      for index in 0 ..< size {

        bSum += b[index] * bBuffer[index + bOffset]

      }

      var outValue = 0.0

      var aSum = 0.0

      for index in 0 ..< order {

        aSum += a[index + 1] * aBuffer[index + aOffset]

      }

      outValue = bSum - aSum

      if aOffset > 0 { aOffset -= 1 }
      else {

        for index in (0 ..< (size - 2)).reversed() {

          aBuffer[index + maxOffset + 1] = aBuffer[index]

        }

        aOffset = maxOffset

      }

      aBuffer[aOffset] = outValue


      (output + signalIndex).initialize(to: outValue)
      
    }

  }

}
