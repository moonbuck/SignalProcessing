//
//  Report.swift
//  Chord Finder
//
//  Created by Jason Cardwell on 8/31/17.
//  Copyright (c) 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import CoreText

#if os(iOS)
  import UIKit
#else
  import AppKit
#endif

public protocol Report {

  /// Generates the report's header content.
  func generateHeader() -> NSAttributedString

  /// Generates the report's content for a given frame.
  func generateContent(frame: Int) -> NSAttributedString

  /// Generates the report's overview inserted before frame content.
  func generateOverview() -> NSAttributedString?

  /// Generates the figure for the report, returning `nil` if the report has no figure.
  func generateFigures() -> [(Image, NSAttributedString?)]?

  /// Generates content for the page header for the specified page or `nil`.
  func generateHeader(forPage page: Int) -> NSAttributedString?

  /// Generates content for the page footer for the specified page or `nil`.
  func generateFooter(forPage page: Int) -> NSAttributedString?

  /// The total number of frames to process when generating the report's PDF content.
  var totalFrames: Int { get }

  /// A flag indicating whether the report should be detailed or brief.
  var isBrief: Bool { get set }

  /// Whether the report includes an overview section.
  var hasOverview: Bool { get }

}

extension Report {

  /// A closure for rendering the report's PDF content into a graphics context setup for PDFs.
  public var renderPage: (CGContext) -> Bool {

    // Create a flag for indicating whether the header needs to be drawn.
    var needsHeader = true

    // Create the collection of figures.
    var figures: [(Image, NSAttributedString?)] = generateFigures()?.reversed() ?? []

    // Create a flag for indicating whether the overview needs to be drawn.
    var needsOverview = hasOverview

    // Retrieve the page margins.
    let margins = ReportRenderer.pageMargins

    // Retrieve the page size.
    let pageSize = ReportRenderer.pageSize

    // Create a variable for storing the current page offset.
    var pageOffset: CGFloat = margins.top

    // Calculate the offset at which a new page should be started.
    let maxOffset = pageSize.height - margins.top - margins.bottom - 10

    // Create a variable for storing text that would not fit on a page.
    var leftoverText: NSAttributedString? = nil

    // Create a variable to store the next frame to draw.
    var currentFrame = 0

    // Create a variable for stopping frame iteration.
    let stopFrame = totalFrames

    // Create a variable to track the page count for the footer.
    var currentPage = 0

    // Return a closure containing the drawing code.
    return {
      context in

      // Increment the page count.
      currentPage += 1

      // Try generating content for the page header if the current page is not the first page.
      if currentPage > 1, let pageHeader = self.generateHeader(forPage: currentPage) {

        // Draw the page header.
        ReportRenderer.draw(pageHeader: pageHeader, in: context)

      }

      // Reset the page offset since this is a fresh page.
      pageOffset = margins.top

      // Check whether the header needs to be drawn.
      if needsHeader, leftoverText == nil {

        // Draw the header.
        let header = self.generateHeader()
        let (rect, remaining) = ReportRenderer.draw(text: header,
                                                    in: context,
                                                    pageOffset: pageOffset)

        // Check that all of the header has been drawn.
        guard remaining == nil else {

          // Update the leftover text.
          leftoverText = remaining

          // Try generating the page footer.
          if let pageFooter = self.generateFooter(forPage: currentPage) {

            // Draw the page footer.
            ReportRenderer.draw(pageFooter: pageFooter, in: context)

          }

          // Return `true` to continue drawing in a fresh page.
          return true

        }

        // Update the page offset.
        pageOffset += rect.height

        // Update the flag.
        needsHeader = false

      }


      // Check whether the figure needs to be drawn.
      while let (figure, title) = figures.popLast() {

        // Create a variable for the title's height.
        var titleHeight: CGFloat = 0

        // Try unwrapping the title.
        if let title = title {

          // Create a frame setter.
          let framesetter = CTFramesetterCreateWithAttributedString(title)

          // Create a size with which to constrain the title.
          let constraints = CGSize(width: pageSize.width - margins.left - margins.right,
                                   height: CGFloat.greatestFiniteMagnitude)

          // Get the amount of space that will be consumed when drawing the frame of text.
          let frameSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter,
                                                                       CFRange(title.textRange),
                                                                       nil,
                                                                       constraints,
                                                                       nil)

          // Update `titleHeight`.
          titleHeight = frameSize.height

        }

        // Establish a value for additional padding above and below the figure.
        let pad: CGFloat = 10

        // Get the dimensions of the image.
        let imageHeight = figure.size.height, imageWidth = figure.size.width

        //Establish the target width for the figure.
        let targetWidth = (pageSize.width - margins.left - margins.right)

        // Calculate the height of the image at the target width.
        let proposedHeight = imageHeight * targetWidth / imageWidth

        // Calculate the amount of vertical space available.
        let availableHeight = pageSize.height - pageOffset - pad - margins.bottom - titleHeight

        // Calculate the max height if the figure is one its own page.
        let maxHeight = pageSize.height - margins.bottom - margins.top - titleHeight

        // Establish variables for the determined width and height for the figure.
        let width: CGFloat, height: CGFloat

        // Switch on the proposed and maximum heights.
        switch (proposedHeight, availableHeight) {

          case let (proposed, available) where proposed <= available:
            // There is space for the figure at the proposed height. 

            // Set the width to the target width.
            width = targetWidth

            // Set the height to the proposed height.
            height = proposedHeight

          case let (proposed, available) where proposed / available >= 0.75:
            // There is not enough space for the figure at the proposed height but there is 
            // space for the figure if the proposed height is reduced by at most 25%.

            // Set the width to be proportional to the maximum height.
            width = availableHeight * imageWidth / imageHeight

            // Set the height to the maximum height.
            height = availableHeight

          case let (proposed, _) where proposed <= maxHeight:
            // There is not enough space for the proposed height but there would be on an empty
            // page.

            // Try generating the page footer.
            if let pageFooter = self.generateFooter(forPage: currentPage) {

              // Draw the page footer.
              ReportRenderer.draw(pageFooter: pageFooter, in: context)
              
            }

            // Push the figure back onto the stack.
            figures.append((figure, title))

            // Return `true` to generate a new page.
            return true

          default:
            // The figure cannot fit on any page at the proposed height.

            // Ensure the page offset is equal to the top margin.
            guard pageOffset == margins.top else {

              // Try generating the page footer.
              if let pageFooter = self.generateFooter(forPage: currentPage) {

                // Draw the page footer.
                ReportRenderer.draw(pageFooter: pageFooter, in: context)

              }

              // Push the figure back onto the stack.
              figures.append((figure, title))
              
              // Return `true` to generate a new page.
              return true

            }

            // Set the width to be proportional to the maximum height.
            width = availableHeight * imageWidth / imageHeight

            // Set the height to the maximum height.
            height = availableHeight

        }

        // Adjust the page offset for the padding above the figure.
        pageOffset += pad

        // Try unwrapping the title.
        if let title = title {

          // Draw the title.
          let (rect, _) = ReportRenderer.draw(text: title, in: context, pageOffset: pageOffset)

          // Update the page offset.
          pageOffset += rect.height

        }

        // Draw the figure.
        let rect = ReportRenderer.draw(image: figure,
                                       size: CGSize(width: width, height: height),
                                       in: context,
                                       pageOffset: pageOffset)

        // Update the page offset.
        pageOffset += rect.height + pad

        // Ensure there is more space on the current page.
        guard pageOffset < maxOffset else {

          // Try generating the page footer.
          if let pageFooter = self.generateFooter(forPage: currentPage) {

            // Draw the page footer.
            ReportRenderer.draw(pageFooter: pageFooter, in: context)

          }

          // Ensure the report is not brief and without any more brief content.
          guard !self.isBrief || self.hasOverview else {

            // Return `false` to end report content generation.
            return false

          }

          // Return `true` to generate a new page.
          return true

        }

      }

      // Check whether the overview needs to be drawn.
      if needsOverview, leftoverText == nil, let overview = self.generateOverview() {

        let (rect, remaining) = ReportRenderer.draw(text: overview,
                                                    in: context,
                                                    pageOffset: pageOffset)

        // Check that all of the header has been drawn.
        guard remaining == nil else {

          // Update the leftover text.
          leftoverText = remaining

          // Try generating the page footer.
          if let pageFooter = self.generateFooter(forPage: currentPage) {

            // Draw the page footer.
            ReportRenderer.draw(pageFooter: pageFooter, in: context)

          }

          // Return `true` to continue drawing in a fresh page.
          return true
          
        }

        // Update the page offset.
        pageOffset += rect.height

        // Update the flag.
        needsOverview = false

      }

      // Check whether the overview needs to be drawn but there is no overview.
      else if needsOverview, leftoverText == nil {

        // If the flag is set but this code is reached than the report has no overview.
        needsOverview = false

      }

      // Check for leftover text to draw.
      if let text = leftoverText {

        // Draw the rest of partial frame.
        let (rect, remaining) = ReportRenderer.draw(text: text, in: context, pageOffset: pageOffset)

        // Check that all of the leftover text has been drawn.
        guard remaining == nil else {

          // Update the leftover text.
          leftoverText = remaining

          // Try generating the page footer.
          if let pageFooter = self.generateFooter(forPage: currentPage) {

            // Draw the page footer.
            ReportRenderer.draw(pageFooter: pageFooter, in: context)

          }

          // Return `true` to continue drawing in a fresh page.
          return true

        }

        // Clear the leftover text.
        leftoverText = nil

        // Update the offset by adding the height of the last draw operation.
        pageOffset += rect.height

        // Check whether the text was leftover from the header.
        if needsHeader {

          // Update the flag.
          needsHeader = false

        } else if needsOverview {

          // Update the overview flag.
          needsOverview = false
          
        } else {
          
          // Update the current frame.
          currentFrame += 1

        }

      }

      // Ensure that the report is meant to be detailed.
      guard !self.isBrief else {

        // Try generating the page footer.
        if let pageFooter = self.generateFooter(forPage: currentPage) {

          // Draw the page footer.
          ReportRenderer.draw(pageFooter: pageFooter, in: context)

        }

        // Return `false` to end content generation for the report.
        return false

      }

      // Loop until all frames have been drawn or a new page is needed.
      while currentFrame < stopFrame {

        // Draw the current frame of features.
        let frameText = self.generateContent(frame: currentFrame)
        let (rect, remaining) = ReportRenderer.draw(text: frameText,
                                                    in: context,
                                                    pageOffset: pageOffset)

        // Check that there are not any more pitches remaining.
        guard remaining == nil else {

          // Update `partialFrame` with new range of remaining pitches for `frame`.
          leftoverText = remaining

          // Try generating the page footer.
          if let pageFooter = self.generateFooter(forPage: currentPage) {

            // Draw the page footer.
            ReportRenderer.draw(pageFooter: pageFooter, in: context)

          }

          // Return `true` to continue drawing in a fresh page.
          return true
          
        }

        // Update the offset by adding the height of the last draw operation.
        pageOffset += rect.height

        // Update the current frame.
        currentFrame += 1

        // Check whether a new page should be started.
        guard pageOffset < maxOffset else {

          // Try generating the page footer.
          if let pageFooter = self.generateFooter(forPage: currentPage) {

            // Draw the page footer.
            ReportRenderer.draw(pageFooter: pageFooter, in: context)

          }

          return currentFrame < stopFrame ? true : false

        }

      }

      // Try generating the page footer.
      if let pageFooter = self.generateFooter(forPage: currentPage) {

        // Draw the page footer.
        ReportRenderer.draw(pageFooter: pageFooter, in: context)

      }

      // Return `false` since there is no more content to draw.
      return false

    }

  }

  public func generateFooter(forPage page: Int) -> NSAttributedString? {

    // Don't put a footer on the first page.
    guard page > 1 else { return nil }

    // Create a description of the page number.
    let pageNumberDesc = page.description

    // Get the number of spaces to pad for right alignment.
    let pad = ReportRenderer.columnCount - pageNumberDesc.count

    return NSAttributedString(string: "\(" " * pad)\(pageNumberDesc)", style: .extraLight)

  }

}
