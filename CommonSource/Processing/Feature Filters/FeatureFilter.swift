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
public enum FeatureFilter {

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

}

