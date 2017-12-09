//
//  SyncWindow.swift
//  SignalProcessing
//
//  Created by Jason Cardwell on 10/2/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation

/// A window containing values of the sinc function, i.e. sin(x)/x with sinc(0) == 1, with x == 0
/// at the center.
/// - Note: Ported from QM DSP Library
public class SincWindow: Windower {

  public let length: Int
  private let p: Float64
  private let window: Float64Buffer

  /// Construct a windower of the given `length`, containing the values of sinc(x) with x=0 in the
  /// middle, i.e. at sample (length-1)/2 for odd or (length/2)+1 for even length, such that the
  /// distance from -pi to pi (the nearest zero crossings either side of the peak) is `p` samples.
  public init(length: Int, p: Float64) {

    self.length = length
    self.p = p

    window = Float64Buffer.allocate(capacity: max(0, length))

    guard length > 0 else { return }
    guard length > 1 else { window.initialize(to: 1); return }

    let n0 = length % 2 == 0 ? length / 2 : (length - 1) / 2
    let n1 = length % 2 == 0 ? length / 2 : (length + 1) / 2
    let m = 2 * .pi / p

    var index = 0
    for i in 0 ..< n0 {
      let x = (Float64(length / 2) - Float64(i)) * m
      (window + index).initialize(to: sin(x) / x)
      index = index &+ 1
    }

    (window + index).initialize(to: 1)
    index = index &+ 1

    for i in 1 ..< n1 {
      let x = Float64(i) * m
      (window + index).initialize(to: sin(x) / x)
      index = index &+ 1
    }

  }

  /// Apply the window to a buffer, overwriting the buffer with the result.
  public func cut(buffer: Float64Buffer) { cut(source: buffer, destination: buffer) }

  /// Apply the window to a source buffer, writing result to a destination buffer.
  public func cut(source: Float64Buffer, destination: Float64Buffer) {
    for i in 0 ..< length { (destination + i).initialize(to: source[i] * window[i]) }
  }

}
