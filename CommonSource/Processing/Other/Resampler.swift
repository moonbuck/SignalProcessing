//
//  Resampler.swift
//  SignalProcessing
//
//  Created by Jason Cardwell on 10/2/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation

/// Resampler resamples a stream from one integer sample rate to another (arbitrary) rate, using a
/// kaiser-windowed sinc filter.  The results and performance are pretty similar to libraries such
/// as libsamplerate, though this implementation does not support time-varying ratios (the ratio is
/// fixed on construction).
/// - Note: Ported from QM DSP Library
public class Resampler {

  private let sourceRate: Int
  private let targetRate: Int
  private let gcd: Int
  private let filterLength: Int

  /// The number of samples of latency at the output due by the filter. (That is, the output will
  /// be delayed by this number of samples relative to the input.)
  let latency: Int

  private var peakToPole: Double

  private let phaseData: [Phase]

  private var phase: Int

  private var buffer: [Float64]
  private var bufferOrigin: Int

  /// Construct a Resampler to resample from sourceRate to targetRate, using the given filter
  /// parameters.
  public init(sourceRate: Int, targetRate: Int, snr: Float64 = 100, bandwidth: Float64 = 0.02) {

    self.sourceRate = sourceRate
    self.targetRate = targetRate

    let higher = max(sourceRate, targetRate)
    let lower = min(sourceRate, targetRate)

    func gcd(_ a: Int, _ b: Int) -> Int {
      var a = a, b = b; while b != 0 { a = a % b; swap(&a, &b) }; return a
    }

    self.gcd = gcd(lower, higher)
    peakToPole = Float64(higher) / Float64(self.gcd)

    if targetRate < sourceRate {
      // antialiasing filter, should be slightly below nyquist

      peakToPole = peakToPole / (1 - bandwidth / 2)
      
    }

    var (length, beta) = KaiserWindow.parameters(forAttenuation: snr,
                                                 bandwidth: bandwidth,
                                                 sampleRate: Float64(higher) / Float64(self.gcd))

    if length % 2 == 0 { length += 1 }
    if length > 200001 { length = 200001 }

    filterLength = length

    let kaiserWindow = KaiserWindow(length: length, beta: beta)
    let sincWindow = SincWindow(length: length, p: peakToPole * 2)

    var filter = Array<Float64>(repeating: 1, count: filterLength)
    sincWindow.cut(buffer: &filter)
    kaiserWindow.cut(buffer: &filter)

    let inputSpacing = targetRate / self.gcd
    let outputSpacing = sourceRate / self.gcd

    /*
     Now we have a filter of (odd) length flen in which the lower sample rate corresponds to every
     n'th point and the higher rate to every m'th where n and m are higher and lower rates divided
     by their gcd respectively. So if x coordinates are on the same scale as our filter resolution,
     then source sample i is at i * (targetRate/gcd) and target sample j is at j * (sourceRate/gcd).

     To reconstruct a single target sample, we want a buffer (real or virtual) of flen values formed
     of source samples spaced at intervals of (targetRate / gcd), in our example case 3.  This is
     initially formed with the first sample at the filter peak.

     0  0  0  0  a  0  0  b  0

     and of course we have our filter

     f1 f2 f3 f4 f5 f6 f7 f8 f9

     We take the sum of products of non-zero values from this buffer with corresponding values in
     the filter

     a * f5 + b * f8

     Then we drop (sourceRate / gcd) values, in our example case 4, from the start of the buffer
     and fill until it has flen values again

     a  0  0  b  0  0  c  0  0

     repeat to reconstruct the next target sample

     a * f1 + b * f4 + c * f7

     and so on.

     Above I said the buffer could be "real or virtual" -- ours is virtual. We don't actually store
     all the zero spacing values, except for padding at the start; normally we store only the values
     that actually came from the source stream, along with a phase value that tells us how many
     virtual zeroes there are at the start of the virtual buffer.  So the two examples above are

     0 a b  [ with phase 1 ]
     a b c  [ with phase 0 ]

     Having thus broken down the buffer so that only the elements we need to multiply are present,
     we can also unzip the filter into every-nth-element subsets at each phase, allowing us to do
     the filter multiplication as a simply vector multiply. That is, rather than store

     f1 f2 f3 f4 f5 f6 f7 f8 f9

     we store separately

     f1 f4 f7
     f2 f5 f8
     f3 f6 f9

     Each time we complete a multiply-and-sum, we need to work out how many (real) samples to drop
     from the start of our buffer, and how many to add at the end of it for the next multiply. We
     know we want to drop enough real samples to move along by one computed output sample, which is
     our outputSpacing number of virtual buffer samples. Depending on the relationship between input
     and output spacings, this may mean dropping several real samples, one real sample, or none at
     all (and simply moving to a different "phase").
     */

    var phaseData: [Phase] = []
    phaseData.reserveCapacity(inputSpacing)

    for phase in 0 ..< inputSpacing {

      var nextPhase = phase - outputSpacing
      while nextPhase < 0 { nextPhase += inputSpacing }
      nextPhase %= inputSpacing

      let drop = Int(max(0, Float64(outputSpacing - phase) / Float64(inputSpacing)).rounded(.up))

      let filtZipLength = Int((Float64(length - phase) / Float64(inputSpacing)).rounded(.up))

      var pFilter: [Float64] = []

      for i in 0 ..< filtZipLength { pFilter.append(filter[i * inputSpacing + phase]) }

      phaseData.append(Phase(nextPhase: nextPhase, filter: pFilter, drop: drop))

    }

    self.phaseData = phaseData

    /*
     The May implementation of this uses a pull model -- we ask the resampler for a certain number
     of output samples, and it asks its source stream for as many as it needs to calculate those.
     This means (among other things) that the source stream can be asked for enough samples up-front
     to fill the buffer before the first output sample is generated.

     In this implementation we're using a push model in which a certain number of source samples is
     provided and we're asked for as many output samples as that makes available. But we can't
     return any samples from the beginning until half the filter length has been provided as input.
     This means we must either return a very variable number of samples (none at all until the
     filter fills, then half the filter length at once) or else have a lengthy declared latency on
     the output. We do the latter. (What do other implementations do?)

     We want to make sure the first "real" sample will eventually be aligned with the centre sample
     in the filter (it's tidier, and easier to do diagnostic calculations that way). So we need to
     pick the initial phase and buffer fill accordingly.

     Example: if the inputSpacing is 2, outputSpacing is 3, and filter length is 7,

        x     x     x     x     a     b     c ... input samples
     0  1  2  3  4  5  6  7  8  9 10 11 12 13 ...
              i        j        k        l    ... output samples
     [--------|--------] <- filter with centre mark

     Let h be the index of the centre mark, here 3 (generally int(filterLength/2) for odd-length
     filters).

     The smallest n such that h + n * outputSpacing > filterLength is 2 (that is, ceil((filterLength
     - h) / outputSpacing)), and (h + 2 * outputSpacing) % inputSpacing == 1, so the initial phase
     is 1.

     To achieve our n, we need to pre-fill the "virtual" buffer with 4 zero samples: the x's above.
     This is int((h + n * outputSpacing) / inputSpacing). It's the phase that makes this buffer get
     dealt with in such a way as to give us an effective index for sample a of 9 rather than 8 or
     10 or whatever.

     This gives us output latency of 2 (== n), i.e. output samples i and j will appear before the
     one in which input sample a is at the centre of the filter.
     */

    let h = length / 2
    let n = Int((Float64(length - h) / Float64(outputSpacing)).rounded(.up))

    phase = (h + n * outputSpacing) % inputSpacing

    let fill = (h + n * outputSpacing) / inputSpacing

    latency = n

    buffer = Array<Float64>(repeating: 0, count: fill)

    bufferOrigin = 0

  }

  /// Read `count` input samples from src and write resampled data to dst. The return value is the
  /// number of samples written, which will be no more than ceil((n * targetRate) / sourceRate). The
  /// caller must ensure the dst buffer has enough space for the samples returned.
  public func process(source: Float64Buffer, destination: Float64Buffer, count: Int) -> Int {

    let sourceArray = Array(UnsafeBufferPointer(start: source, count: count))
    buffer.append(contentsOf: sourceArray)

    let maxOut = Int((Float64(count) * Float64(targetRate) / Float64(sourceRate)).rounded(.up))
    var outIndex = 0

    let scaleFactor = (Float64(targetRate) / Float64(gcd)) / peakToPole

    while outIndex < maxOut && buffer.count >= phaseData[phase].filter.count + bufferOrigin {
      (destination + outIndex).initialize(to: scaleFactor * reconstructOne())
      outIndex = outIndex &+ 1
    }

    assert(bufferOrigin <= buffer.count)

    buffer = Array(buffer[bufferOrigin...])
    bufferOrigin = 0

   return outIndex

  }

  /// Read n input samples from src and return resampled data by value.
  public func process(source: Float64Buffer, count: Int) -> [Float64] {

    let maxOut = Int((Float64(count) * Float64(targetRate) / Float64(sourceRate)).rounded(.up))

    var out = Array<Float64>(repeating: 0, count: maxOut)

    let got = process(source: source, destination: &out, count: count)

    assert(got <= maxOut)

    if got < maxOut { out.removeSubrange(got...) }

    return out

  }

  /// Carry out a one-off resample of a single block of n samples. The output is latency-compensated.
  public static func resample(sourceRate: Int,
                              targetRate: Int,
                              data: Float64Buffer,
                              count: Int) -> [Float64]
  {

    let resampler = Resampler(sourceRate: sourceRate, targetRate: targetRate)

    let latency = resampler.latency

    let inputPad = Int((Float64(latency) * Float64(sourceRate) / Float64(targetRate)).rounded(.up))

    let n1 = count + inputPad

    let m1 = Int((Float64(n1) * Float64(targetRate) / Float64(sourceRate)).rounded(.up))

    let m = Int((Float64(count) * Float64(targetRate) / Float64(sourceRate)).rounded(.up))

    var pad = Array<Float64>(repeating: 0, count: n1 - count)
    var out = Array<Float64>(repeating: 0, count: m1 + 1)

    let gotData = resampler.process(source: data, destination: &out, count: count)

    let gotPad = out.withUnsafeMutableBufferPointer {
      resampler.process(source: &pad, destination: $0.baseAddress! + gotData, count: pad.count)
    }

    let got = gotData + gotPad

    let toReturn = min(m, got - latency)

    let sliced = out[latency..<(latency + toReturn)]

    return Array(sliced)

  }

  private func reconstructOne() -> Float64 {

    let phase = phaseData[self.phase]

    var v = 0.0
    let n = phase.filter.count

    for i in 0 ..< n { v += buffer[i + bufferOrigin] * phase.filter[i] }

    bufferOrigin += phase.drop

    self.phase = phase.nextPhase

    return v

  }

  struct Phase {

    let nextPhase: Int
    let filter: [Float64]
    let drop: Int

  }

}
