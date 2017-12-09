//
//  KaiserWindow.swift
//  SignalProcessing
//
//  Created by Jason Cardwell on 10/2/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation

/// A windower whose bandwidth and sidelobe height (signal-noise ratio) can be specified. These
/// parameters are traded off against the window length.
public class KaiserWindow: Windower {

  /// The length of the window.
  public let length: Int

  /// The beta parameter used to construct the window.
  private let beta: Float64

  /// The buffer holding `length` window values.
  private let window: Float64Buffer

  /// Initialize with the specified `length` and `beta` parameters.
  public init(length: Int, beta: Float64) {

    func factorial(_ a: Int) -> Int { return a == 1 ? a : a * factorial(a - 1) }

    func besselTerm(_ x: Float64, _ i: Int) -> Float64 {
      return i == 0 ? 1 : pow(x / 2, Float64(i * 2)) / pow(Float64(factorial(i)), 2)
    }

    func bessel0(_ x: Float64) -> Float64 {
      var b = 0.0
      for i in 0 ..< 20 { b += besselTerm(x, i) }
      return b
    }

    let denominator = bessel0(beta)
    let even = length % 2 == 0

    window = Float64Buffer.allocate(capacity: length)

    var index = 0
    for i in 0 ..< (even ? length / 2 : (length + 1) / 2) {
      let k = Float64(2 * i) / Float64(length - 1) - 1
      (window + index).initialize(to: bessel0(beta * sqrt(1 - pow(k, 2))) / denominator)
      index = index &+ 1
    }

    for i in 0 ..< (even ? length / 2 : (length - 1) / 2) {
      (window + index).initialize(to: window[length / 2 - i - 1])
      index = index &+ 1
    }

    self.length = length
    self.beta = beta

  }

  /// Initialize a Kaiser windower with the given attenuation in dB and transition width in samples.
  public convenience init(attenuation: Float64, transition: Float64) {

    let (length, beta) = KaiserWindow.parameters(forAttenuation: attenuation,
                                                 transitionWidth: transition)

    self.init(length: Int(length), beta: beta)

  }

  /// Initialize a Kaiser window of the given attenuation in dB and transition bandwidth in Hz for
  /// the given samplerate.
  public convenience init(attenuation: Float64, bandwidth: Float64, sampleRate: Float64) {

    let (length, beta) = KaiserWindow.parameters(forAttenuation: attenuation,
                                                 bandwidth: bandwidth,
                                                 sampleRate: sampleRate)

    self.init(length: length, beta: beta)

  }

  /// Apply the window to a buffer, overwriting the buffer with the result.
  public func cut(buffer: Float64Buffer) { cut(source: buffer, destination: buffer) }

  /// Apply the window to a source buffer, writing result to a destination buffer.
  public func cut(source: Float64Buffer, destination: Float64Buffer) {
    for i in 0 ..< length { (destination + i).initialize(to: source[i] * window[i]) }
  }

  /// Obtain the parameters necessary for a Kaiser window of the given attenuation in dB and
  /// transition width in samples.
  public static func parameters(forAttenuation attenuation: Float64,
                                transitionWidth transition: Float64) -> (length: Int, beta: Float64)
  {

    let length = 1 + (attenuation > 21.0 ?
      ceil((attenuation - 7.95) / (2.285 * transition)) :
      ceil(5.79 / transition))

    let beta = (attenuation > 50 ?
      0.1102 * (attenuation - 8.7) :
      attenuation > 21 ?
        0.5842 * pow(attenuation - 21, 0.4) + 0.07886 * (attenuation - 21.0) :
      0)

    return (length: Int(length), beta: beta)

  }

  /// Obtain the parameters necessary for a Kaiser window of the given attenuation in dB and
  /// transition bandwidth in Hz for the given samplerate.
  public static func parameters(forAttenuation attenuation: Float64,
                                bandwidth: Float64,
                                sampleRate: Float64) -> (length: Int, beta: Float64)
  {
    return parameters(forAttenuation: attenuation,
                      transitionWidth: (bandwidth * 2 * .pi) / sampleRate)
  }

}
