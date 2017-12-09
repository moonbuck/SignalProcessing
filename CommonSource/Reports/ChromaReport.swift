//
//  ChromaReport.swift
//  Chord Finder
//
//  Created by Jason Cardwell on 8/22/17.
//  Copyright (c) 2017 Moondeer Studios. All rights reserved.
//
import Foundation

/// A structure that generates reports focused on a collection of chroma features.
public struct ChromaReport: Report, ReportContentProvider {

  /// The chroma features serving as the report's subject.
  public let features: ChromaFeatures

  /// The source from which `chromaFeatures` were extracted.
  public let source: Features.Source

  /// The recipe used to create `features`.
  public let recipe: Features.Recipe

  /// A flag indicating whether the report should be detailed or brief.
  public var isBrief: Bool

  /// Whether the report includes an overview section.
  public var hasOverview: Bool { return false }

  /// Whether the report includes a figure.
  public var hasFigure: Bool { return true }

  /// The total number of feature frames.
  public var totalFrames: Int { return features.count }

  /// Default initializer.
  ///
  /// - Parameters:
  ///   - features: The chroma features for the report.
  ///   - source: The source of `features`.
  ///   - recipe: The recipe used to create `features`.
  ///   - isBrief: Whether the report should be brief.
  public init(features: ChromaFeatures,
              source: Features.Source,
              recipe: Features.Recipe,
              isBrief: Bool = false)
  {
    self.features = features
    self.source = source
    self.recipe = recipe
    self.isBrief = isBrief
  }

  /// Generates a header describing the source of the chroma features, frame count, frame rate, etc.
  ///
  /// - Returns: An attributed string with the header.
  public func generateHeader() -> NSAttributedString {

    // Create an attributed string with the header.
    let text = NSMutableAttributedString(string: "Chroma features extracted from ", style: .black)

    // Append a description of the chroma feature source.
    text.append(featureSource: source)

    // Append a new line character.
    text += "\n"

    // Append a line dividing the header and subtext.
    text.appendLine()

    // Append the frame count, feature rate and parameters.
    text.appendInfo(for: features)

    return text

  }

  /// Generates a table of chroma values from the vector for the specified frame.
  ///
  /// - Parameters:
  ///   - frame: The frame index for the vector of chroma values.
  /// - Returns: An attributed string with the table of chroma values.
  public func generateContent(frame: Int) -> NSAttributedString {

    // Create a string for accumulating the text to draw.
    let text = NSMutableAttributedString()

    // Append a frame label
    text.append(frame: frame)

    // Append the chroma vector values with the top three values bolded.
    text.append(vector: features[frame], boldCount: 3)

    // Append an attribute to keep the frame label and table on the same page.
    text.addAttribute(NSAttributedStringKey(rawValue: ReportRenderer.samePageAttributeName), value: true, range: text.textRange)

    // Append a blank line.
    text += "\n"

    return text

  }

  /// There is no overview so this function returns `nil`.
  ///
  /// - Returns: `nil`
  public func generateOverview() -> NSAttributedString? { return nil }

  /// Generates a spectrogram for the chroma features.
  ///
  /// - Returns: The image containing the spectrogram.
  public func generateFigures() -> [(Image, NSAttributedString?)]? {

    let colorMap: ColorMap

    switch recipe.chromaVariant {
      case .CRP: colorMap = ColorMap(size: .s128)
      default:   colorMap = ColorMap(size: .s64)
    }

    // Generate the plot of chroma features.
    let figure = chromaPlot(features: features, colorMap: colorMap)

    // Create the title.
    let title = NSAttributedString(string: "Chromagram of Extracted Features",
                                   style: .lightCentered)

    // Return the figure and the title.
    return [(figure, title)]
    
  }

  /// Generates content for the page footer for the specified page or `nil`.
  ///
  /// - Parameter page: The page number of the page for which to generate the header.
  /// - Returns: The content for the page header or `nil`.
  public func generateHeader(forPage page: Int) -> NSAttributedString? {

    // Create an empty attributed string.
    let text = NSMutableAttributedString()

    // Append lead in text for the report's source.
    text += ("Chroma Report for ", .extraLight)

    // Append the source of the report.
    switch source {
      case .mic:                text += ("Captured Audio", .extraLight)
      case .file(url: let url): text += (url.lastPathComponent, .extraLightItalic)
    }

    // Append the lead in text for the date.
    text += (" generated ", .extraLight)

    // Append a description for the current date and time.
    text.append(date: Date())

    return text

  }
  
}

