//
//  EqualLoudnessFilter.swift
//  SignalProcessing
//
//  Created by Jason Cardwell on 9/27/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import AVFoundation

public final class EqualLoudnessFilter: SignalFilter {

  private static let butterworthCoefficients = (
    a: [1.0, -1.96977855582618, 0.97022847566350],
    b: [0.98500175787242, -1.97000351574484, 0.98500175787242]
  )

  private static let yulewalkCoefficients = (
    a: [1.0, -3.47845948550071, 6.36317777566148, -8.54751527471874, 9.47693607801280,
        -8.81498681370155, 6.85401540936998, -4.39470996079559, 2.19611684890774,
        -0.75104302451432, 0.13149317958808],
    b: [0.05418656406430, -0.02911007808948, -0.00848709379851, -0.00851165645469,
        -0.00834990904936, 0.02245293253339, -0.02596338512915, 0.01624864962975,
        -0.00240879051584, 0.00674613682247-0.00187763777362]
  )

  private let butterworthFilter = IIRFilter(a: EqualLoudnessFilter.butterworthCoefficients.a,
                                            b: EqualLoudnessFilter.butterworthCoefficients.b)

  private let yulewalkFilter = IIRFilter(a: EqualLoudnessFilter.yulewalkCoefficients.a,
                                         b: EqualLoudnessFilter.yulewalkCoefficients.b)

  public func process(signal x: SignalVector, y: inout SignalVector) {

    var buffer = SignalVector(count: x.count)

    yulewalkFilter.process(signal: x, y: &buffer)
    butterworthFilter.process(signal: buffer, y: &y)

  }

  public init() {}

  public static func process(signal buffer: AVAudioPCMBuffer) {
    EqualLoudnessFilter().process(signal: buffer)
  }

  public static func process(signal x: SignalVector, y: inout SignalVector) {
    EqualLoudnessFilter().process(signal: x, y: &y)
  }

}

