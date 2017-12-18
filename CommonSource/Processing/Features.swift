//
//  Features.swift
//  Chord Finder
//
//  Created by Jason Cardwell on 8/25/17.
//  Copyright (c) 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import AVFoundation

/// A structure for extracting pitch and chroma features using a recipe of extraction parameters.
public struct Features {

  /// The source from which `pitchFeatures` and `chromaFeatures` were extracted.
  public let source: Source

  /// The pitch features extracted from `url`.
  public let pitchFeatures: PitchFeatures

  /// `pitchFeatures` smoothed and downsampled to match the feature rate of `chromaFeatures`.
  public let smoothedPitchFeatures: PitchFeatures

  /// The chroma features extracted from `pitchFeatures`. 
  public let chromaFeatures: ChromaFeatures

  /// The recipe whose parameters where used to extract `pitchFeatures` and `chromaFeatures`.
  public let recipe: Recipe

  /// Initializing with the url of an audio file and a feature recipe.
  ///
  /// - Parameters:
  ///   - url: The location of the audio file from which features are to be extracted.
  ///   - recipe: The recipe to use when extracting features.
  /// - Throws: Any error encountered opening `url` or initializing the multirate buffer.
  public init(from url: URL, using recipe: Recipe) throws {

    // Create a buffer from the PCM buffer.
    let buffer = (try AVAudioPCMBuffer(contentsOf: url)).mono64

    EqualLoudnessFilter().process(signal: buffer)

    // Extract pitch features.
    pitchFeatures = try PitchFeatures(from: buffer, parameters: recipe.pitchFeatureParameters)

    // Extract chroma features.
    chromaFeatures = ChromaFeatures(pitchFeatures: pitchFeatures,
                                    variant: recipe.chromaVariant)

    // Generate pitch features with a feature rate equal to `chromaFeatures`.
    if pitchFeatures.featureRate == chromaFeatures.featureRate {

      // No need to modify `pitchFeatures`.
      smoothedPitchFeatures = pitchFeatures

    } else {

      // Convert the pitch features into a buffer
      let pitchBuffer = PitchBuffer(pitchFeatures)

      // Calculate the downsample factor.
      let downsampleFactor = Int(pitchFeatures.featureRate/chromaFeatures.featureRate)

      // Create the smoothing settings.
      let smoothingSettings = SmoothingSettings(windowSize: 21,
                                                downsampleFactor: downsampleFactor)

      // Smooth/downsample the pitch features.
      let smoothedPitchBuffer = smooth(buffer: pitchBuffer, settings: smoothingSettings)

      // Create the normalization settings
//      let normalizationSettings: NormalizationSettings = .lᵖNorm(space: .l¹, threshold: 0.001)

      // Normalize the smoothed pitch features.
//      normalize(buffer: smoothedPitchBuffer, settings: normalizationSettings)

      var parameters = pitchFeatures.parameters
      parameters.filters = parameters.filters + [.smoothing(settings: smoothingSettings)]//,
//                                                 .normalization(settings: normalizationSettings)]



      // Initialize the property.
      smoothedPitchFeatures = PitchFeatures(smoothedPitchBuffer, parameters)

    }

    // Initialize `recipe`.
    self.recipe = recipe

    // Initialize the feature source.
    source = .file(url: url)

  }

  /// A simple structure encapsulating parameters for extracting pitch and chroma features.
  public struct Recipe {

    /// Parameters for pitch feature extraction.
    public let pitchFeatureParameters: PitchFeatures.Parameters

    /// The chroma feature variant to extract.
    public let chromaVariant: ChromaFeatures.Variant

    /// Similarity score adjustments.
    public let scoreAdjustments: [ScoreAdjustment]

    /// Initializing with default property values.
    ///
    /// - Parameters:
    ///   - pitchFeatureParameters: Parameters for pitch feature extraction.
    ///   - chromaVariant: The chroma feature variant to extract.
    ///   - scoreAdjustments: The adjusments to make when generating similarity scores.
    public init(pitchFeatureParameters: PitchFeatures.Parameters = PitchFeatures.Parameters(),
                chromaVariant: ChromaFeatures.Variant = .default,
                scoreAdjustments: [ScoreAdjustment] = ScoreAdjustment.defaultAdjustments)
    {
      self.pitchFeatureParameters = pitchFeatureParameters
      self.chromaVariant = chromaVariant
      self.scoreAdjustments = scoreAdjustments
    }

  }

  /// An enumeration of possible sources for feature extraction.
  public enum Source {

    /// The features are being extracted from audio captured by a microphone.
    case mic

    /// The features are being extracted from an audio file.
    /// - Parameter url: The location of the audio file.
    case file (url: URL)

  }


}

/*
extension Features {

  /// An option set for specifying what to include when generating reports.
  public struct ReportOptions: OptionSet {

    /// The value on which bitwise operations are used to determine which options have been set.
    public let rawValue: Int

    /// Initializing with a raw value.
    ///
    /// - Parameter rawValue: The raw value for the options.
    public init(rawValue: Int) { self.rawValue = rawValue }

    /// An option to include a pitch feature report.
    public static let pitch = ReportOptions(rawValue: 1 << 0)

    /// An option to include an overview of pitch features.
    public static let pitchBrief = ReportOptions(rawValue: 3 << 0)

    /// An option to include a smoothed pitch feature report.
    public static let smoothedPitch = ReportOptions(rawValue: 1 << 2)

    /// An option to include an overview of smoothed pitch features.
    public static let smoothedPitchBrief = ReportOptions(rawValue: 3 << 2)

    /// An option to include a chroma feature report.
    public static let chroma = ReportOptions(rawValue: 1 << 4)

    /// An option to include an overview of chroma features.
    public static let chromaBrief = ReportOptions(rawValue: 3 << 4)

    /// An option to include a report of chroma features with matched and expected templates.
    public static let template = ReportOptions(rawValue: 1 << 6)

    /// An option to include an overview chroma features with matched and expected templates.
    public static let templateBrief = ReportOptions(rawValue: 3 << 6)

    /// An option to include a report of chroma features with matched and expected templates.
    public static let feature = ReportOptions(rawValue: 1 << 8)

    /// An option to include an overview chroma features with matched and expected templates.
    public static let featureBrief = ReportOptions(rawValue: 3 << 8)

  }

  /// An enumeration of errors throwable by `Features`.
  public enum Error: String, Swift.Error {

    case invalidReportOptions = "The report options specified require a chord progression."

  }

  /// Generates a PDF file containing the specified feature report and saves the file to `url`.
  ///
  /// - Parameters:
  ///   - reportOptions: Options specifying what to include in the generated report.
  ///   - url: The destination directory for saving the generated report.
  ///   - expectedChords: The actual chord progression for the feature source or `nil` if
  ///                     the chords are not required for the configured `reportOptions`.
  /// - Throws: Any error encountered while generating the report.
  public func generate(reportOptions: ReportOptions,
                       saveLocation url: URL,
                       fileNameSuffix: String = "",
                       expectedChords: ChordProgression? = nil) throws
  {

    // Create an array for holding the report content providers.
    var providers: [ReportContentProvider] = []

    // Create an array for piecing together a file name from the providers.
    var providerNames: [String] = []

    // Check whether to include a pitch report.
    if reportOptions.contains(.pitch) {

      // Append a pitch report.
      providers.append(PitchReport(features: pitchFeatures,
                                   source: source,
                                   isBrief: reportOptions.contains(.pitchBrief)))

      providerNames.append("Pitch")

    }

    // Check whether to include a smoothed pitch report.
    if reportOptions.contains(.smoothedPitch) {

      // Append a pitch report.
      providers.append(PitchReport(features: smoothedPitchFeatures,
                                   source: source,
                                   isBrief: reportOptions.contains(.smoothedPitchBrief)))

      providerNames.append("SmoothedPitch")

    }

    // Check whether to include a chroma report.
    if reportOptions.contains(.chroma) {

      // Append a chroma report.
      providers.append(ChromaReport(features: chromaFeatures,
                                    source: source,
                                    recipe: recipe,
                                    isBrief: reportOptions.contains(.chromaBrief)))

      providerNames.append("Chroma")

    }

    // Check whether to include a template report.
    if reportOptions.contains(.template) {

      // Unwrap the chord progression.
      guard let expectedChords = expectedChords else { throw Error.invalidReportOptions }

      // Append a template report.
      providers.append(TemplateReport(features: chromaFeatures,
                                      source: source,
                                      scoreAdjustments: recipe.scoreAdjustments,
                                      expectedChords: expectedChords,
                                      isBrief: reportOptions.contains(.templateBrief)))

      providerNames.append("Template")

    }

    // Check whether to include a feature report.
    if reportOptions.contains(.feature) {

      // Unwrap the chord progression.
      guard let expectedChords = expectedChords else { throw Error.invalidReportOptions }

      // Append a template report.
      providers.append(FeatureReport(features: self,
                                      expectedChords: expectedChords,
                                      isBrief: reportOptions.contains(.featureBrief)))

      providerNames.append("Feature")

    }

    // Check that `reportOptions` specifies at least one provider.
    guard !providers.isEmpty else { return }

    // Join together the provider names for a file name prefix.
    let prefix = providerNames.joined(separator: "-")

    // Create a suffix out of `source`.
    let suffix: String

    switch source {
      case .file(url: let sourceURL): suffix = sourceURL.lastPathComponent + fileNameSuffix
      case .mic:                      suffix = "CapturedAudio" + fileNameSuffix
    }

    // Create a url for the generated file.
    let fileURL = url.appendingPathComponent("\(prefix) Report-\(suffix).pdf")

    // Generate the PDF file.
    ReportRenderer.createReport(url: fileURL, providers: providers)

  }

}
*/

