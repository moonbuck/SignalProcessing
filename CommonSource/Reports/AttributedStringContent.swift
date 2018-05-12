//
//  AttributedStringContent.swift
//  Chord Finder
//
//  Created by Jason Cardwell on 8/31/17.
//  Copyright (c) 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import MoonKit

#if os(iOS)
  import UIKit
#else
  import AppKit
#endif

/// Extension of mutable attributed strings with functions used by various report content providers.
extension NSMutableAttributedString {

  /// Appends a description for the source of extracted features.
  ///
  /// - Parameter featureSource: The source to describe.
  public func append(featureSource: Features.Source) {

    // Append a description of the chroma feature source.
    switch featureSource {

    case .mic:
      self += ("audio input", .ctBlack)

    case .file(url: let url):
      self += (url.lastPathComponent, .ctExtraLightItalic)

    }

  }

  /// Appends a horizontal line.
  public func appendLine() {

    self += ("\("─" * ReportRenderer.columnCount)\n", .ctBold)

  }

  /// Appends a double horizontal line.
  public func appendDoubleLine() {

    self += ("\("═" * ReportRenderer.columnCount)\n", .ctBold)

  }

  /// Appends descriptions for the frame count, feature rate, and parameters of a collection
  /// of chroma features.
  ///
  /// - Parameter chromaFeatures: The features for which a description is to be appended.
  public func appendInfo(for chromaFeatures: ChromaFeatures) {

    // Append the frame count.
    self += ("# Frames: ", .ctMediumItalic)
    self += ("\(chromaFeatures.count)\n", .ctLightItalic)

    // Append the feature rate.
    self += ("Feature Rate: ", .ctMediumItalic)
    self += ("\(chromaFeatures.featureRate) Hz\n", .ctLightItalic)

    // Append the parameters.
    append(parameters: chromaFeatures.parameters)

  }

  /// Appends a description of chroma feature parameters that includes the pitch feature parameters
  /// and the chroma variant.
  ///
  /// - Parameter parameters: The parameters for which to append a description.
  public func append(parameters: ChromaFeatures.Parameters, indent: Int = 0) {

    // Introduce the pitch feature parameters and start a new line.
    self += ("\(" " * indent)Pitch Feature Parameters:\n", .ctMediumItalic)

    // Append a description of the pitch feature parameters with a slight indentation.
    append(parameters: parameters.pitchFeatureParameters, indent: indent + 4)

    // Append a description of the variant.
    append(variant: parameters.variant, indent: indent)

  }

  /// Appends a description of pitch features that includes the number of features, feature rate,
  /// and the parameters used to extract the features.
  ///
  /// - Parameter pitchFeatures: The pitch features for which to append a description.
  public func appendInfo(for pitchFeatures: PitchFeatures) {

    // Append the frame count.
    self += ("# Frames: ", .ctMediumItalic)
    self += ("\(pitchFeatures.count)\n", .ctLightItalic)

    // Append the feature rate.
    self += ("Feature Rate: ", .ctMediumItalic)
    self += ("\(pitchFeatures.featureRate) Hz\n", .ctLightItalic)

    // Append the parameters.
    append(parameters: pitchFeatures.parameters)

  }

  /// Appends a description of pitch feature parameters that includes the method of extraction,
  /// the normalization settings, the compression settings, and the smoothing settings.
  ///
  /// - Parameters:
  ///   - parameters: The parameters for which to append a description.
  ///   - indent: The number of spaces that should be prepended to each line.
  public func append(parameters: PitchFeatures.Parameters, indent: Int = 0) {

    append(extractionMethod: parameters.method, indent: indent)

    self += ("\(" " * indent)Filters:\(parameters.filters.isEmpty ? " None" : "")\n", .ctMediumItalic)

    for filter in parameters.filters {

      switch filter {

        case .compression(settings: let settings):
          append(compressionSettings: settings, indent: indent + 4)

        case .normalization(settings: let settings):
          append(normalizationSettings: settings, indent: indent + 4)

        case .quantization(settings: let settings):
          append(quantizationSettings: settings, indent: indent + 4)

        case .smoothing(settings: let settings):
          append(smoothingSettings: settings, indent: indent + 4)

        case .decibel(let settings):
          append(decibelConversionSettings: settings, indent: indent + 4)
        
      }

    }


  }

  public func appendInfo(for features: Features) {

    // Append the frame count.
    self += ("Pitch Features:\n", .ctMediumItalic)
    self += ("    # Frames: ", .ctMediumItalic)
    self += ("\(features.pitchFeatures.count)\n", .ctLightItalic)

    // Append the feature rate.
    self += ("    Feature Rate: ", .ctMediumItalic)
    self += ("\(features.pitchFeatures.featureRate) Hz\n", .ctLightItalic)

    // Append the frame count.
    self += ("Smoothed Pitch/Chroma Features:\n", .ctMediumItalic)
    self += ("    # Frames: ", .ctMediumItalic)
    self += ("\(features.chromaFeatures.count)\n", .ctLightItalic)

    // Append the feature rate.
    self += ("    Feature Rate: ", .ctMediumItalic)
    self += ("\(features.chromaFeatures.featureRate) Hz\n", .ctLightItalic)

    // Append a description of the recipe.
    append(recipe: features.recipe)

  }

  /// Appends a description of the specified feature recipe.
  ///
  /// - Parameter recipe: The recipe for which a description shall be appended.
  public func append(recipe: Features.Recipe) {

    // Introduce the recipe and start a new line.
    self += ("Recipe:\n", .ctMediumItalic)

    // Introduce the pitch feature parameters and start a new line.
    self += ("    Pitch Feature Parameters:\n", .ctMediumItalic)

    // Append a description of the pitch feature parameters with a slight indentation.
    append(parameters: recipe.pitchFeatureParameters, indent: 8)

    // Append a description of the variant.
    append(variant: recipe.chromaVariant, indent: 4)

    // Append a description of the similarity score adjustments.
    append(scoreAdjustments: recipe.scoreAdjustments)

  }

  /// Appends a description of the specified similarity score adjustments.
  ///
  /// - Parameter scoreAdjustmenets: The score adjusmtents for which to append a description.
  public func append(scoreAdjustments: [ScoreAdjustment], indent: Int = 0) {

    // Append a line to introduce the similarity score configuration.
    self += ("\(" " * indent)Similarity Score Adjustments:", .ctMedium)

    guard !scoreAdjustments.isEmpty else {

      self += (" None\n", .ctLightItalic)

      return

    }

    self += ("\n", .ctMedium)


    for adjustment in scoreAdjustments {

      switch adjustment {

        case let .noteCount(matchingBonus):

          // Append an intro for the note count adjustment.
          self += ("\(" " * (indent + 4))Note Count Adjustment:\n", .ctMediumItalic)

          // Append the matching bonus.
          self += ("\(" " * (indent + 8))Matching Bonus: ", .ctItalic)
          self += ("\(matchingBonus)\n", .ctLightItalic)

        case let .chordRoot(matching, penalty, threshold, bonus):

          // Append an intro for the chord root adjustment.
          self += ("\(" " * (indent + 4))Chord Root Adjustment:\n", .ctMediumItalic)

          // Append the matching bonus.
          self += ("\(" " * (indent + 8))Matching Bonus: ", .ctItalic)
          self += ("\(matching)\n", .ctLightItalic)

          // Append the mismatch penalty.
          self += ("\(" " * (indent + 8))Mismatch Penalty: ", .ctItalic)
          self += ("\(penalty)\n", .ctLightItalic)

          // Append the high energy threshold.
          self += ("\(" " * (indent + 8))High Energy Threshold: ", .ctItalic)
          self += ("\(threshold)\n", .ctLightItalic)

          // Append the high energy bonus.
          self += ("\(" " * (indent + 8))High Energy Bonus: ", .ctItalic)
          self += ("\(bonus)\n", .ctLightItalic)

        case let .energyDistribution(absent, matching, threshold, bonus, penalty):

          // Append an intro for the energy distribution adjustment.
          self += ("\(" " * (indent + 4))Energy Distribution Adjustment:\n", .ctMediumItalic)

          // Append the absent chroma threshold.
          self += ("\(" " * (indent + 8))Absent Chroma Threshold: ", .ctItalic)
          self += ("\(absent)\n", .ctLightItalic)

          // Append the matching chroma bonus.
          self += ("\(" " * (indent + 8))Matching Chromas Bonus: ", .ctItalic)
          self += ("\(matching)\n", .ctLightItalic)

          // Append the high energy threshold.
          self += ("\(" " * (indent + 8))High Energy Threshold: ", .ctItalic)
          self += ("\(threshold)\n", .ctLightItalic)

          // Append the high energy bonus.
          self += ("\(" " * (indent + 8))High Energy Bonus: ", .ctItalic)
          self += ("\(bonus)\n", .ctLightItalic)

          // Append the high energy penalty.
          self += ("\(" " * (indent + 8))High Energy Penalty: ", .ctItalic)
          self += ("\(penalty)\n", .ctLightItalic)

      }

    }

  }

  /// Appends a description of a pitch feature extraction method.
  ///
  /// - Parameters:
  ///   - extractionMethod: The method to describe.
  ///   - indent: The number of spaces that should be prepended to each line.
  public func append(extractionMethod: PitchFeatures.ExtractionMethod, indent: Int = 0) {

    // Append a description of the extraction method.
    self += ("\(" " * indent)Extraction Method: ", .ctMediumItalic)

    // Initialize `methodDesc`.
    switch extractionMethod {

      case .stft(let p):
        self += ("STFT { Window Size: \(p.windowSize), Hop Size: \(p.hopSize) }\n", .ctLightItalic)

      case .filterbank(let p):
        self += ("Filterbank { Window Size: \(p.windowSize), Hop Size: \(p.hopSize) }\n", .ctLightItalic)

    }


  }

  /// Appends a description for feature compression settings.
  ///
  /// - Parameters:
  ///   - compression: The settings to describe or `nil` if compression was not applied.
  ///   - indent: The number of spaces that should be prepended to each line.
  public func append(compressionSettings compression: CompressionSettings?, indent: Int = 0) {

    // Append a description of `compression`.
    self += ("\(" " * indent)Logarithmic Compression: ", .ctMediumItalic)

    if let compression = compression {
      self += ("{ Term: \(compression.term), Factor: \(compression.factor) }\n", .ctLightItalic)
    } else {
      self += ("No\n", .ctLightItalic)
    }

  }

  /// Appends a description for feature decibel conversion settings.
  ///
  /// - Parameters:
  ///   - decibels: The settings to describe or `nil` if decibel conversion was not applied.
  ///   - indent: The number of spaces that should be prepended to each line.
  public func append(decibelConversionSettings decibels: DecibelConversionSettings?,
                     indent: Int = 0)
  {

    // Append a description of `compression`.
    self += ("\(" " * indent)Logarithmic Compression: ", .ctMediumItalic)

    if let decibels = decibels {
      self += ("{ Multiplier: \(decibels.multiplier), ", .ctLightItalic)
      self += ("Zero Reference: \(decibels.zeroReference) }\n", .ctLightItalic)
    } else {
      self += ("No\n", .ctLightItalic)
    }

  }

  /// Appends a description for feature normalization settings.
  ///
  /// - Parameters:
  ///   - normalization: The settings to describe or `nil` if normalization was not applied.
  ///   - indent: The number of spaces that should be prepended to each line.
  public func append(normalizationSettings normalization: NormalizationSettings?, indent: Int = 0) {

    // Append a description of `normalization`.
    self += ("\(" " * indent)Normalization: ", .ctMediumItalic)

    switch normalization {

      case .maxValue?:
        self += ("Max Value\n", .ctLightItalic)

      case .lᵖNorm(let space, let threshold)?:
        self += ("{ Space: \(space), Threshold: \(threshold) }\n", .ctLightItalic)

      case nil:
        self += ("No\n", .ctLightItalic)

    }

  }

  /// Appends a description for feature quantization settings.
  ///
  /// - Parameters:
  ///   - quantization: The settings to describe.
  ///   - indent: The number of spaces that should be prepended to each line.
  public func append(quantizationSettings quantization: QuantizationSettings, indent: Int = 0) {

    // Append a description of `quantization`.
    self += ("\(" " * indent)Quantization: ", .ctMediumItalic)

    // Create a string with step values.
    let steps = quantization.steps.map({String(format: "%.2lf", $0)}).joined(separator: ", ")

    // Create a string with the weight values.
    let weights = quantization.weights.map({String(format: "%.2lf", $0)}).joined(separator: ", ")

    self += ("{ Steps: [\(steps)], Weights: [\(weights)] }\n", .ctLightItalic)

  }

  /// Appends a description for feature smoothing settings.
  ///
  /// - Parameters:
  ///   - smoothing: The settings to describe or `nil` if smoothing was not applied.
  ///   - indent: The number of spaces that should be prepended to each line.
  public func append(smoothingSettings smoothing: SmoothingSettings?, indent: Int = 0) {

    // Append a description of `smoothing`.
    self += ("\(" " * indent)Smoothing: ", .ctMediumItalic)

    if let smoothing = smoothing {
      self += ("{ Window Size: \(smoothing.windowSize), ", .ctLightItalic)
      self += ("Downsample Factor: \(smoothing.downsampleFactor) }\n", .ctLightItalic)
    } else {
      self += ("No\n", .ctLightItalic)
    }

  }

  /// Appends a description for a feature coefficient range.
  ///
  /// - Parameters:
  ///   - coefficients: The range of coefficients to describe.
  ///   - indent: The number of spaces that should be prepended to each line.
 public func append(coefficients: CountableRange<Int>, indent: Int = 0) {

    // Append a description of `coefficients`.
    self += ("\(" " * indent)Coefficients: ", .ctMediumItalic)
    self += ("\(coefficients.lowerBound) - \(coefficients.upperBound - 1)\n", .ctLightItalic)

  }

  /// Appends a description for a chroma feature variant.
  ///
  /// - Parameters:
  ///   - variant: The chroma feature variant to describe.
  ///   - indent: The number of spaces that should be prepended to each line.
  public func append(variant: ChromaFeatures.Variant, indent: Int = 0) {

    // Append a description of the `variant`.
    self += ("\(" " * indent)Variant: ", .ctMediumItalic)

    switch variant {

      case .CP(compression: let compression, normalization: let normalization):

        // Append the kind of variant.
        self += ("CP\n", .ctLightItalic)

        // Append a description of `compression`.
        append(compressionSettings: compression, indent: indent + 4)

        // Append a description of `normalization`.
        append(normalizationSettings: normalization, indent: indent + 4)

      case .CENS(quantization: let quantization, smoothing: let smoothing):

        // Append the kind of variant.
        self += ("CENS\n", .ctLightItalic)

        // Append a description of `quantization`.
        append(quantizationSettings: quantization, indent: indent + 4)

        // Append a description of `smoothing`.
        append(smoothingSettings: smoothing, indent: indent + 4)

      case .CRP(coefficients: let coefficients, smoothing: let smoothing):

        // Append the kind of variant.
        self += ("CRP\n", .ctLightItalic)

        // Append a description of `coefficients`.
        append(coefficients: coefficients, indent: indent + 4)

        // Append a description of `smoothing`.
        append(smoothingSettings: smoothing, indent: indent + 4)

    }

  }

  /// Appends a right-aligned frame label.
  ///
  /// - Parameter frame: The frame number.
  public func append(frame: Int) {

    // Create the frame label
    let frameLabel = "Frame \(frame)"

    // Calculate how many spaces should go before the frame label.
    let frameLabelPad = ReportRenderer.columnCount - frameLabel.count

    // Append the padded frame label to `self`.
    self += ("\(" " * frameLabelPad)\(frameLabel)\n", .ctMediumItalic)

  }

  /// Appends the values of the vector for the specified template with the template's chromas 
  /// bolded.
  ///
  /// - Parameter template: The template with values to append.
  public func append(template: ChromaTemplate) {

    // Create the straight line between corners.
    let line = "─" * (ReportRenderer.columnCount - 2)

    // Append the box top.
    self += ("┌\(line)┐\n│", .ctRegular)

    // Get the indices for the vector's top `boldCount` values.
    let boldIndices = Set(template.chord.chromas.map({$0.rawValue}))

    // Create the line of chroma labels.
    for chroma in 0 ..< 12 {

      // Create a description the chroma.
      var chromaDesc = Chroma(rawValue: chroma).description

      // Make all chroma descriptions two characters wide.
      if chromaDesc.count == 1 { chromaDesc = " " + chromaDesc }

      // Append the chroma description with font weighted by whether it is a top three chroma.
      self += ("   \(chromaDesc)   ", (boldIndices.contains(chroma) ? .ctBlack : .ctThin))

    }

    // End the previous line,add another separator and begin the next line.
    self += ("│\n├\(line)┤\n│  ", .ctRegular)

    // Iterate over the vector indices up to the last.
    for index in 0..<11 {

      // Create a string with the value for this index.
      let valueDesc = String(format: "%5.3lf   ", template.vector[index])

      // Add the value's description with font weighted by whether this is a top three value.
      self += (valueDesc, (boldIndices.contains(index) ? .ctBlack : .ctRegular))

    }

    // Create a string with the value for the last index.
    let valueDesc = String(format: "%5.3lf │\n", template.vector[11])

    // Add the value's description with font weighted by whether this is a top three value.
    self += (valueDesc, (boldIndices.contains(11) ? .ctBlack : .ctRegular))

    // Append a bottom separator and a blank line.
    self += ("└\(line)┘\n", .ctRegular)

  }

  /// Appends the values of a chroma vector within a single column box below a header. The top
  /// `boldCount` values will be bolded along with their corresponding header.
  ///
  /// - Parameters:
  ///   - vector: The vector of values to append.
  ///   - boldCount: The number of values to make bold.
  public func append(vector: ChromaVector, boldCount: Int) {

    // Get the indices for the vector's top `boldCount` values.
    let boldIndices = Set(vector.indicesByValue[0..<max(0, boldCount)])

    // Append using the method that takes the indices.
    append(vector: vector, boldIndices: boldIndices)

  }

  /// Appends the values of a chroma vector within a single column box below a header. Chroma that
  /// are included in `boldIndices` will have their header and value bolded.
  ///
  /// - Parameters:
  ///   - vector: The vector of values to append.
  ///   - boldIndices: The indices for chroma to bold.
  public func append(vector: ChromaVector, boldIndices: Set<Int>) {

    // Create the straight line between corners.
    let line = "─" * (ReportRenderer.columnCount - 2)

    // Append the box top.
    self += ("┌\(line)┐\n│", .ctRegular)

    // Create the line of chroma labels.
    for chroma in 0 ..< 12 {

      // Create a description the chroma.
      var chromaDesc = Chroma(rawValue: chroma).description

      // Make all chroma descriptions two characters wide.
      if chromaDesc.count == 1 { chromaDesc = " " + chromaDesc }

      // Append the chroma description with font weighted by whether it is a top three chroma.
      self += ("   \(chromaDesc)   ", (boldIndices.contains(chroma) ? .ctBlack : .ctThin))

    }

    // End the previous line,add another separator and begin the next line.
    self += ("│\n├\(line)┤\n│  ", .ctRegular)

    // Iterate over the vector indices up to the last.
    for index in 0..<11 {

      // Create a string with the value for this index.
      let valueDesc = String(format: "%5.3lf   ", vector[index])

      // Add the value's description with font weighted by whether this is a top three value.
      self += (valueDesc, (boldIndices.contains(index) ? .ctBlack : .ctRegular))

    }

    // Create a string with the value for the last index.
    let valueDesc = String(format: "%5.3lf │\n", vector[11])

    // Add the value's description with font weighted by whether this is a top three value.
    self += (valueDesc, (boldIndices.contains(11) ? .ctBlack : .ctRegular))

    // Append a bottom separator and a blank line.
    self += ("└\(line)┘\n", .ctRegular)

  }
  
/*
  /// Appends a description of the tuple of possible root chromas.
  ///
  /// - Parameter possibleRoots: The tuple for which to append a description.
  public func append(possibleRoots: PossibleRoots) {

    self += ("(pos: ", .ctThin)
    self += ("\(possibleRoots.byFrequency)", .ctLight)
    self += (", count: ", .ctThin)
    self += ("\(possibleRoots.byCount)", .ctLight)
    self += (", energy: ", .ctThin)
    self += ("\(possibleRoots.byEnergy)", .ctLight)
    self += (", avg: ", .ctThin)
    self += ("\(possibleRoots.averaged)", .ctLight)
    self += (")", .ctThin)

  }
*/

  /// Appends the values of a pitch vector within a double column box below a header. The top
  /// `boldCount` values will be bolded.
  ///
  /// - Parameters:
  ///   - vector: The vector of values to append.
  ///   - boldCount: The number of values to make bold. This number should be divisible by `3`.
  ///   - boldLabel: An index of the label to make bold or `nil`.
  ///   - italicLabel: An index of a label to make italic or `nil`.
  ///   - underlineLabel: An index of a label to underline or `nil`.
  ///   - doubleUnderlineLabel: An index of a label to double underline or `nil`.
  public func append(vector: PitchVector,
                     boldCount: Int,
                     boldLabel: Int? = nil,
                     italicLabel: Int? = nil,
                     underlineLabel: Int? = nil,
                     doubleUnderlineLabel: Int? = nil)
  {

    // Create the straight line between corners.
    let line86 = "─" * 86
    let line9 = "─" * 9

    // Append a line separating the frame label from the column headers.
    self += ("┌\(line9)┬\(line86)┐\n│ ", .ctRegular)

    // Append the octave column header.
    self += ("Octave", .ctThin)

    // Append a separator.
    self += ("  │", .ctRegular)

    // Create an array for holding the sum of the values for each chroma.
    var sums = Array<Float64>(repeating: 0, count: 12)

    // Create the line of chroma labels.
    for rawChroma in 0 ..< 12 {

      // Create a chroma using `rawChroma`.
      let chroma = Chroma(rawValue: rawChroma)

      // Create a description the chroma.
      var chromaDesc = chroma.description

      // Make all chroma descriptions two characters wide.
      if chromaDesc.count == 1 { chromaDesc = " " + chromaDesc }

      let labelStyle: FontStyle

      switch (boldLabel, italicLabel) {
        case let (b, i) where b == i && b == rawChroma: labelStyle = .ctBlackItalic
        case let (b, _) where b == rawChroma:           labelStyle = .ctBlack
        case let (_, i) where i == rawChroma:           labelStyle = .ctItalic
        default:                                        labelStyle = .ctThin
      }

      // Append the chroma description with font weighted by whether it is a top three chroma.
      self += ("   \(chromaDesc)  ", labelStyle)

      if let underlineLabel = underlineLabel, rawChroma == underlineLabel {

        let range = NSRange(location: length - 2 - chroma.description.count,
                            length: chroma.description.count)
        addAttribute(.underlineStyle,
                     value: NSUnderlineStyle.styleSingle.rawValue,
                     range: range)

      }

      if let doubleUnderlineLabel = doubleUnderlineLabel, rawChroma == doubleUnderlineLabel {

        let range = NSRange(location: length - 2 - chroma.description.count,
                            length: chroma.description.count)
        addAttribute(.underlineStyle,
                     value: NSUnderlineStyle.styleDouble.rawValue,
                     range: range)

      }
      
    }

    // End the previous line,add another separator.
    self += ("  │\n├\(line9)┼\(line86)┤\n", .ctRegular)

    // Get the indices of `vector` ranked from highest to lowest.
    let sortedIndices = vector.indicesByValue

    // Get the number of values per tier.
    let tierCount = boldCount / 3

    // Group the top five indices.
    let tier1Indices = Set(sortedIndices[0..<tierCount])

    // Group the five indices that follow the top five.
    let tier2Indices = Set(sortedIndices[tierCount..<(boldCount - tierCount)])

    // Group the five indices that follow the five that follow the top five.
    let tier3Indices = Set(sortedIndices[(boldCount - tierCount)..<boldCount])

    // Iterate the C pitches in the vector.
    for cPitch in stride(from: 0, to: 128, by: 12) {

      // Check that at least one of the values for this octave will show a digit besides `0`.
      let octaveValues = cPitch == 120
        ? vector[cPitch..<(cPitch + 8)]
        : vector[cPitch..<(cPitch + 12)]

      // Skip this octave if there isn't a value worth showing.
      guard octaveValues.first(where: {$0 > 0.0009}) != nil else { continue }

      // Append the left bar and pad.
      self += ("│   ", .ctRegular)

      // Calculate the octave.
      let octave = cPitch / 12 - 1

      // Create a label for the octave.
      let octaveDesc = String(format: "%2li", octave)

      // Append the octave.
      self += (octaveDesc, .ctThin)

      // Append a separator.
      self += ("    │  ", .ctRegular)

      // Iterate the pitches for this octave.
      for pitch in cPitch..<(cPitch + octaveValues.count) {

        // Get the value.
        let value = vector[pitch]

        // Add the value to the running sum.
        sums[pitch % 12] += value

        // Create a string with the value for this index.
        let valueDesc = String(format: "%5.3lf  ", value)

        // Append `valueDesc` weighted by the membership of `indexʹ`.
        if tier1Indices.contains(pitch) { self += (valueDesc, .ctBlack) }
        else if tier2Indices.contains(pitch) { self += (valueDesc, .ctBold) }
        else if tier3Indices.contains(pitch) { self += (valueDesc, .ctMedium) }
        else if vector[pitch] > 0.0009 { self += (valueDesc, .ctLight) }
        else { self += (valueDesc, .ctThin) }

      }

      if octave == 9 {

        // Pad the final line and terminate it.
        self += ("\(" " * 28)│\n", .ctRegular)

      } else {

        // Terminate the line.
        self += ("│\n", .ctRegular)

      }

    }

    // Append a separator for the row of sums and start the next line.
    self += ("├\(line9)┼\(line86)┤\n│  ", .ctRegular)

    // Append the label for the row of sums.
    self += ("Total", .ctThin)

    // Append the separator between the label and sums.
    self += ("  │  ", .ctRegular)

    // Iterate the sums.
    for sum in sums {

      // Append the sum.
      self += ("\(String(format: "%5.3lf ", sum)) ", .ctRegular)

    }

    // End the row of sums and close the bottom of the box.
    self += ("│\n└\(line9)┴\(line86)┘\n", .ctRegular)

  }

  /// Appends a description of the specified date.
  ///
  /// - Parameter date: The date whose description is to be appended.
  public func append(date: Date) {

    // Create and configure a date formatter.
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .short
    dateFormatter.timeStyle = .short

    // Create a description for the current date and time.
    let dateDescription = dateFormatter.string(from: date)

    // Append the date description.
    self += (dateDescription, .ctExtraLight)

  }

}
