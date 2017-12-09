//
//  PitchReport.swift
//  Chord Finder
//
//  Created by Jason Cardwell on 8/22/17.
//  Copyright (c) 2017 Moondeer Studios. All rights reserved.
//
import Foundation

/// A structure that generates reports focused on a collection of pitch features.
public struct PitchReport: Report, ReportContentProvider {

  /// The pitch features serving as the report's subject.
  public let features: PitchFeatures

  /// The most likely root chroma per frame.
//  public let mostLikelyRoots: [PossibleRoots]

  /// The source from which `pitchFeatures` were extracted.
  public let source: Features.Source

  /// The parameters used to extract `features`.
  public var parameters: PitchFeatures.Parameters { return features.parameters }

  /// The total number of feature frames.
  public var totalFrames: Int { return features.count }

  /// A flag indicating whether the report should be detailed or brief.
  public var isBrief: Bool

  /// Whether the report includes an overview section.
  public var hasOverview: Bool { return false }

  /// Whether the report includes a figure.
  public var hasFigure: Bool { return true }
  
  /// Default initializer.
  ///
  /// - Parameters:
  ///   - features: The pitch features for the report.
  ///   - source: The source of `features`.
  ///   - isBrief: Whether the report should be brief.
  public init(features: PitchFeatures,
              source: Features.Source,
              isBrief: Bool = false)
  {
    self.features = features
//    mostLikelyRoots = features.mostLikelyRoots
    self.source = source
    self.isBrief = isBrief
  }

  /// Generates a header describing the source of the pitch features, frame count, frame rate, etc.
  ///
  /// - Returns: An attributed string with the header.
  public func generateHeader() -> NSAttributedString {

    // Create an attributed string with the header.
    let text = NSMutableAttributedString(string: "Pitch features extracted from ", style: .black)

    // Append a description of the pitch feature source.
    text.append(featureSource: source)

    // Append a newline character.
    text += "\n"

    // Append a line dividing the header and subtext.
    text.appendLine()

    // Append the frame count, feature rate, and parameters.
    text.appendInfo(for: features)

    return text

  }

  /// Generates a table of pitch values from the vector for the specified frame.
  ///
  /// - Parameters:
  ///   - frame: The frame index for the vector of pitch values.
  /// - Returns: An attributed string with the table of pitch values.
  public func generateContent(frame: Int) -> NSAttributedString {

    // Create a string for accumulating the text to draw.
    let text = NSMutableAttributedString()

    // Append a frame label
    text.append(frame: frame)

//    let possibleRoots = mostLikelyRoots[frame]

    // Append the pitch feature values in a two column box with three tiers of bolded values.
    text.append(vector: features[frame],
                boldCount: 15//,
//                boldLabel: possibleRoots.byCount.rawValue,
//                italicLabel: possibleRoots.byEnergy.rawValue,
//                underlineLabel: possibleRoots.averaged.rawValue,
//                doubleUnderlineLabel: possibleRoots.byFrequency.chroma.rawValue
    )

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

  /// Generates a spectrogram for the pitch features.
  ///
  /// - Returns: The image containing the spectrogram.
  public func generateFigures() -> [(Image, NSAttributedString?)]? {

    // Establish a threshold for values of significance.
    let threshold = 0.05

    // Create a variable to hold the lowest pitch with energy ≥ `threshold`.
    var lowestPitch = 128

    // Iterate through raw pitch values from lowest to highest.
    low: for pitch in 0 ..< 128 {

      // Iterate through the frames.
      for frame in 0 ..< features.count {

        // Check that the energy for `pitch` in `frame` is lower than `threshold`.
        guard features[frame][pitch] < threshold else {

          // The energy is ≥ `threshold`, store the pitch as the lowest to plot.
          lowestPitch = pitch

          // Break out since the lowest pitch has been determined.
          break low

        }

      }

    }

    // Create a variable to hold the highest pitch with energy ≥ `threshold`.
    var highestPitch = -1

    // Iterate through raw pitch values from highest to lowest.
    high: for pitch in (0 ..< 128).reversed() {

      // Iterate through the frames.
      for frame in 0 ..< features.count {

        // Check that the energy for `pitch` in `frame` is lower than `threshold`.
        guard features[frame][pitch] < threshold else {

          // The energy is ≥ `threshold`, store the pitch as the highest to plot.
          highestPitch = pitch

          // Break out since the highest pitch has been determined.
          break high

        }

      }
      
    }

    // Ensure the lowest and highest pitches form a valid range.
    guard lowestPitch <= highestPitch else {

      // Generate a full plot.
      let figure = pitchPlot(features: features)

      // Create the title.
      let title = NSAttributedString(string: "Spectrogram of Extracted Features",
                                     style: .mediumCentered)

      // Return the plot and the title.
      return [(figure, title)]

    }

    // Generate the pitch range from the raw pitch values.
    let range = Pitch(rawValue: lowestPitch)...Pitch(rawValue: highestPitch)

    // Generate the plot of pitches in `range`.
    let figure = pitchPlot(features: features, range: range)

    // Create the title.
    let title = NSAttributedString(string: "Spectrogram of Extracted Features (\(range.lowerBound)" +
                                            " through \(range.upperBound))",
                                   style: .lightCentered)

    // Return the figure and the title
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
    text += ("Pitch Report for ", .extraLight)

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
