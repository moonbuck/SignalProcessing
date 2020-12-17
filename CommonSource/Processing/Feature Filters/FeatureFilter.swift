//
//  FeatureFilter.swift
//  SignalProcessing
//
//  Created by Jason Cardwell on 9/15/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation

/// An enumeration of filters that can be applied to features.
///
/// - compression: Compresses feature values.
/// - normalization: Normalize feature values.
/// - quantization: Quantize feature values.
/// - smoothing: Smooth feature values.
/// - decibel: Converts feature values to their decibel equivalents.
public enum FeatureFilter: CustomStringConvertible {

  case compression (settings: CompressionSettings)
  case normalization (settings: NormalizationSettings)
  case quantization (settings: QuantizationSettings)
  case smoothing (settings: SmoothingSettings)
  case decibel (settings: DecibelConversionSettings)

  public func filter<Vector>(buffer: inout FeatureBuffer<Vector>) {

    switch self {

      case .compression(settings: let settings):
        compress(buffer: buffer, settings: settings)

      case .normalization(settings: let settings):
        normalize(buffer: buffer, settings: settings)

      case .quantization(settings: let settings):
        quantize(buffer: buffer, settings: settings)

      case .smoothing(settings: let settings):
        buffer = smooth(buffer: buffer, settings: settings)

      case .decibel(settings: let settings):
        decibelConversion(buffer: buffer, settings: settings)

    }

  }

  public var description: String {

    switch self {

      case .compression(let settings):
        return "Compression (term: \(settings.term), factor: \(settings.factor))"

      case .normalization(settings: let .lᵖNorm(space, threshold)):
        return "Normalization (lᵖ (space: \(space), threshold: \(threshold)))"

      case .normalization(.maxValue):
        return "Normalization (Max Value)"

      case .quantization(let settings):
        return "Quantization (steps: \(settings.steps), weights: \(settings.weights))"

      case .smoothing(let settings):
        return """
          Smoothing (window: \(settings.windowSize), \
          decimation: \(settings.decimation))
          """

      case .decibel(let settings):
        return """
          Decibel (multiplier: \(settings.multiplier), \
          zero reference: \(settings.zeroReference))
          """

    }

  }

}

