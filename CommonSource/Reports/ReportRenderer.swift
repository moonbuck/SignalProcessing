//
//  ReportRenderer.swift
//  Chord Finder
//
//  Created by Jason Cardwell on 8/28/17.
//  Copyright (c) 2017 Moondeer Studios. All rights reserved.
//
import Foundation

#if os(iOS)
  import UIKit
#else
  import AppKit
#endif

/// A protocol for providers of content for a PDF report.
public protocol ReportContentProvider {

  /// A closure for rendering page content. The closure is passed the PDF context in which
  /// the page content should be drawn. The closure should return `true` to generate an
  /// additional page and `false` if the provider has no more content to render.
  var renderPage: (CGContext) -> Bool { get }

}

extension ReportContentProvider {

  /// Generates a report and saves it as a PDF document to the specified location.
  ///
  /// - Parameter url: The location to which the report will be saved.
  public func generateReport(url: URL) { ReportRenderer.createReport(url: url, provider: self) }

}

/// A class for coordinating the generation of reports as PDF files. 
public final class ReportRenderer {

  /// The key used for a `Bool` attribute whose range denotes a chunk of text that must appear
  /// all on the same page.
  public static let samePageAttributeName = "samePage"

  /// The size of the rendered PDF pages.
  public static let pageSize = CGSize(width: 612, height: 792)

  /// Page margins for generated PDFs.
  public static let pageMargins = EdgeInsets(top: 36, left: 36, bottom: 36, right: 36)

  /// The total number of characters per line.
  public static let columnCount = 98

  /// Creates a new PDF document at the specified location and containing the combined content
  /// provided by `providers`.
  ///
  /// - Parameters:
  ///   - url: The location for the PDF being created.
  ///   - providers: An array of content providers for rendering the PDF pages.
  /// - Requires: `providers` contain at least one element.
  public static func createReport(url: URL, providers: [ReportContentProvider]) {

    #if os(iOS)

      // Check that there is at least one content provider.
      guard !providers.isEmpty else {
        fatalError("\(#function) `providers` must not be empty.")
      }

      // Establish the bounding box for the PDF context.
      let bounds = CGRect(origin: .zero, size: pageSize)

      // Create a new PDF renderer.
      let pdfRenderer = UIGraphicsPDFRenderer(bounds: bounds)

      // Create a variable to hold the index of the current content provider in `providers`.
      var currentProvider = 0

      // Create a variable to hold the render page callback and initialize using the first provider.
      var renderPage: (CGContext) -> Bool = providers[0].renderPage

      do {

        // Create the PDF file.
        try pdfRenderer.writePDF(to: url) {
          context in

          // Create a variable to serve as a flag for the loop below.
          var drawNewPage = true

          // Loop until no more pages need be created.
          while drawNewPage {

            // Begin a new PDF page with a size specified by `bounds`.
            context.beginPage()

            // Invoke the render callback, switching on the returned boolean.
            switch renderPage(context.cgContext) {

            case true:
              // The current provider has more page content, simply break.

              break

            case false where currentProvider + 1 < providers.count:
              // The current provider is out of content but there are one or more providers left.

              // Increment index specifying the current provider.
              currentProvider += 1

              // Update the render callback.
              renderPage = providers[currentProvider].renderPage

            case false:
              // The current provider is out of content and there are no more providers.

              // Update the flag to end page generation and complete PDF creation.
              drawNewPage = false

            }

          }

        }

      } catch {

        fatalError("\(#function) Error creating report - \(error)")

      }

    #else

      fatalError("\(#function) not yet implemented for the macOS platform.")

    #endif

  }
  
  /// Creates a new PDF document at the specified location and with content provided by `provider`.
  ///
  /// - Parameters:
  ///   - url: The location for the PDF being created.
  ///   - provider: The object providing the callback for rendering page content.
  public static func createReport(url: URL, provider: ReportContentProvider) {

    createReport(url: url, providers: [provider])

  }

  /// Draws an image horizontally centered at a specified offset and height.
  ///
  /// - Parameters:
  ///   - image: The image to draw.
  ///   - size: The size to make the image.
  ///   - context: The context in which to draw `image`.
  ///   - pageOffset: The offset, including the top margin, at which the image should begin.
  /// - Returns: The rectangle in which `image` has been drawn.
  @discardableResult
  public static func draw(image: Image,
                          size: CGSize,
                          in context: CGContext,
                          pageOffset: CGFloat) -> CGRect
  {

    #if os(iOS)

      // Get the bounding box for the page content.
      let bounds = UIGraphicsGetPDFContextBounds()
      let contentBounds = CGRect(x: bounds.origin.x + pageMargins.left,
                                 y: bounds.origin.y + pageMargins.top,
                                 width: bounds.size.width - (pageMargins.left + pageMargins.right),
                                 height: bounds.size.height - (pageMargins.top + pageMargins.bottom))

      // Calculate the x position for the image origin.
      let imageX = contentBounds.midX - size.width * 0.5

      // Create a rectangle for drawing the image.
      let imageRect = CGRect(x: imageX, y: pageOffset, width: size.width, height: size.height)

      // Draw the image.
      image.draw(in: imageRect, blendMode: .darken, alpha: 1)

      return imageRect

    #else

      fatalError("\(#function) not yet implemented for the macOS platform.")

    #endif


  }

  /// Draws text into a graphics context and returns a tuple of the rect in which the text was
  /// drawn and any text that did not fit.
  ///
  /// - Parameters:
  ///   - text: The text to draw into `context`.
  ///   - context: The graphics context in which to draw `text`.
  ///   - pageOffset: The offset, including the top margin, at which the text should begin.
  /// - Returns: A tuple containing the rectangle in which `text` has been drawn and the suffix
  ///            of `text` that did not fit or `nil` if all the text fit.
  @discardableResult
  public static func draw(text: NSAttributedString,
                          in context: CGContext,
                          pageOffset: CGFloat) -> (rect: CGRect, remaining: NSAttributedString?)
  {

    #if os(iOS)

      // Save the graphics state before manipulating the context.
      context.saveGState()

      // Get the bounding box from the PDF context.
      let bounds = UIGraphicsGetPDFContextBounds()

      // Flip the coordinates to prevent core text functions from drawing upsidedown.
      context.scaleBy(x: 1, y: -1)
      context.translateBy(x: 0, y: -bounds.height)

      // Calculate the rectangle for drawing PDF content.
      var contentBounds = CGRect(x: bounds.origin.x + pageMargins.left,
                                 y: bounds.origin.y + pageMargins.top,
                                 width: bounds.size.width - (pageMargins.left + pageMargins.right),
                                 height: bounds.size.height - (pageMargins.top + pageMargins.bottom))
  //      UIEdgeInsetsInsetRect(bounds, pageMargins)

      // Adjust `contentBounds` for the page offset and minding the lower-left origin.
      contentBounds.origin.y = bounds.height - pageOffset
      contentBounds.size.height -= pageOffset - pageMargins.top

      // Create a frame setter with the header and subheader.
      let framesetter = CTFramesetterCreateWithAttributedString(text)

      // Create a variable for the range of text being drawn.
      var textRange = CFRange(text.textRange)

      // Get the amount of space that will be consumed when drawing the frame of text.
      var frameSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter,
                                                                   textRange,
                                                                   nil,
                                                                   contentBounds.size,
                                                                   &textRange)

      // Adjust the width so that the text can be centered should the style dictate.
      frameSize.width = contentBounds.size.width

      // Enumerate 'same-page' attributes in `text`.
      text.enumerateAttribute(NSAttributedStringKey(rawValue: samePageAttributeName),
                              in: text.textRange,
                              options: [])
      {
        (value: Any?, range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) -> Void in

        // Unwrap and test the attribute value.
        if let attributeValue = value as? Bool,
          attributeValue == true,
          range.endLocation > textRange.endLocation,
          range.location < textRange.endLocation
        {

          // Modify `textRange` so that it stops just before the chunk of text that must appear
          // on the same page.
          textRange.length = range.location - textRange.location

          // Stop enumerating since any remaining ranges would be located after `range`.
          stop.pointee = true

        }

      }

      // Make sure there is some text to draw.
      guard textRange.length > 0 else {

        // Restore the graphics state for `context`.
        context.restoreGState()

        // Return the whole string of text as remaining so it can start the next page.
        return (rect: .zero, remaining: text)

      }

      // Create a variable with any text that did not fit onto the current page.
      let remainingText: NSAttributedString? = textRange.length < text.length
        ? text.attributedSubstring(from: textRange.location + textRange.length)
        : nil

      // Calculate the origin for the frame in which to draw the text.
      var frameOrigin = contentBounds.origin
      frameOrigin.y -= frameSize.height

      // Calculate the bounding box for the frame of text.
      let frameRect = CGRect(origin: frameOrigin, size: frameSize)

      // Create a path for the frame setter.
      let path = CGPath(rect: frameRect, transform: nil)

      // Get a frame from the frame setter.
      let textFrame = CTFramesetterCreateFrame(framesetter, textRange, path, nil)

      // Draw the text frame into the provided context.
      CTFrameDraw(textFrame, context)

      // Restore the graphics state for `context`.
      context.restoreGState()

      return (rect: frameRect,
              remaining: remainingText != nil && !remainingText!.isWhitespace ? remainingText : nil)

    #else

      fatalError("\(#function) not yet implemented for the macOS platform.")

    #endif

  }

  /// Draws a page header between the left and right margins and within the top margin.
  ///
  /// - Parameters:
  ///   - text: The content for the page header.
  ///   - context: The context within which to draw `text`.
  public static func draw(pageHeader text: NSAttributedString, in context: CGContext) {

    #if os(iOS)

      // Save the graphics state before manipulating the context.
      context.saveGState()

      // Get the bounding box from the PDF context.
      let bounds = UIGraphicsGetPDFContextBounds()

      // Flip the coordinates to prevent core text functions from drawing upsidedown.
      context.scaleBy(x: 1, y: -1)
      context.translateBy(x: 0, y: -bounds.height)

      // Create a frame setter with the header and subheader.
      let framesetter = CTFramesetterCreateWithAttributedString(text)

      // Create a variable for the range of text being drawn.
      var textRange = CFRange(text.textRange)

      // Create the size within which the text is bound.
      let boundingSize = CGSize(width: pageSize.width - pageMargins.left - pageMargins.right,
                                height: pageMargins.top)

      // Get the amount of space that will be consumed when drawing the frame of text.
      let frameSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter,
                                                                   textRange,
                                                                   nil,
                                                                   boundingSize,
                                                                   &textRange)

      let frameOrigin = CGPoint(x: pageMargins.left * 0.5, y: pageSize.height - 9 - frameSize.height)

      // Calculate the bounding box for the frame of text.
      let frameRect = CGRect(origin: frameOrigin, size: frameSize)

      // Create a path for the frame setter.
      let path = CGPath(rect: frameRect, transform: nil)

      // Get a frame from the frame setter.
      let textFrame = CTFramesetterCreateFrame(framesetter, textRange, path, nil)

      // Draw the text frame into the provided context.
      CTFrameDraw(textFrame, context)

      // Restore the graphics state for `context`.
      context.restoreGState()

    #else

      fatalError("\(#function) not yet implemented for the macOS platform.")

    #endif

  }

  /// Draws a page footer between the left and right margins and within the bottom margin.
  ///
  /// - Parameters:
  ///   - text: The content for the page footer.
  ///   - context: The context within which to draw `text`.
  public static func draw(pageFooter text: NSAttributedString, in context: CGContext) {

    #if os(iOS)

      // Save the graphics state before manipulating the context.
      context.saveGState()

      // Get the bounding box from the PDF context.
      let bounds = UIGraphicsGetPDFContextBounds()

      // Flip the coordinates to prevent core text functions from drawing upsidedown.
      context.scaleBy(x: 1, y: -1)
      context.translateBy(x: 0, y: -bounds.height)

      // Create a frame setter with the header and subheader.
      let framesetter = CTFramesetterCreateWithAttributedString(text)

      // Create a variable for the range of text being drawn.
      var textRange = CFRange(text.textRange)

      // Create the size within which the text is bound.
      let boundingSize = CGSize(width: pageSize.width - pageMargins.left - pageMargins.right,
                                height: pageMargins.bottom)

      // Get the amount of space that will be consumed when drawing the frame of text.
      let frameSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter,
                                                                   textRange,
                                                                   nil,
                                                                   boundingSize,
                                                                   &textRange)

      let frameOrigin = CGPoint(x: pageMargins.left * 1.5, y: 18)

      // Calculate the bounding box for the frame of text.
      let frameRect = CGRect(origin: frameOrigin, size: frameSize)

      // Create a path for the frame setter.
      let path = CGPath(rect: frameRect, transform: nil)

      // Get a frame from the frame setter.
      let textFrame = CTFramesetterCreateFrame(framesetter, textRange, path, nil)

      // Draw the text frame into the provided context.
      CTFrameDraw(textFrame, context)

      // Restore the graphics state for `context`.
      context.restoreGState()

    #else

      fatalError("\(#function) not yet implemented for the macOS platform.")

    #endif

  }

}

extension CFRange {

  /// Full-width conversion from `NSRange`.
  ///
  /// - Parameter range: The range to convert.
  public init(_ range: NSRange) { self.init(location: range.location, length: range.length) }

  /// The location after the last location contained by the range.
  public var endLocation: CFIndex { return location + length }

}

extension NSRange {

  /// Full-width conversion from `CFRange`.
  ///
  /// - Parameter range: The range to convert.
  public init(_ range: CFRange) { self.init(location: range.location, length: range.length) }

  /// The location after the last location contained by the range.
  public var endLocation: Int { return location + length }

}
