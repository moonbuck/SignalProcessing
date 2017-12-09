import Foundation
import AVFoundation
import CoreText
import Accelerate

#if os(iOS)
  import UIKit
#else
  import AppKit
#endif

infix operator ×

public func ×(lhs: CGFloat, rhs: CGFloat) -> CGSize {
  return CGSize(width: lhs, height: rhs)
}

extension CGPoint: ExpressibleByArrayLiteral {

  public init(arrayLiteral elements: CGFloat...) {

    switch elements.count {
      case 0:  self = CGPoint()
      case 1:  self = CGPoint(x: elements[0], y: elements[0])
      default: self = CGPoint(x: elements[0], y: elements[1])
    }

  }

}

/// A structure for specifying a color map for use with graphing functions.
public struct ColorMap: Collection {

  /// An enumeration of supported color map sizes.
  public enum Size { case s64, s128 }

  /// An enumeration for specifying how the color map should generate its colors.
  public enum Kind { case heat, grayscale }

  /// The total number of assignable colors in the color map
  public let size: Size

  /// The kind of colors used by the color map.
  public let kind: Kind

  /// The range of values mapped by the color map.
  public var valueRange: Range<CGFloat> {
    switch size {
      case .s64: return 0..<1
      case .s128: return -1..<1
    }
  }

  public var preferredBackgroundColor: Color {
    switch kind {
      case .heat: return .black
      case .grayscale: return .white
    }
  }

  /// The actual colors that make up the color map.
  private let colors: [Color]

  public var count: Int { return endIndex }

  public let startIndex: Int = 0
  public let endIndex: Int

  public func index(after i: Int) -> Int { return i &+ 1 }

  public subscript(position: Int) -> Color { return colors[position] }

  public subscript(value: Float64) -> Int {

    switch size {
      case .s64: return Int((value * 63).rounded())
      case .s128: return Int((((value + 1) / 2) * 127).rounded())
    }

  }

  private init(heatMapWithSize size: Size) {

    kind = .heat
    self.size = size

    var oneHalf = 0.5
    var zero = 0.0
    var one = 1.0
    var a = 0.0417
    var b = 0.0625

    let ramp24AtoOne = UnsafeMutablePointer<Double>.allocate(capacity: 24)
    vDSP_vgenD(&a, &one, ramp24AtoOne, 1, 24)

    let ramp24ZerotoOne = UnsafeMutablePointer<Double>.allocate(capacity: 24)
    vDSP_vgenD(&zero, &one, ramp24ZerotoOne, 1, 24)

    let ramp16ZeroToOne = UnsafeMutablePointer<Double>.allocate(capacity: 16)
    vDSP_vgenD(&zero, &one, ramp16ZeroToOne, 1, 16)

    switch size {

    case .s64:

      endIndex = 64

      let redValues = UnsafeMutablePointer<Double>.allocate(capacity: 64)
      redValues.initialize(from: ramp24AtoOne, count: 24)
      (redValues + 24).initialize(to: 1, count: 40)

      let greenValues = UnsafeMutablePointer<Double>.allocate(capacity: 64)
      greenValues.initialize(to: 0, count: 24)
      (greenValues + 24).initialize(from: ramp24ZerotoOne, count: 24)
      (greenValues + 48).initialize(to: 1, count: 16)

      let blueValues = UnsafeMutablePointer<Double>.allocate(capacity: 64)
      blueValues.initialize(to: 0, count: 48)
      (blueValues + 48).initialize(from: ramp16ZeroToOne, count: 16)

      colors = (0..<64).map { Color(red: CGFloat(redValues[$0]),
                                    green: CGFloat(greenValues[$0]),
                                    blue: CGFloat(blueValues[$0]),
                                    alpha: 1) }

    case .s128:

      endIndex = 128

      let ramp64OneHalfToZero = UnsafeMutablePointer<Double>.allocate(capacity: 64)
      vDSP_vgenD(&oneHalf, &zero, ramp64OneHalfToZero, 1, 64)

      let ramp64OneToZero = UnsafeMutablePointer<Double>.allocate(capacity: 64)
      vDSP_vgenD(&one, &zero, ramp64OneToZero, 1, 64)

      let ramp16BtoOne = UnsafeMutablePointer<Double>.allocate(capacity: 16)
      vDSP_vgenD(&b, &one, ramp16BtoOne, 1, 16)

      let redValues = UnsafeMutablePointer<Double>.allocate(capacity: 128)
      redValues.initialize(from: ramp64OneHalfToZero, count: 64)
      (redValues + 64).initialize(from: ramp24AtoOne, count: 24)
      (redValues + 88).initialize(to: 1, count: 40)

      let greenValues = UnsafeMutablePointer<Double>.allocate(capacity: 128)
      greenValues.initialize(from: ramp64OneHalfToZero, count: 64)
      (greenValues + 64).initialize(to: 0, count: 24)
      (greenValues + 88).initialize(from: ramp24AtoOne, count: 24)
      (greenValues + 112).initialize(to: 1, count: 16)

      let blueValues = UnsafeMutablePointer<Double>.allocate(capacity: 128)
      blueValues.initialize(from: ramp64OneToZero, count: 64)
      (blueValues + 64).initialize(to: 0, count: 48)
      (blueValues + 112).initialize(from: ramp16BtoOne, count: 16)

      colors = (0..<128).map { Color(red: CGFloat(redValues[$0]),
                                     green: CGFloat(greenValues[$0]),
                                     blue: CGFloat(blueValues[$0]),
                                     alpha: 1) }

    }


  }

  private init(grayscaleMapWithSize size: Size) {

    kind = .grayscale
    self.size = size

    var min = 0.0417
    var max = 1.0

    switch size {

    case .s64:

      endIndex = 64

      let ramp = UnsafeMutablePointer<Double>.allocate(capacity: 64)
      vDSP_vgenD(&min, &max, ramp, 1, 64)
      colors = (0..<64).reversed().map { Color(white: CGFloat(ramp[$0]), alpha: 1) }

    case .s128:

      endIndex = 128

      let ramp = UnsafeMutablePointer<Double>.allocate(capacity: 128)
      vDSP_vgenD(&min, &max, ramp, 1, 128)
      colors = (0..<128).reversed().map { Color(white: CGFloat(ramp[$0]), alpha: 1) }

    }

  }

  public init(size: Size, kind: Kind = .heat) {

    switch kind {
      case .heat: self.init(heatMapWithSize: size)
      case .grayscale: self.init(grayscaleMapWithSize: size)
    }

  }

}


public func chromaPlot(features: [ChromaVector],
                       featureRate: Float,
                       colorMap: ColorMap? = nil,
                       title: String? = nil) -> Image
{

  let imageSize = 866×715

  return createImage(size: imageSize) {
    context in

    let rect = CGRect(origin: .zero, size: imageSize)

    // Create a color map to use for fill colors.
    let colorMap = colorMap ?? ColorMap(size: .s64)

    // Establish the amount of vertical space allotted to the title.
    let titleHeight: CGFloat = title == nil ? 8 : 50

    // Get the origin offset and plot size from `rect`.
    let plotOrigin = CGPoint(x: rect.origin.x + 40, y: rect.origin.y + titleHeight)
    let plotSize = (rect.size.width - 146) × (rect.size.height - 40 - titleHeight)
    let plotRect = CGRect(origin: plotOrigin, size: plotSize)

    // Calculate the total number of columns in the plot.
    let columnCount = CGFloat(features.count)

    // The number of rows for a chromagram is always `12`.
    let rowCount: CGFloat = 12

    // Calculate the size for each value box.
    let rowHeight = plotSize.height / rowCount
    let columnWidth = plotSize.width / columnCount
    let dataBoxSize = columnWidth × rowHeight

    // Map the provided values to a tuple with the value's box and color index.
    let dataBoxes = features.enumerated().map {
      (column: Int, vector: ChromaVector) -> [(CGRect, Int)] in

      // Map the rows for this `column`.
      (0..<12).map {

        // Calculate the origin assuming `rect.origin` is (0, 0).
        var origin = CGPoint(x: CGFloat(column) * columnWidth,
                             y: rowHeight * (11 - CGFloat($0)))

        // Adjust `origin` according to actual `rect.origin`.
        origin.x += plotOrigin.x
        origin.y += plotOrigin.y

        // Create the rect.
        let rect = CGRect(origin: origin, size: dataBoxSize)

        // Get the color index for the value.
        let colorIndex = colorMap[vector[$0]]

        // Return a tuple with the box rect and color index.
        return (rect, colorIndex)

      }

    }

    // Fill the rect with white.
    context.setFillColor(Color.white.cgColor)
    context.fill(rect)

    // Fill the plot with black.
    context.setFillColor(Color.black.cgColor)
    context.fill(plotRect)

    // Iterate through the columns.
    for column in dataBoxes {

      // Iterate through the rows of this column.
      for (rect, i) in column {

        // Set the fill color according the color index.
        context.setFillColor(colorMap[i].cgColor)

        // Fill the rect for this row in this column.
        context.fill(rect)

      }

    }

    // Set black as the stroke color and outline the plot.
    context.setStrokeColor(Color.black.cgColor)
    context.stroke(plotRect, width: 1)

    // Generate a list of labels for the y axis.
    let chromaLabels = (0...11).map(Chroma.init(rawValue:))
      .map({$0.description as NSString}).reversed()

    // Create an attributes dictionary for the axis labels.
    var attributes: [NSAttributedStringKey:Any] = [ .font: (CTFont.light as Font).withSize(18) ]

    // Set the fill color back to black.
    context.setFillColor(Color.black.cgColor)

    // Create a pad value to use in left-aligning the chroma labels.
    let chromaLabelPad: CGFloat = {
      let s = Chroma.dFlat.description as NSString
      let w = s.size(withAttributes: attributes).width
      return (40 - w)/2
    }()

    // Iterate through the enumerated chroma labels.
    for (i, label) in chromaLabels.enumerated() {

      // Calculate the label's height.
      let labelSize = label.size(withAttributes: attributes)

      // Calculate the vertical offset for this label's row.
      let yOffset = CGFloat(i) * rowHeight + (rowHeight - labelSize.height)/2

      // Calculate the origin for the label.
      let labelOrigin = CGPoint(x: rect.origin.x + chromaLabelPad,
                                y: plotRect.origin.y + yOffset)

      // Draw the label.
      label.draw(at: labelOrigin, withAttributes: attributes)

    }

    // Determine the total number of seconds represented in the plot.
    let totalSeconds = CGFloat(features.count) / CGFloat(featureRate)

    // Determine the number of plot points that correspond to one second.
    let pointsPerSecond = plotRect.size.width / totalSeconds

    let xLabelSize = 40 × 40

    // Create a paragraph style for centering text.
    let centered = NSMutableParagraphStyle()
    centered.alignment = .center

    attributes[NSAttributedStringKey.paragraphStyle] = centered

    // Iterate every five seconds through `totalSeconds`.
    for t in stride(from: CGFloat(), through: totalSeconds, by: 5) {

      // Create the label using the number of seconds for this iteration.
      let label = "\(Int(t))" as NSString

      // Calculate the label's height.
      let labelHeight = label.size(withAttributes: attributes).height

      // Calculate the origin for the label.
      let labelOrigin = CGPoint(x: plotRect.origin.x + pointsPerSecond * t,
                                y: plotRect.maxY + 20 - labelHeight/2)

      // Create the rectangle within which to draw the label.
      let labelRect = CGRect(origin: labelOrigin, size: xLabelSize)

      // Draw the label.
      label.draw(in: labelRect, withAttributes: attributes)

    }

    // Establish the width of the color map.
    let colorMapWidth: CGFloat = 37

    // Calculate the height for each color index's rectangle.
    let cmIndexHeight = plotRect.size.height/CGFloat(colorMap.count)

    // Calculate the rectangle for the color map.
    let cmRect = CGRect(x: plotRect.maxX + 20, y: plotRect.origin.y,
                        width: colorMapWidth, height: plotRect.size.height)

    // Calculate the size of the rectangle for a single color map index.
    let colorMapIndexSize = colorMapWidth × cmIndexHeight

    // Iterate through the reversed color map indices.
    for (i, colorIndex) in (colorMap.startIndex..<colorMap.endIndex).reversed().enumerated() {

      // Calculate the y offset for this color index.
      let yOffset = CGFloat(i) * colorMapIndexSize.height

      // Create the origin for this color index.
      let colorMapIndexOrigin = CGPoint(x: cmRect.origin.x,
                                        y: cmRect.origin.y + yOffset)

      // Create the rectangle for this color index.
      let colorMapIndexRect = CGRect(origin: colorMapIndexOrigin, size: colorMapIndexSize)

      // Set the fill to the color for this index.
      colorMap[colorIndex].setFill()

      // Fill the rectangle with the color.
      context.fill(colorMapIndexRect)

    }

    // Outline the color map.
    context.stroke(cmRect, width: 1)

    let valueRange = colorMap.valueRange
    let colorMapLabels = stride(from: valueRange.lowerBound,
                                through: valueRange.upperBound,
                                by: CGFloat(colorMap.count/64)/10).reversed()

    for (i, f) in colorMapLabels.enumerated() {


      let label = "\(f)" as NSString

      let labelHeight = label.size(withAttributes: attributes).height
      let yOffset = cmRect.size.height * (CGFloat(i)/10) + cmIndexHeight/2 - labelHeight/2 - 6

      let labelOrigin = CGPoint(x: cmRect.maxX + 4, y: cmRect.origin.y + yOffset)

      let labelRect = CGRect(origin: labelOrigin, size: colorMapWidth × labelHeight)

      label.draw(in: labelRect, withAttributes: attributes)

    }

    // Unwrap the optional title and draw when non-nil.
    if let title = title as NSString? {

      let titleAttributes: [NSAttributedStringKey:Any] = [
        .font: (CTFont.bold as Font).withSize(22),
        .paragraphStyle: centered
      ]

      // Get the height of the title.
      let titleHeight = title.size(withAttributes: titleAttributes).height

      // Create the origin and size for the title's rectangle.
      let titleOrigin = CGPoint(x: 0, y: 25 - titleHeight/2)
      let titleSize = rect.size.width × 50

      // Draw the title.
      title.draw(in: CGRect(origin: titleOrigin, size: titleSize),
                 withAttributes: titleAttributes)

    }

  }

}

public func chromaPlot(features: ChromaFeatures,
                       colorMap: ColorMap? = nil,
                       title: String? = nil) -> Image
{
  let imageSize = 866×715

  return createImage(size: imageSize) {
    context in

    let rect = CGRect(origin: .zero, size: imageSize)

    // Create a color map to use for fill colors.
    let colorMap = colorMap ?? ColorMap(size: .s64)

    // Establish the amount of vertical space allotted to the title.
    let titleHeight: CGFloat = title == nil ? 8 : 50

    // Get the origin offset and plot size from `rect`.
    let plotOrigin = CGPoint(x: rect.origin.x + 40, y: rect.origin.y + titleHeight)
    let plotSize = (rect.size.width - 146) × (rect.size.height - 40 - titleHeight)
    let plotRect = CGRect(origin: plotOrigin, size: plotSize)

    // Calculate the total number of columns in the plot.
    let columnCount = CGFloat(features.count)

    // The number of rows for a chromagram is always `12`.
    let rowCount: CGFloat = 12

    // Calculate the size for each value box.
    let rowHeight = plotSize.height / rowCount
    let columnWidth = plotSize.width / columnCount
    let dataBoxSize = columnWidth × rowHeight

    // Map the provided values to a tuple with the value's box and color index.
    let dataBoxes = features.enumerated().map {
      (column: Int, vector: ChromaVector) -> [(CGRect, Int)] in

      // Map the rows for this `column`.
      (0..<12).map {

        // Calculate the origin assuming `rect.origin` is (0, 0).
        var origin = CGPoint(x: CGFloat(column) * columnWidth,
                             y: rowHeight * (11 - CGFloat($0)))

        // Adjust `origin` according to actual `rect.origin`.
        origin.x += plotOrigin.x
        origin.y += plotOrigin.y

        // Create the rect.
        let rect = CGRect(origin: origin, size: dataBoxSize)

        // Get the color index for the value.
        let colorIndex = colorMap[vector[$0]]

        // Return a tuple with the box rect and color index.
        return (rect, colorIndex)

      }

    }

    // Fill the rect with white.
    context.setFillColor(Color.white.cgColor)
    context.fill(rect)

    // Fill the plot with black.
    context.setFillColor(Color.black.cgColor)
    context.fill(plotRect)

    // Iterate through the columns.
    for column in dataBoxes {

      // Iterate through the rows of this column.
      for (rect, i) in column {

        // Set the fill color according the color index.
        colorMap[i].setFill()

        // Fill the rect for this row in this column.
        context.fill(rect)

      }

    }

    // Set black as the stroke color and outline the plot.
    context.setStrokeColor(Color.black.cgColor)
    context.stroke(plotRect, width: 1)

    // Generate a list of labels for the y axis.
    let chromaLabels = (0...11).map(Chroma.init(rawValue:))
                         .map({$0.description as NSString}).reversed()

    // Create an attributes dictionary for the axis labels.
    var attributes: [NSAttributedStringKey:Any] = [ .font: (CTFont.light as Font).withSize(18) ]

    // Set the fill color back to black.
    context.setFillColor(Color.black.cgColor)

    // Create a pad value to use in left-aligning the chroma labels.
    let chromaLabelPad: CGFloat = {
      let s = Chroma.dFlat.description as NSString
      let w = s.size(withAttributes: attributes).width
      return (40 - w)/2
    }()

    // Iterate through the enumerated chroma labels.
    for (i, label) in chromaLabels.enumerated() {

      // Calculate the label's height.
      let labelSize = label.size(withAttributes: attributes)

      // Calculate the vertical offset for this label's row.
      let yOffset = CGFloat(i) * rowHeight + (rowHeight - labelSize.height)/2

      // Calculate the origin for the label.
      let labelOrigin = CGPoint(x: rect.origin.x + chromaLabelPad,
                                y: plotRect.origin.y + yOffset)

      // Draw the label.
      label.draw(at: labelOrigin, withAttributes: attributes)

    }

    // Determine the total number of seconds represented in the plot.
    let totalSeconds = CGFloat(features.count) / CGFloat(features.featureRate)

    // Determine the number of plot points that correspond to one second.
    let pointsPerSecond = plotRect.size.width / totalSeconds

    let xLabelSize = 40 × 40

    // Create a paragraph style for centering text.
    let centered = NSMutableParagraphStyle()
    centered.alignment = .center

    attributes[NSAttributedStringKey.paragraphStyle] = centered

    // Iterate every five seconds through `totalSeconds`.
    for t in stride(from: CGFloat(), through: totalSeconds, by: 5) {

      // Create the label using the number of seconds for this iteration.
      let label = "\(Int(t))" as NSString

      // Calculate the label's height.
      let labelHeight = label.size(withAttributes: attributes).height

      // Calculate the origin for the label.
      let labelOrigin = CGPoint(x: plotRect.origin.x + pointsPerSecond * t,
                                y: plotRect.maxY + 20 - labelHeight/2)

      // Create the rectangle within which to draw the label.
      let labelRect = CGRect(origin: labelOrigin, size: xLabelSize)

      // Draw the label.
      label.draw(in: labelRect, withAttributes: attributes)

    }

    // Establish the width of the color map.
    let colorMapWidth: CGFloat = 37

    // Calculate the height for each color index's rectangle.
    let cmIndexHeight = plotRect.size.height/CGFloat(colorMap.count)

    // Calculate the rectangle for the color map.
    let cmRect = CGRect(x: plotRect.maxX + 20, y: plotRect.origin.y,
                        width: colorMapWidth, height: plotRect.size.height)

    // Calculate the size of the rectangle for a single color map index.
    let colorMapIndexSize = colorMapWidth × cmIndexHeight

    // Iterate through the reversed color map indices.
    for (i, colorIndex) in (colorMap.startIndex..<colorMap.endIndex).reversed().enumerated() {

      // Calculate the y offset for this color index.
      let yOffset = CGFloat(i) * colorMapIndexSize.height

      // Create the origin for this color index.
      let colorMapIndexOrigin = CGPoint(x: cmRect.origin.x,
                                        y: cmRect.origin.y + yOffset)

      // Create the rectangle for this color index.
      let colorMapIndexRect = CGRect(origin: colorMapIndexOrigin, size: colorMapIndexSize)

      // Set the fill to the color for this index.
      colorMap[colorIndex].setFill()

      // Fill the rectangle with the color.
      context.fill(colorMapIndexRect)

    }

    // Outline the color map.
    context.stroke(cmRect, width: 1)

    let valueRange = colorMap.valueRange
    let colorMapLabels = stride(from: valueRange.lowerBound,
                                through: valueRange.upperBound,
                                by: CGFloat(colorMap.count/64)/10).reversed()

    for (i, f) in colorMapLabels.enumerated() {


      let label = "\(f)" as NSString

      let labelHeight = label.size(withAttributes: attributes).height
      let yOffset = cmRect.size.height * (CGFloat(i)/10) + cmIndexHeight/2 - labelHeight/2 - 6

      let labelOrigin = CGPoint(x: cmRect.maxX + 4, y: cmRect.origin.y + yOffset)

      let labelRect = CGRect(origin: labelOrigin, size: colorMapWidth × labelHeight)

      label.draw(in: labelRect, withAttributes: attributes)

    }

    // Unwrap the optional title and draw when non-nil.
    if let title = title as NSString? {

      let titleAttributes: [NSAttributedStringKey:Any] = [
        .font: (CTFont.bold as Font).withSize(22),
        .paragraphStyle: centered
      ]

      // Get the height of the title.
      let titleHeight = title.size(withAttributes: titleAttributes).height

      // Create the origin and size for the title's rectangle.
      let titleOrigin = CGPoint(x: 0, y: 25 - titleHeight/2)
      let titleSize = rect.size.width × 50

      // Draw the title.
      title.draw(in: CGRect(origin: titleOrigin, size: titleSize),
                 withAttributes: titleAttributes)

    }

  }

}

public func pitchPlot(features: PitchFeatures,
                      title: String? = nil,
                      mapKind: ColorMap.Kind = .heat) -> Image
{
  return pitchPlot(features: features, range: 0...127, title: title, mapKind: mapKind)

/*
  let rect = CGRect(origin: .zero, size: 866×715)

  let (context, bitmap, bitmapByteCount) = createImageContext(size: rect.size)

  // Create a color map to use for fill colors.
  let colorMap = ColorMap(size: .s64)

  // Establish the amount of vertical space allotted to the title.
  let titleHeight: CGFloat = title == nil ? 8 : 50

  // Get the origin offset and plot size from `rect`.
  let plotOrigin = CGPoint(x: rect.origin.x + 40, y: rect.origin.y + titleHeight)
  let plotSize = (rect.size.width - 146) × (rect.size.height - 40 - titleHeight)
  let plotRect = CGRect(origin: plotOrigin, size: plotSize)

  // Calculate the total number of columns in the plot.
  let columnCount = CGFloat(features.count)

  // The number of rows for a pitch-based spectrogram is always `128`.
  let rowCount: CGFloat = 128

  // Calculate the size for each value box.
  let rowHeight = plotSize.height / rowCount
  let columnWidth = plotSize.width / columnCount
  let dataBoxSize = columnWidth × rowHeight

  // Map the provided values to a tuple with the value's box and color index.
  let dataBoxes = features.enumerated().map {
    (column: Int, vector: PitchVector) -> [(CGRect, Int)] in

    // Map the rows for this `column`.
    (0..<128).map {

      // Calculate the origin assuming `rect.origin` is (0, 0).
      var origin = CGPoint(x: CGFloat(column) * columnWidth,
                           y: rowHeight * (127 - CGFloat($0)))

      // Adjust `origin` according to actual `rect.origin`.
      origin.x += plotOrigin.x
      origin.y += plotOrigin.y

      // Create the rect.
      let rect = CGRect(origin: origin, size: dataBoxSize)

      // Get the value for this column.
      var value = vector[$0]

      if value < 0 {
        print("\(#function) warning - clamping negative value to 0: \(value)")
        value = 0

      }

      if value > 1 {
        print("\(#function) warning - clamping positive value to 1: \(value)")
        value = 1
      }

      // Get the color index for the value.
      let colorIndex = colorMap[max(min(vector[$0], 1), 0)]

      // Return a tuple with the box rect and color index.
      return (rect, colorIndex)

    }

  }

  // Fill the rectangle with white.
  context.setFillColor(Color.white.cgColor)
  context.fill(rect)

  // Fill the plot with black.
  context.setFillColor(Color.black.cgColor)
  context.fill(plotRect)

  // Iterate through the columns.
  for column in dataBoxes {

    // Iterate through the rows of this column.
    for (rect, i) in column {

      // Set the fill color according the color index.
      colorMap[i].setFill()

      // Fill the rect for this row in this column.
      context.fill(rect)

    }

  }

  // Set black as the stroke color and outline the plot.
  context.setStrokeColor(Color.black.cgColor)
  context.stroke(plotRect, width: 1)

  // Create a paragraph style for centering text.
  let centered = NSMutableParagraphStyle()
  centered.alignment = .center

  // Create an attributes dictionary for the axis labels.
  let attributes: [NSAttributedStringKey:Any] = [
    .font: (CTFont.light as Font).withSize(18),
    .paragraphStyle: centered
  ]

  // Create a uniform size for the label rectangles.
  let yLabelSize = 40 × 40

  // Set the fill color back to black.
  context.setFillColor(Color.black.cgColor)

  for p in stride(from: 30, through: 100, by: 10) {

    let d = CGFloat(128 - p)
    let yOffset = d * rowHeight

    let label = "\(p)"

    let labelHeight = (label as NSString).size(withAttributes: attributes).height

    // Calculate the origin for the label.
    let labelOrigin = CGPoint(x: rect.origin.x,
                              y: plotRect.origin.y + yOffset + rowHeight/2 - labelHeight/2)

    // Create the rectangle within which to draw the label.
    let labelRect = CGRect(origin: labelOrigin, size: yLabelSize)

    // Draw the label.
    (label as NSString).draw(in: labelRect, withAttributes: attributes)

  }

  // Determine the total number of seconds represented in the plot.
  let totalSeconds = CGFloat(features.count) / CGFloat(features.featureRate)

  // Determine the number of plot points that correspond to one second.
  let pointsPerSecond = plotRect.size.width / totalSeconds

  let xLabelSize = 40 × 40

  // Iterate every five seconds through `totalSeconds`.
  for t in stride(from: CGFloat(), through: totalSeconds, by: 5) {

    // Create the label using the number of seconds for this iteration.
    let label = "\(Int(t))"

    // Calculate the label's height.
    let labelHeight = (label as NSString).size(withAttributes: attributes).height

    // Calculate the origin for the label.
    let labelOrigin = CGPoint(x: plotRect.origin.x + pointsPerSecond * t - 20,
                              y: plotRect.maxY + 20 - labelHeight/2)

    // Create the rectangle within which to draw the label.
    let labelRect = CGRect(origin: labelOrigin, size: xLabelSize)

    // Draw the label.
    (label as NSString).draw(in: labelRect, withAttributes: attributes)

  }

  // Establish the width of the color map.
  let colorMapWidth: CGFloat = 37

  // Calculate the height for each color index's rectangle.
  let cmIndexHeight = plotRect.size.height/CGFloat(colorMap.count)

  // Calculate the rectangle for the color map.
  let cmRect = CGRect(x: plotRect.maxX + 10, y: plotRect.origin.y,
                      width: colorMapWidth, height: plotRect.size.height)

  // Calculate the size of the rectangle for a single color map index.
  let colorMapIndexSize = colorMapWidth × cmIndexHeight

  // Iterate through the reversed color map indices.
  for (i, colorIndex) in colorMap.indices.reversed().enumerated() {

    // Calculate the y offset for this color index.
    let yOffset = CGFloat(i) * colorMapIndexSize.height

    // Create the origin for this color index.
    let colorMapIndexOrigin = CGPoint(x: cmRect.origin.x,
                                      y: cmRect.origin.y + yOffset)

    // Create the rectangle for this color index.
    let colorMapIndexRect = CGRect(origin: colorMapIndexOrigin, size: colorMapIndexSize)

    // Set the fill to the color for this index.
    colorMap[colorIndex].setFill()

    // Fill the rectangle with the color.
    context.fill(colorMapIndexRect)

  }

  // Outline the color map.
  context.stroke(cmRect, width: 1)

  for f in stride(from: CGFloat(0.0), through: 1.0, by: 0.1).reversed() {

    let label = "\(f)" as NSString

    let labelHeight = label.size(withAttributes: attributes).height

    let yOffset = cmRect.size.height * (1 - f) + cmIndexHeight/2 - labelHeight/2 - 6

    let labelOrigin = CGPoint(x: cmRect.maxX + 4, y: cmRect.origin.y + yOffset)

    let labelRect = CGRect(origin: labelOrigin, size: colorMapWidth × labelHeight)

    label.draw(in: labelRect, withAttributes: attributes)

  }

  // Unwrap the optional title and draw when non-nil.
  if let title = title as NSString? {

    let titleAttributes: [NSAttributedStringKey:Any] = [
      .font: (CTFont.bold as Font).withSize(22),
      .paragraphStyle: centered
    ]

    // Get the height of the title.
    let titleHeight = title.size(withAttributes: titleAttributes).height

    // Create the origin and size for the title's rectangle.
    let titleOrigin = CGPoint(x: 0, y: 25 - titleHeight/2)
    let titleSize = rect.size.width × 50

    // Draw the title.
    title.draw(in: CGRect(origin: titleOrigin, size: titleSize),
               withAttributes: titleAttributes)

  }

  let image = UIGraphicsGetImageFromCurrentImageContext()!

  UIGraphicsEndImageContext()

  return image
*/

}

public func pitchPlot(features: PitchFeatures,
                      range: CountableClosedRange<Pitch>,
                      title: String? = nil,
                      mapKind: ColorMap.Kind = .heat) -> Image
{


  // Establish the height of one row.
  let rowHeight: CGFloat = 20

  // Establish the number of rows to plot.
  let rowCount = CGFloat(range.count)

  let imageSize = 866×(rowHeight * rowCount + 90)

  return createImage(size: imageSize) {
    context in

    // Create the bounding box with the height dictated by the number of rows.
    let rect = CGRect(origin: .zero, size: imageSize)

    // Create a color map to use for fill colors.
    let colorMap = ColorMap(size: .s64, kind: mapKind)

    // Establish the amount of vertical space allotted to the title.
    let titleHeight: CGFloat = title == nil ? 8 : 50

    // Get the origin offset and plot size from `rect`.
    let plotOrigin = CGPoint(x: rect.origin.x + 50, y: rect.origin.y + titleHeight)
    let plotSize = (rect.size.width - 146) × (rect.size.height - 40 - titleHeight)
    let plotRect = CGRect(origin: plotOrigin, size: plotSize)

    // Calculate the total number of columns in the plot.
    let columnCount = CGFloat(features.count)

    // Calculate the size for each value box.
    let columnWidth = plotSize.width / columnCount
    let dataBoxSize = columnWidth × rowHeight

    // Map the provided values to a tuple with the value's box and color index.
    let dataBoxes = features.enumerated().map {
      (column: Int, vector: PitchVector) -> [(CGRect, Int)] in

      // Map the rows for this `column`.
      range.map {

        // Calculate the row for this pitch.
        let row = CGFloat($0.rawValue - range.lowerBound.rawValue)

        // Calculate the origin assuming `rect.origin` is (0, 0).
        var origin = CGPoint(x: CGFloat(column) * columnWidth,
                             y: rowHeight * (rowCount - row - 1))

        // Adjust `origin` according to actual `rect.origin`.
        origin.x += plotOrigin.x
        origin.y += plotOrigin.y

        // Create the rect.
        let rect = CGRect(origin: origin, size: dataBoxSize)

        // Get the value for this column.
        var value = vector[$0]
        if value.isInfinite || value.isNaN { value = 0 }

        if value < 0 {
          print("\(#function) warning - clamping negative value to 0: \(value)")
          value = 0

        }

        if value > 1 {
          print("\(#function) warning - clamping positive value to 1: \(value)")
          value = 1
        }

        // Get the color index for the value.
        let colorIndex = colorMap[max(min(value, 1), 0)]

        // Return a tuple with the box rect and color index.
        return (rect, colorIndex)

      }

    }

    // Fill the rectangle with white.
    context.setFillColor(Color.white.cgColor)
    context.fill(rect)

    // Fill the plot with the color map's preffered background color.
    colorMap.preferredBackgroundColor.setFill()
    context.fill(plotRect)

    // Iterate through the columns.
    for column in dataBoxes {

      // Iterate through the rows of this column.
      for (rect, i) in column {

        // Set the fill color according the color index.
        colorMap[i].setFill()

        // Fill the rect for this row in this column.
        context.fill(rect)

      }

    }

    // Set black as the stroke color and outline the plot.
    context.setStrokeColor(Color.black.cgColor)
    context.stroke(plotRect, width: 1)

    // Create an attributes dictionary for the axis labels.
    var attributes: [NSAttributedStringKey:Any] = [
      .font: (CTFont.light as Font).withSize(18)
    ]

    // Create a uniform size for the label rectangles.
    let yLabelSize = 40 × rowHeight

    // Set the fill color back to black.
    context.setFillColor(Color.black.cgColor)

    for pitch in range {

      let row = CGFloat(pitch.rawValue - range.lowerBound.rawValue)
      let d = rowCount - row - 1
      let yOffset = d * rowHeight

      let label = pitch.description as NSString

      let labelHeight = label.size(withAttributes: attributes).height

      // Calculate the origin for the label.
      let labelOrigin = CGPoint(x: rect.origin.x + 6,
                                y: plotRect.origin.y + yOffset + rowHeight/2 - labelHeight/2)

      // Create the rectangle within which to draw the label.
      let labelRect = CGRect(origin: labelOrigin, size: yLabelSize)

      // Draw the label.
      label.draw(in: labelRect, withAttributes: attributes)

    }

    // Create a paragraph style for centering text.
    let centered = NSMutableParagraphStyle()
    centered.alignment = .center

    // Insert the paragraph style into the dictionary of attributes.
    attributes[.paragraphStyle] = centered

    // Determine the total number of seconds represented in the plot.
    let totalSeconds = CGFloat(features.count) / CGFloat(features.featureRate)

    // Determine the number of plot points that correspond to one second.
    let pointsPerSecond = plotRect.size.width / totalSeconds

    let xLabelSize = 40 × 40

    // Iterate every five seconds through `totalSeconds`.
    for t in stride(from: CGFloat(), through: totalSeconds, by: 5) {

      // Create the label using the number of seconds for this iteration.
      let label = "\(Int(t))"

      // Calculate the label's height.
      let labelHeight = (label as NSString).size(withAttributes: attributes).height

      // Calculate the origin for the label.
      let labelOrigin = CGPoint(x: plotRect.origin.x + pointsPerSecond * t - 20,
                                y: plotRect.maxY + 20 - labelHeight/2)

      // Create the rectangle within which to draw the label.
      let labelRect = CGRect(origin: labelOrigin, size: xLabelSize)

      // Draw the label.
      (label as NSString).draw(in: labelRect, withAttributes: attributes)

    }

    // Establish the width of the color map.
    let colorMapWidth: CGFloat = 37

    // Calculate the height for each color index's rectangle.
    let cmIndexHeight = plotRect.size.height/CGFloat(colorMap.count)

    // Calculate the rectangle for the color map.
    let cmRect = CGRect(x: plotRect.maxX + 10, y: plotRect.origin.y,
                        width: colorMapWidth, height: plotRect.size.height)

    // Calculate the size of the rectangle for a single color map index.
    let colorMapIndexSize = colorMapWidth × cmIndexHeight

    // Iterate through the reversed color map indices.
    for (i, colorIndex) in colorMap.indices.reversed().enumerated() {

      // Calculate the y offset for this color index.
      let yOffset = CGFloat(i) * colorMapIndexSize.height

      // Create the origin for this color index.
      let colorMapIndexOrigin = CGPoint(x: cmRect.origin.x,
                                        y: cmRect.origin.y + yOffset)

      // Create the rectangle for this color index.
      let colorMapIndexRect = CGRect(origin: colorMapIndexOrigin, size: colorMapIndexSize)

      // Set the fill to the color for this index.
      colorMap[colorIndex].setFill()

      // Fill the rectangle with the color.
      context.fill(colorMapIndexRect)

    }

    // Outline the color map.
    context.stroke(cmRect, width: 1)

    for f in stride(from: CGFloat(0.0), through: 1.0, by: 0.1).reversed() {

      let label = "\(f)" as NSString

      let labelHeight = label.size(withAttributes: attributes).height

      let yOffset = cmRect.size.height * (1 - f) + cmIndexHeight/2 - labelHeight/2 - 6

      let labelOrigin = CGPoint(x: cmRect.maxX + 4, y: cmRect.origin.y + yOffset)

      let labelRect = CGRect(origin: labelOrigin, size: colorMapWidth × labelHeight)

      label.draw(in: labelRect, withAttributes: attributes)

    }

    // Unwrap the optional title and draw when non-nil.
    if let title = title as NSString? {

      let titleAttributes: [NSAttributedStringKey:Any] = [
        .font: (CTFont.bold as Font).withSize(22),
        .paragraphStyle: centered
      ]

      // Get the height of the title.
      let titleHeight = title.size(withAttributes: titleAttributes).height

      // Create the origin and size for the title's rectangle.
      let titleOrigin = CGPoint(x: 0, y: 25 - titleHeight/2)
      let titleSize = rect.size.width × 50

      // Draw the title.
      title.draw(in: CGRect(origin: titleOrigin, size: titleSize),
                 withAttributes: titleAttributes)

    }

  }

}

public func FscoreBarGraph(scores: [Float],
                           in rect: CGRect,
                           title: String? = nil,
                           barColor: Color = .black) -> Image
{

  return createImage(size: rect.size) {
    context in

    // Establish the amount of vertical space allotted to the title.
    let titleHeight: CGFloat = title == nil ? 8 : 50

    // Get the origin offset and graph size from `rect`.
    let graphOrigin = CGPoint(x: rect.origin.x + 40, y: rect.origin.y + titleHeight)
    let graphSize = (rect.size.width - 50) × (rect.size.height - 40 - titleHeight)
    let graphRect = CGRect(origin: graphOrigin, size: graphSize)

    // Calculate the total number of columns in the graph.
    let columnCount = CGFloat(scores.count)

    // Calculate the width of each column.
    let columnWidth = graphSize.width / columnCount

    // Specify the max height for a column's box.
    let columnMaxHeight = graphSize.height

    // Map the scores to rectangles for bars to be drawn.
    let scoreBoxes = scores.enumerated().map {
      (column: Int, score: Float) -> CGRect in

      // Convert `score` into a `CGFloat`.
      let score = CGFloat(score)

      // Calculate the origin assuming `rect.origin` is (0, 0).
      var origin = CGPoint(x: CGFloat(column) * columnWidth,
                           y: columnMaxHeight * (1 - score))

      // Adjust `origin` according to actual `rect.origin`.
      origin.x += graphOrigin.x
      origin.y += graphOrigin.y

      // Calculate the size.
      let size = CGSize(width: columnWidth, height: columnMaxHeight * score)

      // Return the rectangle.
      return CGRect(origin: origin, size: size)

    }

    // Fill the rectangle with white.
    context.setFillColor(Color.white.cgColor)
    context.fill(rect)

    // Set the fill color for the boxes.
    context.setFillColor(barColor.cgColor)

    // Iterate through the columns.
    for box in scoreBoxes {

      // Fill this box.
      context.fill(box)

    }

    // Set black as the stroke color and outline the plot.
    context.setStrokeColor(Color.black.cgColor)
    context.stroke(graphRect, width: 1)

    // Create a paragraph style for centering text.
    let centered = NSMutableParagraphStyle()
    centered.alignment = .center

    // Create an attributes dictionary for the axis labels.
    let attributes: [NSAttributedStringKey:Any] = [
      .font: (CTFont.light as Font).withSize(18),
      .paragraphStyle: centered
    ]

    // Set the fill color back to black.
    context.setFillColor(Color.black.cgColor)

    // Iterate the score value range in 0.1 increments.
    for value in stride(from: CGFloat(), through: 1, by: 0.1) {

      // Calculate the y offset for this value.
      let yOffset = (1 - value) * graphSize.height

      // Create a label for this value.
      let label = String(format: "%.1f", value) as NSString

      // Calculate the label's size.
      let size = label.size(withAttributes: attributes)

      // Calculate the origin for the label.
      let origin = CGPoint(x: graphOrigin.x - size.width - 8,
                           y: graphOrigin.y + yOffset - size.height/2)

      // Draw the label at `origin`.
      label.draw(at: origin, withAttributes: attributes)

    }

    // Determine the widest a bar label might be.
    let maxWidth = ((scores.count + 1).description as NSString).size(withAttributes: attributes).width

    // Calculate a stride for column labels by determining whether the columns are wide enough to
    // label them all padded by 2 on each side.
    let columnStride = columnWidth - 4 >= maxWidth ? 1 : Int((maxWidth / columnWidth).rounded(.up))

    // Iterate through the 1-indexed bars with `columnStride`.
    for bar in stride(from: 1, through: scores.count, by: columnStride) {

      // Calculate the x offset for this bar.
      let xOffset = (CGFloat(bar - 1) / CGFloat(scores.count)) * graphSize.width + columnWidth / 2

      // Create a label for this bar.
      let label = bar.description as NSString

      // Calculate the label's size.
      let size = label.size(withAttributes: attributes)

      // Calculate the origin for the label.
      let origin = CGPoint(x: graphOrigin.x + xOffset - size.width / 2, y: graphRect.maxY + 8)

      // Draw the label at `origin`.
      label.draw(at: origin, withAttributes: attributes)

    }

    // Unwrap the optional title and draw when non-nil.
    if let title = title as NSString? {

      let titleAttributes: [NSAttributedStringKey:Any] = [
        .font: (CTFont.bold as Font).withSize(22),
        .paragraphStyle: centered
      ]

      // Get the height of the title.
      let titleHeight = title.size(withAttributes: titleAttributes).height

      // Create the origin and size for the title's rectangle.
      let titleOrigin = CGPoint(x: 0, y: 25 - titleHeight/2)
      let titleSize = rect.size.width × 50

      // Draw the title.
      title.draw(in: CGRect(origin: titleOrigin, size: titleSize),
                 withAttributes: titleAttributes)

    }

  }

}

