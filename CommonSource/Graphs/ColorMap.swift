//
//  ColorMap.swift
//  SignalProcessing
//
//  Created by Jason Cardwell on 12/11/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import Accelerate

private func steps(from x: CGFloat, to y: CGFloat) -> Int {
  return Int(bitPattern: y.bitPattern) - Int(bitPattern: x.bitPattern)
}

/// A structure for specifying a color map for use with graphing functions.
public struct ColorMap: Collection {

  /// An enumeration of supported color map sizes.
  public enum Size { case infinite, s64, s128 }

  /// An enumeration for specifying how the color map should generate its colors.
  public enum Kind { case heat, grayscale, data }

  /// The total number of assignable colors in the color map
  public let size: Size

  /// The kind of colors used by the color map.
  public let kind: Kind

  /// The range of values mapped by the color map.
  public var valueRange: Range<CGFloat> {
    switch size {
      case .s64, .infinite: return 0..<1
      case .s128: return -1..<1
    }
  }

  public var preferredBackgroundColor: Color {
    switch kind {
      case .heat, .data: return .black
      case .grayscale: return .white
    }
  }

  /// The actual colors that make up the color map.
  private let colors: [Color]

  public var count: Int { return endIndex }

  public let startIndex: Int = 0
  public let endIndex: Int

  public func index(after i: Int) -> Int { return i &+ 1 }

  public subscript(position: Int) -> Color {
    switch kind {
      case .data: return Color(white: CGFloat(bitPattern: UInt(position)), alpha: 1)
      default:    return colors[position]
    }
  }

  public subscript(value: Float64) -> Color {

    let value = Swift.max(Swift.min(value.isInfinite || value.isNaN ? 0 : value, 1), 0)

    switch size {
      case .infinite: return Color(white: CGFloat(value), alpha: 1)
      case .s64:      return colors[Int((value * 63).rounded())]
      case .s128:     return colors[Int((((value + 1) / 2) * 127).rounded())]
    }

  }

  private init(heatMapWithSize size: Size) {

    kind = .heat
    self.size = size

    var oneHalf = 0.5
    var zero = 0.0
    var one = 1.0
    var a = 0.0417
    var b = 0.0625

    let ramp24AtoOne = UnsafeMutablePointer<Double>.allocate(capacity: 24)
    vDSP_vgenD(&a, &one, ramp24AtoOne, 1, 24)

    let ramp24ZerotoOne = UnsafeMutablePointer<Double>.allocate(capacity: 24)
    vDSP_vgenD(&zero, &one, ramp24ZerotoOne, 1, 24)

    let ramp16ZeroToOne = UnsafeMutablePointer<Double>.allocate(capacity: 16)
    vDSP_vgenD(&zero, &one, ramp16ZeroToOne, 1, 16)

    switch size {

    case .s64:

      endIndex = 64

      let redValues = UnsafeMutablePointer<Double>.allocate(capacity: 64)
      redValues.initialize(from: ramp24AtoOne, count: 24)
      (redValues + 24).initialize(to: 1, count: 40)

      let greenValues = UnsafeMutablePointer<Double>.allocate(capacity: 64)
      greenValues.initialize(to: 0, count: 24)
      (greenValues + 24).initialize(from: ramp24ZerotoOne, count: 24)
      (greenValues + 48).initialize(to: 1, count: 16)

      let blueValues = UnsafeMutablePointer<Double>.allocate(capacity: 64)
      blueValues.initialize(to: 0, count: 48)
      (blueValues + 48).initialize(from: ramp16ZeroToOne, count: 16)

      colors = (0..<64).map { Color(red: CGFloat(redValues[$0]),
                                    green: CGFloat(greenValues[$0]),
                                    blue: CGFloat(blueValues[$0]),
                                    alpha: 1) }

    case .s128:

      endIndex = 128

      let ramp64OneHalfToZero = UnsafeMutablePointer<Double>.allocate(capacity: 64)
      vDSP_vgenD(&oneHalf, &zero, ramp64OneHalfToZero, 1, 64)

      let ramp64OneToZero = UnsafeMutablePointer<Double>.allocate(capacity: 64)
      vDSP_vgenD(&one, &zero, ramp64OneToZero, 1, 64)

      let ramp16BtoOne = UnsafeMutablePointer<Double>.allocate(capacity: 16)
      vDSP_vgenD(&b, &one, ramp16BtoOne, 1, 16)

      let redValues = UnsafeMutablePointer<Double>.allocate(capacity: 128)
      redValues.initialize(from: ramp64OneHalfToZero, count: 64)
      (redValues + 64).initialize(from: ramp24AtoOne, count: 24)
      (redValues + 88).initialize(to: 1, count: 40)

      let greenValues = UnsafeMutablePointer<Double>.allocate(capacity: 128)
      greenValues.initialize(from: ramp64OneHalfToZero, count: 64)
      (greenValues + 64).initialize(to: 0, count: 24)
      (greenValues + 88).initialize(from: ramp24AtoOne, count: 24)
      (greenValues + 112).initialize(to: 1, count: 16)

      let blueValues = UnsafeMutablePointer<Double>.allocate(capacity: 128)
      blueValues.initialize(from: ramp64OneToZero, count: 64)
      (blueValues + 64).initialize(to: 0, count: 48)
      (blueValues + 112).initialize(from: ramp16BtoOne, count: 16)

      colors = (0..<128).map { Color(red: CGFloat(redValues[$0]),
                                     green: CGFloat(greenValues[$0]),
                                     blue: CGFloat(blueValues[$0]),
                                     alpha: 1) }

      case .infinite:
        fatalError("Only maps of kind `.data` support the `.infinite` size.")
    }


  }

  private init(grayscaleMapWithSize size: Size) {

    kind = .grayscale
    self.size = size

    var min = 0.0417
    var max = 1.0

    switch size {

    case .s64:

      endIndex = 64

      let ramp = UnsafeMutablePointer<Double>.allocate(capacity: 64)
      vDSP_vgenD(&min, &max, ramp, 1, 64)
      colors = (0..<64).reversed().map { Color(white: CGFloat(ramp[$0]), alpha: 1) }

    case .s128:

      endIndex = 128

      let ramp = UnsafeMutablePointer<Double>.allocate(capacity: 128)
      vDSP_vgenD(&min, &max, ramp, 1, 128)
      colors = (0..<128).reversed().map { Color(white: CGFloat(ramp[$0]), alpha: 1) }

      case .infinite:
        fatalError("Only maps of kind `.data` support the `.infinite` size.")

    }

  }

  private init(dataMap: Void) {
    kind = .data
    size = .infinite
    colors = []
    endIndex = Int(CGFloat(1).bitPattern - CGFloat(0).bitPattern)
  }

  public init(kind: Kind = .heat) {
    switch kind {
      case .heat, .grayscale: self.init(size: .s64, kind: kind)
      case .data: self.init(dataMap: ())
    }
  }

  public init(size: Size, kind: Kind = .heat) {

    switch kind {
      case .heat: self.init(heatMapWithSize: size)
      case .grayscale: self.init(grayscaleMapWithSize: size)
      case .data where size == .infinite: self.init(dataMap: ())
      case .data: fatalError("Only size `.infinite` is supported by kind `.data`.")
    }

  }

}
