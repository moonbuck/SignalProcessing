//
//  TemplateReport.swift
//  Chord Finder
//
//  Created by Jason Cardwell on 8/22/17.
//  Copyright (c) 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import MoonKit

#if os(iOS)
import struct UIKit.CGFloat
#else
import struct AppKit.CGFloat
#endif

public struct TemplateReport: Report, ReportContentProvider {

  /// The matched chroma features serving as the report's subject.
  public let features: MatchedChromaFeatures

  /// The actual chords present in `source`.
  public let expectedChords: ChordProgression

  /// A list of possible root chromas for each frame if provided.
//  public let mostLikelyRoots: [PossibleRoots]

  /// The source from which `chromaFeatures` were extracted.
  public let source: Features.Source

  /// Adjustments applied to similarity scores.
  public let scoreAdjustments: [ScoreAdjustment]

  /// The total number of feature frames.
  public var totalFrames: Int { return features.count }

  /// A flag indicating whether the report should be detailed or brief.
  public var isBrief: Bool

  /// Whether the report includes an overview section.
  public var hasOverview: Bool { return true }

  /// Whether the report includes a figure.
  public var hasFigure: Bool { return true }
  
  /// Default initializer.
  ///
  /// - Parameters:
  ///   - features: The chroma features for the report.
  ///   - source: The source of `features`.
  ///   - scoreAdjustments: Adjustments to apply to similarity scores.
  ///   - expectedChords: The actual chords present in `source`.
  ///   - isBrief: Whether the report should be brief.
  public init(features: ChromaFeatures,
              source: Features.Source,
              scoreAdjustments: [ScoreAdjustment],
              expectedChords: ChordProgression,
//              mostLikelyRoots: [PossibleRoots],
//              noteCountEstimates: [Int],
              isBrief: Bool = false)
  {
    self.features = MatchedChromaFeatures(features: features,
//                                          mostLikelyRoots: mostLikelyRoots,
//                                          noteCountEstimates: noteCountEstimates,
                                          scoreAdjustments: scoreAdjustments)
    self.source = source
    self.scoreAdjustments = scoreAdjustments
    self.expectedChords = expectedChords
//    self.mostLikelyRoots = mostLikelyRoots
    self.isBrief = isBrief
  }

  /// Generates a header describing the source of the chroma features, frame count, frame rate, etc.
  ///
  /// - Returns: An attributed string with the header.
  public func generateHeader() -> NSAttributedString {

    // Create an attributed string with the header.
    let text = NSMutableAttributedString(string: "Chroma features extracted from ", style: .ctBlack)

    // Append a description of the chroma feature source.
    text.append(featureSource: source)

    text += (" with matched and expected chord templates\n", .ctBlack)
    
    // Append a line dividing the header and subtext.
    text.appendLine()

    // Append the frame count, feature rate and parameters.
    text.appendInfo(for: features.features)

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

    // Append a separator.
    text.appendDoubleLine()

    // Mark the start of the same-page range.
    var rangeStart = 0

    // Try getting the actual notes played to generate the feature.
    let pitches = expectedChords.composition(forFrame: frame, frameRate: features.featureRate)

    // Append a label for the feature vector.
    text += ("Feature Vector", .ctThinItalic)

    // Create a variable for number of spaces to add before appending possible roots.
    var possiblesPad = -70

    // Create a description for the pitches.
    let pitchesDesc = pitches.map({$0.description}).joined(separator: "-")

    // Append the description of the pitches.
    text += (" \(pitchesDesc)", .ctExtraLightItalic)

    // Subtract the number of characters appended from `possiblesPad`.
    possiblesPad -= pitchesDesc.count + 1


    // Try obtaining the possible root chromas for this frame.
//    let possibles = mostLikelyRoots[frame]


    // Subtract the number of characters from the chroma descriptions.
//    possiblesPad -= possibles.byFrequency.description.count
//    possiblesPad -= possibles.byCount.description.count
//    possiblesPad -= possibles.byEnergy.description.count
//    possiblesPad -= possibles.averaged.description.count

    // Add the number of columns per line.
//    possiblesPad += ReportRenderer.columnCount

    // Append the spaces and the label for the possible roots.
//    text += ("\(" " * possiblesPad)Possible Roots: ", .ctThinItalic)

    // Append the possible root chroma values and end the line.
//    text.append(possibleRoots: possibles)

    // End the current line.
    text += "\n"

    // Convert the pitches to chroma indices.
    let boldIndices = Set(pitches.map({$0.chroma.rawValue}))

    // Append the feature vector with actual notes played appearing in bold type.
    text.append(vector: features.features[frame], boldIndices: boldIndices)

    // Keep the vector label and table together.
    text.addAttribute(NSAttributedStringKey(rawValue: ReportRenderer.samePageAttributeName),
                      value: true,
                      range: NSRange(location: rangeStart, length: text.length - rangeStart - 1))

    // Get the expected chord for `frame`.
    let expectedChord = expectedChords.chord(forFrame: frame, frameRate: features.featureRate)

    // Retrieve the score for the expected chord.
    guard let expectedChordScore = features.matchResults[frame].scores[expectedChord] else {
      fatalError("Invalid chord found in chord progression: \(expectedChord.name)")
    }

    // Get the chord that matched `features[frame]`.
    let (matchedChord, matchedScore) = features.matchResults[frame].maxScore

    if matchedChord == expectedChord {

      // Update the start of the range.
      rangeStart = text.length

      // Append a label introducing the matched chord template.
      text += ("Matched Expected Template ", .ctThinItalic)

      // Append the name of the matched chord.
      text += (matchedChord.name, .ctLight)

      // Append spaces to pad the score label and value.
      // `"Matched Template "` contains 17 characters
      // The score label and value will contain 11 characters.
      text += (" " * (ReportRenderer.columnCount - 37 - matchedChord.name.count), .ctRegular)

      // Append a label for the matched chord template's score.
      text += ("Score ", .ctThinItalic)

      // Append the matched chord template's score and end the line.
      text += (String(format: "%5.3lf\n", matchedScore), .ctLight)

      // Append the template vector for the matched chord.
      text.append(template: matchedChord.template)
      
      // Keep the template label and table together.
      text.addAttribute(NSAttributedStringKey(rawValue: ReportRenderer.samePageAttributeName),
                        value: true,
                        range: NSRange(location: rangeStart, length: text.length - rangeStart - 1))

    } else {

      // Update the start of the range.
      rangeStart = text.length

      // Append a label introducing the matched chord template.
      text += ("Matched Template ", .ctThinItalic)

      // Append the name of the matched chord.
      text += (matchedChord.name, .ctLight)

      // Append spaces to pad the score label and value.
      // `"Matched Template "` contains 17 characters
      // The score label and value will contain 11 characters.
      text += (" " * (ReportRenderer.columnCount - 28 - matchedChord.name.count), .ctRegular)

      // Append a label for the matched chord template's score.
      text += ("Score ", .ctThinItalic)

      // Append the matched chord template's score and end the line.
      text += (String(format: "%5.3lf\n", matchedScore), .ctLight)

      // Append the template vector for the matched chord.
      text.append(template: matchedChord.template)

      // Keep the template label and table together.
      text.addAttribute(NSAttributedStringKey(rawValue: ReportRenderer.samePageAttributeName),
                        value: true,
                        range: NSRange(location: rangeStart, length: text.length - rangeStart - 1))

      // Update the start of the range.
      rangeStart = text.length

      // Append a label introducing the expected chord template.
      text += ("Expected Template ", .ctThinItalic)

      // Append the name of the expected chord.
      text += (expectedChord.name, .ctLight)

      // Append spaces to pad the score label and value.
      // `"Expected Template "` contains 18 characters
      // The score label and value will contain 11 characters.
      text += (" " * (ReportRenderer.columnCount - 29 - expectedChord.name.count), .ctRegular)

      // Append a label for the expected chord template's score.
      text += ("Score ", .ctThinItalic)

      // Append the expected chord template's score and end the line.
      text += (String(format: "%5.3lf\n", expectedChordScore), .ctLight)

      // Append the template vector for the expected chord.
      text.append(template: expectedChord.template)

      // Keep the expected label and table together.
      text.addAttribute(NSAttributedStringKey(rawValue: ReportRenderer.samePageAttributeName),
                        value: true,
                        range: NSRange(location: rangeStart, length: text.length - rangeStart))

    }

    // Append a blank line.
    text += "\n"

    return text
    
  }

  /// Generates an attributed string with a table of frame-matched-expected triplets.
  ///
  /// - Returns: The generated string.
  public func generateOverview() -> NSAttributedString? {

    // Create an attributed string.
    let text = NSMutableAttributedString()

    // Append the score adjustments.
    text.append(scoreAdjustments: scoreAdjustments)

    // Append a blank line.
    text += "\n"

    // Append a line to introduce the table to follow.
    text += ("Overview of Matched Chords by Frame:\n", .ctMedium)

    // Create variables to track true and false positives, as well as false negatives.
    var TP = 0, FP = 0, FN = 0

    // Establish the number of characters between box lines for two colunn sizes.
    let frameCharCount = 18
    let nameCharCount = 38

    // Create the lines that connect horizontally.
    let nameLine = "─" * nameCharCount
    let frameLine = "─" * frameCharCount

    // Append the top of the box.
    text += ("┌\(frameLine)┬\(nameLine)┬\(nameLine)┐\n", .ctRegular)

    // Append the left bar for the column headers.
    text += ("│\(" " * 6)", .ctRegular)

    // Append the header for the frame column.
    text += ("Frame", .ctThin)

    // Append the next bar.
    text += ("\(" " * 7)│\(" " * 11)", .ctRegular)

    // Append the matched template column header.
    text += ("Matched Template", .ctThin)

    // Append the next bar.
    text += ("\(" " * 11)│\(" " * 13)", .ctRegular)

    // Append the expected chord column header.
    text += ("Actual Chord", .ctThin)

    // Append the last bar and end the header line.
    text += ("\(" " * 13)│\n", .ctRegular)

    // Append the line separating the headers from the values.
    text += ("├\(frameLine)┼\(nameLine)┼\(nameLine)┤\n", .ctRegular)

    // Iterate the match results the matched and actual chords.
    for (frame, matchResults) in features.enumerated() {

      // Get the match and its score.
      let (match, score) = matchResults.maxScore

      // Get the expected chord for `frame`.
      let actual = expectedChords.chord(forFrame: frame, frameRate: features.featureRate)

      // Determine whether the matched chord is correct.
      let isCorrect = match == actual

      // Increment `TP`, `FP`, or `FN` according to whether `match == actual` and the score.
      if isCorrect { TP += 1 } else if score == 0 { FN += 1 } else { FP += 1 }

      // Create a label for the frame.
      let frameLabel = "\(frame)"

      // Determine the required number of spaces.
      let frameSpaces = frameCharCount - frameLabel.count

      // Append the left bar and half the frame spaces.
      text += ("│\(" " * (frameSpaces/2))", .ctRegular)

      // Append the frame label.
      text += (frameLabel, .ctThin)

      // Append the rest of the frame spaces and another bar.
      text += ("\(" " * (frameSpaces - frameSpaces/2))│", .ctRegular)

      // Get the matched chord description.
      let matchedDesc = match.name

      // Determine the required number of spaces.
      let matchedSpaces = nameCharCount - matchedDesc.count

      // Append half the matched spaces.
      text += (" " * (matchedSpaces/2), .ctRegular)

      // Append the matched chord description.
      text += (matchedDesc, isCorrect
                              ? .ctBold
                              : match.template.vector == actual.template.vector
                                  ? .ctThinItalic
                                  : .ctLight)

      // Append the rest of the matched spaces and another bar.
      text += ("\(" " * (matchedSpaces - matchedSpaces/2))│", .ctRegular)

      // Try getting the chord composition for the actual chord.
      let composition = expectedChords.composition(forFrame: frame, frameRate: features.featureRate)

      // create a description of the actual chord.
      let actualDesc = "\(actual.name)(\(composition.map({$0.description}).joined(separator: "-")))"

      // Determine the required number of spaces.
      let actualSpaces = nameCharCount - actualDesc.count

      // Append half the actual spaces.
      text += (" " * (actualSpaces/2), .ctRegular)

      // Append the actual chord's description.
      text += (actualDesc, .ctLight)

      // Append the rest of the actual spaces, another bar, and end the line.
      text += ("\(" " * (actualSpaces - actualSpaces/2))│\n", .ctRegular)

    }

    // Append the bottom of the box.
    text += ("└\(frameLine)┴\(nameLine)┴\(nameLine)┘\n", .ctRegular)

    // Calculate the F score.
    let fScore = Fscore(TP: TP, FP: FP, FN: FN)

    // Append the F score label.
    text += ("F Score: ", .ctThinItalic)

    // Append the F score.
    text += ("\(String(format: "%.3f", fScore))", .ctLight)

    // Determine how wide the remaining three columns of content for this line should be.
    let pad = (ReportRenderer.columnCount - 14) / 3

    // Create a description for `TP`.
    let TPDesc = "\(TP)"

    // Append the TP label.
    text += ("\(" " * (pad - 4 - TPDesc.count))TP: ", .ctThinItalic)

    // Append `TP`.
    text += (TPDesc, .ctLight)

    // Create a description for `FP`.
    let FPDesc = "\(FP)"

    // Append the FP label.
    text += ("\(" " * (pad - 4 - FPDesc.count))FP: ", .ctThinItalic)

    // Append `FP`.
    text += (FPDesc, .ctLight)

    // Create a description for `FN`.
    let FNDesc = "\(FN)"

    // Append the FN label.
    text += ("\(" " * (pad - 4 - FNDesc.count))FN: ", .ctThinItalic)

    // Append `FN`.
    text += (FNDesc, .ctLight)

    // End the line, appending an additional newline for padding.
    text += "\n\n"

    // Check whether the number of frames allows for the table to fit on one page.
    if features.count <= 50 {

      // Add an attribute to ensure the table is not broken across pages.
      text.addAttribute(NSAttributedStringKey(rawValue: ReportRenderer.samePageAttributeName), value: true, range: text.textRange)

    }

    return text

  }

  /// Generates a spectrogram for the chroma features.
  ///
  /// - Returns: The image containing the spectrogram.
  public func generateFigures() -> [(Image, NSAttributedString?)]? {

    let colorMapSize: ColorMap.Size

    switch features.features.parameters.variant {
      case .CRP: colorMapSize = .s128
      default:   colorMapSize = .s64
    }

    // Generate the plot of chroma features.
    let figure = chromaPlot(features: features.features,
                            featureRate: CGFloat(features.featureRate),
                            mapSize: colorMapSize,
                            mapKind: ColorMap.Kind.heat,
                            title: nil)

    let title = NSAttributedString(string: "Chromagram of Extracted Features Normalized to have a" +
                                           "Sum ≤ 1",
                                   style: .ctLightCentered)

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
    text += ("Template Report for ", .ctExtraLight)

    // Append the source of the report.
    switch source {
      case .mic:                text += ("Captured Audio", .ctExtraLight)
      case .file(url: let url): text += (url.lastPathComponent, .ctExtraLightItalic)
    }

    // Append the lead in text for the date.
    text += (" generated ", .ctExtraLight)

    // Append a description for the current date and time.
    text.append(date: Date())

    return text

  }
  
}

