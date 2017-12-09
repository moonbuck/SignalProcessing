//
//  AttributedStringContent.swift
//  Chord Finder
//
//  Created by Jason Cardwell on 8/31/17.
//  Copyright (c) 2017 Moondeer Studios. All rights reserved.
//
import Foundation

#if os(iOS)
  import UIKit
#else
  import AppKit
#endif

extension NSAttributedString {

  /// Invokes `attributedSubstring(from:)` with a range derived from `location` and the length
  /// of the attributed string.
  ///
  /// - Parameter location: The location denoting the first character in the return substring.
  /// - Returns: The substring from `location` to the end of the string.
  public func attributedSubstring(from location: Int) -> NSAttributedString {

    return attributedSubstring(from: NSRange(location: location, length: length - location))

  }

  /// The full range of the attributed string's text.
  public var textRange: NSRange { return NSRange(location: 0, length: length) }

  /// Whether the string's content consists only of whitespace and/or newline characters.
  public var isWhitespace: Bool {

    let whitespaceCharacterSet = CharacterSet.whitespacesAndNewlines

    for unicodeScalar in string.unicodeScalars {

      guard whitespaceCharacterSet.contains(unicodeScalar) else { return false }

    }

    return true

  }

}

/// Extension of mutable attributed strings with functions used by various report content providers.
extension NSMutableAttributedString {

  /// Appends a string to the attributed string using the specified attributes or without 
  /// attributes if the parameter is `nil`..
  ///
  /// - Parameters:
  ///   - string: The string to append.
  ///   - attributes: The attributes for `string` or `nil`.
  public func append(_ string: String, attributes:  [NSAttributedStringKey:Any]? = nil) {
    append(NSAttributedString(string: string, attributes: attributes))
  }

  /// Appends a string to the attributed string.
  ///
  /// - Parameters:
  ///   - lhs: The attributed string to which `rhs` will be appended.
  ///   - rhs: The string to append to `lhs`.
  public static func += (lhs: NSMutableAttributedString, rhs: String) {
    lhs.append(rhs)
  }

  /// Appends a string to an attributed string using the specified attributes.
  ///
  /// - Parameters:
  ///   - lhs: The attributed string to which `rhs.0` will be appended with attributes `rhs.1`.
  ///   - rhs: The tuple containing the string and attributes to be appended to `lhs`.
  public static func +=(lhs: NSMutableAttributedString, rhs: (String, [NSAttributedStringKey:Any])) {
    lhs.append(rhs.0, attributes: rhs.1)
  }

  /// Appends a description for the source of extracted features.
  ///
  /// - Parameter featureSource: The source to describe.
  public func append(featureSource: Features.Source) {

    // Append a description of the chroma feature source.
    switch featureSource {

    case .mic:
      self += ("audio input", .black)

    case .file(url: let url):
      self += (url.lastPathComponent, .extraLightItalic)

    }

  }

  /// Appends a horizontal line.
  public func appendLine() {

    self += ("\("─" * ReportRenderer.columnCount)\n", .bold)

  }

  /// Appends a double horizontal line.
  public func appendDoubleLine() {

    self += ("\("═" * ReportRenderer.columnCount)\n", .bold)

  }

  /// Appends descriptions for the frame count, feature rate, and parameters of a collection
  /// of chroma features.
  ///
  /// - Parameter chromaFeatures: The features for which a description is to be appended.
  public func appendInfo(for chromaFeatures: ChromaFeatures) {

    // Append the frame count.
    self += ("# Frames: ", .mediumItalic)
    self += ("\(chromaFeatures.count)\n", .lightItalic)

    // Append the feature rate.
    self += ("Feature Rate: ", .mediumItalic)
    self += ("\(chromaFeatures.featureRate) Hz\n", .lightItalic)

    // Append the parameters.
    append(parameters: chromaFeatures.parameters)

  }

  /// Appends a description of chroma feature parameters that includes the pitch feature parameters
  /// and the chroma variant.
  ///
  /// - Parameter parameters: The parameters for which to append a description.
  public func append(parameters: ChromaFeatures.Parameters, indent: Int = 0) {

    // Introduce the pitch feature parameters and start a new line.
    self += ("\(" " * indent)Pitch Feature Parameters:\n", .mediumItalic)

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
    self += ("# Frames: ", .mediumItalic)
    self += ("\(pitchFeatures.count)\n", .lightItalic)

    // Append the feature rate.
    self += ("Feature Rate: ", .mediumItalic)
    self += ("\(pitchFeatures.featureRate) Hz\n", .lightItalic)

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

    self += ("\(" " * indent)Filters:\(parameters.filters.isEmpty ? " None" : "")\n", .mediumItalic)

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

      }

    }


  }

  public func appendInfo(for features: Features) {

    // Append the frame count.
    self += ("Pitch Features:\n", .mediumItalic)
    self += ("    # Frames: ", .mediumItalic)
    self += ("\(features.pitchFeatures.count)\n", .lightItalic)

    // Append the feature rate.
    self += ("    Feature Rate: ", .mediumItalic)
    self += ("\(features.pitchFeatures.featureRate) Hz\n", .lightItalic)

    // Append the frame count.
    self += ("Smoothed Pitch/Chroma Features:\n", .mediumItalic)
    self += ("    # Frames: ", .mediumItalic)
    self += ("\(features.chromaFeatures.count)\n", .lightItalic)

    // Append the feature rate.
    self += ("    Feature Rate: ", .mediumItalic)
    self += ("\(features.chromaFeatures.featureRate) Hz\n", .lightItalic)

    // Append a description of the recipe.
    append(recipe: features.recipe)

  }

  /// Appends a description of the specified feature recipe.
  ///
  /// - Parameter recipe: The recipe for which a description shall be appended.
  public func append(recipe: Features.Recipe) {

    // Introduce the recipe and start a new line.
    self += ("Recipe:\n", .mediumItalic)

    // Introduce the pitch feature parameters and start a new line.
    self += ("    Pitch Feature Parameters:\n", .mediumItalic)

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
    self += ("\(" " * indent)Similarity Score Adjustments:", .medium)

    guard !scoreAdjustments.isEmpty else {

      self += (" None\n", .lightItalic)

      return

    }

    self += ("\n", .medium)


    for adjustment in scoreAdjustments {

      switch adjustment {

        case let .noteCount(matchingBonus):

          // Append an intro for the note count adjustment.
          self += ("\(" " * (indent + 4))Note Count Adjustment:\n", .mediumItalic)

          // Append the matching bonus.
          self += ("\(" " * (indent + 8))Matching Bonus: ", .italic)
          self += ("\(matchingBonus)\n", .lightItalic)

        case let .chordRoot(matching, penalty, threshold, bonus):

          // Append an intro for the chord root adjustment.
          self += ("\(" " * (indent + 4))Chord Root Adjustment:\n", .mediumItalic)

          // Append the matching bonus.
          self += ("\(" " * (indent + 8))Matching Bonus: ", .italic)
          self += ("\(matching)\n", .lightItalic)

          // Append the mismatch penalty.
          self += ("\(" " * (indent + 8))Mismatch Penalty: ", .italic)
          self += ("\(penalty)\n", .lightItalic)

          // Append the high energy threshold.
          self += ("\(" " * (indent + 8))High Energy Threshold: ", .italic)
          self += ("\(threshold)\n", .lightItalic)

          // Append the high energy bonus.
          self += ("\(" " * (indent + 8))High Energy Bonus: ", .italic)
          self += ("\(bonus)\n", .lightItalic)

        case let .energyDistribution(absent, matching, threshold, bonus, penalty):

          // Append an intro for the energy distribution adjustment.
          self += ("\(" " * (indent + 4))Energy Distribution Adjustment:\n", .mediumItalic)

          // Append the absent chroma threshold.
          self += ("\(" " * (indent + 8))Absent Chroma Threshold: ", .italic)
          self += ("\(absent)\n", .lightItalic)

          // Append the matching chroma bonus.
          self += ("\(" " * (indent + 8))Matching Chromas Bonus: ", .italic)
          self += ("\(matching)\n", .lightItalic)

          // Append the high energy threshold.
          self += ("\(" " * (indent + 8))High Energy Threshold: ", .italic)
          self += ("\(threshold)\n", .lightItalic)

          // Append the high energy bonus.
          self += ("\(" " * (indent + 8))High Energy Bonus: ", .italic)
          self += ("\(bonus)\n", .lightItalic)

          // Append the high energy penalty.
          self += ("\(" " * (indent + 8))High Energy Penalty: ", .italic)
          self += ("\(penalty)\n", .lightItalic)

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
    self += ("\(" " * indent)Extraction Method: ", .mediumItalic)

    // Initialize `methodDesc`.
    switch extractionMethod {

      case .stft(let p):
        self += ("STFT { Window Size: \(p.windowSize), Hop Size: \(p.hopSize) }\n", .lightItalic)

      case .filterbank(let p):
        self += ("Filterbank { Window Size: \(p.windowSize), Hop Size: \(p.hopSize) }\n", .lightItalic)

    }


  }

  /// Appends a description for feature compression settings.
  ///
  /// - Parameters:
  ///   - compression: The settings to describe or `nil` if compression was not applied.
  ///   - indent: The number of spaces that should be prepended to each line.
  public func append(compressionSettings compression: CompressionSettings?, indent: Int = 0) {

    // Append a description of `compression`.
    self += ("\(" " * indent)Logarithmic Compression: ", .mediumItalic)

    if let compression = compression {
      self += ("{ Term: \(compression.term), Factor: \(compression.factor) }\n", .lightItalic)
    } else {
      self += ("No\n", .lightItalic)
    }

  }

  /// Appends a description for feature normalization settings.
  ///
  /// - Parameters:
  ///   - normalization: The settings to describe or `nil` if normalization was not applied.
  ///   - indent: The number of spaces that should be prepended to each line.
  public func append(normalizationSettings normalization: NormalizationSettings?, indent: Int = 0) {

    // Append a description of `normalization`.
    self += ("\(" " * indent)Normalization: ", .mediumItalic)

    switch normalization {

      case .maxValue?:
        self += ("Max Value\n", .lightItalic)

      case .lᵖNorm(let space, let threshold)?:
        self += ("{ Space: \(space), Threshold: \(threshold) }\n", .lightItalic)

      case nil:
        self += ("No\n", .lightItalic)

    }

  }

  /// Appends a description for feature quantization settings.
  ///
  /// - Parameters:
  ///   - quantization: The settings to describe.
  ///   - indent: The number of spaces that should be prepended to each line.
  public func append(quantizationSettings quantization: QuantizationSettings, indent: Int = 0) {

    // Append a description of `quantization`.
    self += ("\(" " * indent)Quantization: ", .mediumItalic)

    // Create a string with step values.
    let steps = quantization.steps.map({String(format: "%.2lf", $0)}).joined(separator: ", ")

    // Create a string with the weight values.
    let weights = quantization.weights.map({String(format: "%.2lf", $0)}).joined(separator: ", ")

    self += ("{ Steps: [\(steps)], Weights: [\(weights)] }\n", .lightItalic)

  }

  /// Appends a description for feature smoothing settings.
  ///
  /// - Parameters:
  ///   - smoothing: The settings to describe or `nil` if smoothing was not applied.
  ///   - indent: The number of spaces that should be prepended to each line.
  public func append(smoothingSettings smoothing: SmoothingSettings?, indent: Int = 0) {

    // Append a description of `smoothing`.
    self += ("\(" " * indent)Smoothing: ", .mediumItalic)

    if let smoothing = smoothing {
      self += ("{ Window Size: \(smoothing.windowSize), ", .lightItalic)
      self += ("Downsample Factor: \(smoothing.downsampleFactor) }\n", .lightItalic)
    } else {
      self += ("No\n", .lightItalic)
    }

  }

  /// Appends a description for a feature coefficient range.
  ///
  /// - Parameters:
  ///   - coefficients: The range of coefficients to describe.
  ///   - indent: The number of spaces that should be prepended to each line.
 public func append(coefficients: CountableRange<Int>, indent: Int = 0) {

    // Append a description of `coefficients`.
    self += ("\(" " * indent)Coefficients: ", .mediumItalic)
    self += ("\(coefficients.lowerBound) - \(coefficients.upperBound - 1)\n", .lightItalic)

  }

  /// Appends a description for a chroma feature variant.
  ///
  /// - Parameters:
  ///   - variant: The chroma feature variant to describe.
  ///   - indent: The number of spaces that should be prepended to each line.
  public func append(variant: ChromaFeatures.Variant, indent: Int = 0) {

    // Append a description of the `variant`.
    self += ("\(" " * indent)Variant: ", .mediumItalic)

    switch variant {

      case .CP(compression: let compression, normalization: let normalization):

        // Append the kind of variant.
        self += ("CP\n", .lightItalic)

        // Append a description of `compression`.
        append(compressionSettings: compression, indent: indent + 4)

        // Append a description of `normalization`.
        append(normalizationSettings: normalization, indent: indent + 4)

      case .CENS(quantization: let quantization, smoothing: let smoothing):

        // Append the kind of variant.
        self += ("CENS\n", .lightItalic)

        // Append a description of `quantization`.
        append(quantizationSettings: quantization, indent: indent + 4)

        // Append a description of `smoothing`.
        append(smoothingSettings: smoothing, indent: indent + 4)

      case .CRP(coefficients: let coefficients, smoothing: let smoothing):

        // Append the kind of variant.
        self += ("CRP\n", .lightItalic)

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
    self += ("\(" " * frameLabelPad)\(frameLabel)\n", .mediumItalic)

  }

  /// Appends the values of the vector for the specified template with the template's chromas 
  /// bolded.
  ///
  /// - Parameter template: The template with values to append.
  public func append(template: ChromaTemplate) {

    // Create the straight line between corners.
    let line = "─" * (ReportRenderer.columnCount - 2)

    // Append the box top.
    self += ("┌\(line)┐\n│", .regular)

    // Get the indices for the vector's top `boldCount` values.
    let boldIndices = Set(template.chord.chromas.map({$0.rawValue}))

    // Create the line of chroma labels.
    for chroma in 0 ..< 12 {

      // Create a description the chroma.
      var chromaDesc = Chroma(rawValue: chroma).description

      // Make all chroma descriptions two characters wide.
      if chromaDesc.count == 1 { chromaDesc = " " + chromaDesc }

      // Append the chroma description with font weighted by whether it is a top three chroma.
      self += ("   \(chromaDesc)   ", (boldIndices.contains(chroma) ? .black : .thin))

    }

    // End the previous line,add another separator and begin the next line.
    self += ("│\n├\(line)┤\n│  ", .regular)

    // Iterate over the vector indices up to the last.
    for index in 0..<11 {

      // Create a string with the value for this index.
      let valueDesc = String(format: "%5.3lf   ", template.vector[index])

      // Add the value's description with font weighted by whether this is a top three value.
      self += (valueDesc, (boldIndices.contains(index) ? .black : .regular))

    }

    // Create a string with the value for the last index.
    let valueDesc = String(format: "%5.3lf │\n", template.vector[11])

    // Add the value's description with font weighted by whether this is a top three value.
    self += (valueDesc, (boldIndices.contains(11) ? .black : .regular))

    // Append a bottom separator and a blank line.
    self += ("└\(line)┘\n", .regular)

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
    self += ("┌\(line)┐\n│", .regular)

    // Create the line of chroma labels.
    for chroma in 0 ..< 12 {

      // Create a description the chroma.
      var chromaDesc = Chroma(rawValue: chroma).description

      // Make all chroma descriptions two characters wide.
      if chromaDesc.count == 1 { chromaDesc = " " + chromaDesc }

      // Append the chroma description with font weighted by whether it is a top three chroma.
      self += ("   \(chromaDesc)   ", (boldIndices.contains(chroma) ? .black : .thin))

    }

    // End the previous line,add another separator and begin the next line.
    self += ("│\n├\(line)┤\n│  ", .regular)

    // Iterate over the vector indices up to the last.
    for index in 0..<11 {

      // Create a string with the value for this index.
      let valueDesc = String(format: "%5.3lf   ", vector[index])

      // Add the value's description with font weighted by whether this is a top three value.
      self += (valueDesc, (boldIndices.contains(index) ? .black : .regular))

    }

    // Create a string with the value for the last index.
    let valueDesc = String(format: "%5.3lf │\n", vector[11])

    // Add the value's description with font weighted by whether this is a top three value.
    self += (valueDesc, (boldIndices.contains(11) ? .black : .regular))

    // Append a bottom separator and a blank line.
    self += ("└\(line)┘\n", .regular)

  }
  
/*
  /// Appends a description of the tuple of possible root chromas.
  ///
  /// - Parameter possibleRoots: The tuple for which to append a description.
  public func append(possibleRoots: PossibleRoots) {

    self += ("(pos: ", .thin)
    self += ("\(possibleRoots.byFrequency)", .light)
    self += (", count: ", .thin)
    self += ("\(possibleRoots.byCount)", .light)
    self += (", energy: ", .thin)
    self += ("\(possibleRoots.byEnergy)", .light)
    self += (", avg: ", .thin)
    self += ("\(possibleRoots.averaged)", .light)
    self += (")", .thin)

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
    self += ("┌\(line9)┬\(line86)┐\n│ ", .regular)

    // Append the octave column header.
    self += ("Octave", .thin)

    // Append a separator.
    self += ("  │", .regular)

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
        case let (b, i) where b == i && b == rawChroma: labelStyle = .blackItalic
        case let (b, _) where b == rawChroma:           labelStyle = .black
        case let (_, i) where i == rawChroma:           labelStyle = .italic
        default:                                        labelStyle = .thin
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
    self += ("  │\n├\(line9)┼\(line86)┤\n", .regular)

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
      self += ("│   ", .regular)

      // Calculate the octave.
      let octave = cPitch / 12 - 1

      // Create a label for the octave.
      let octaveDesc = String(format: "%2li", octave)

      // Append the octave.
      self += (octaveDesc, .thin)

      // Append a separator.
      self += ("    │  ", .regular)

      // Iterate the pitches for this octave.
      for pitch in cPitch..<(cPitch + octaveValues.count) {

        // Get the value.
        let value = vector[pitch]

        // Add the value to the running sum.
        sums[pitch % 12] += value

        // Create a string with the value for this index.
        let valueDesc = String(format: "%5.3lf  ", value)

        // Append `valueDesc` weighted by the membership of `indexʹ`.
        if tier1Indices.contains(pitch) { self += (valueDesc, .black) }
        else if tier2Indices.contains(pitch) { self += (valueDesc, .bold) }
        else if tier3Indices.contains(pitch) { self += (valueDesc, .medium) }
        else if vector[pitch] > 0.0009 { self += (valueDesc, .light) }
        else { self += (valueDesc, .thin) }

      }

      if octave == 9 {

        // Pad the final line and terminate it.
        self += ("\(" " * 28)│\n", .regular)

      } else {

        // Terminate the line.
        self += ("│\n", .regular)

      }

    }

    // Append a separator for the row of sums and start the next line.
    self += ("├\(line9)┼\(line86)┤\n│  ", .regular)

    // Append the label for the row of sums.
    self += ("Total", .thin)

    // Append the separator between the label and sums.
    self += ("  │  ", .regular)

    // Iterate the sums.
    for sum in sums {

      // Append the sum.
      self += ("\(String(format: "%5.3lf ", sum)) ", .regular)

    }

    // End the row of sums and close the bottom of the box.
    self += ("│\n└\(line9)┴\(line86)┘\n", .regular)

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
    self += (dateDescription, .extraLight)

  }

}
