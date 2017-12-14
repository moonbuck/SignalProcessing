//
//  GraphingHelpers.swift
//  SignalProcessing
//
//  Created by Jason Cardwell on 12/11/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation

#if os(iOS)
  import UIKit
#else
  import AppKit
#endif

/// Draws data boxes for a spectrogram.
///
/// - Parameters:
///   - dataBoxes: The data to plot organized as columns of box-color index tuples.
///   - context: The context within which to draw.
///   - plotRect: The rectangle encapsulating the data boxes.
///   - colorMap: The color map used to retrieve box colors.
///   - outline: Whether to stroke `plotRect` after drawing the data boxes.
internal func draw(dataBoxes: [[Int]],
                  in context: CGContext,
                  plotRect: CGRect,
                  using colorMap: ColorMap,
                  outline: Bool = true)
{

  // Fill the plot with the color map's preffered background color.
  context.setFillColor(colorMap.preferredBackgroundColor.cgColor)
  context.fill(plotRect)

  let rowCount = dataBoxes.map(\.count).max() ?? 0
  guard rowCount > 0 else { return }

  guard dataBoxes.filter({$0.count != rowCount }).isEmpty else {
    fatalError("All columns must have the same number of rows.")
  }

  let rowHeight = plotRect.size.height / CGFloat(rowCount)

  let columnCount = dataBoxes.count

  let columnWidth = plotRect.width / CGFloat(columnCount)

  let xOrigin = plotRect.minX
  let yOrigin = plotRect.minY

  let boxSize = columnWidth × rowHeight

  // Iterate through the columns.
  for (columnIndex, column) in dataBoxes.enumerated() {

    // Iterate through the rows of this column.
    for (rowIndex, colorIndex) in column.enumerated() {

      let xOffset = CGFloat(columnIndex) * columnWidth
      let yOffset = CGFloat(rowCount - rowIndex - 1) * rowHeight

      let rect = CGRect(origin: CGPoint(x: xOrigin + xOffset, y: yOrigin + yOffset),
                        size: boxSize)

      // Set the fill color according the color index.
      context.setFillColor(colorMap[colorIndex].cgColor)
      context.setStrokeColor(colorMap[colorIndex].cgColor)

      // Fill the rect for this row in this column.
      context.fill(rect)
      context.stroke(rect)

    }

  }

  // Check whether to outline the data boxes.
  guard outline else { return }

  // Set black as the stroke color and outline the plot.
  context.setStrokeColor(Color.black.cgColor)
  context.stroke(plotRect, width: 2)

}

/// Draws the x axis labels for a feature plot.
///
/// - Parameters:
///   - context: The context in which to draw the labels.
///   - plotRect: The bounding rectangle for the data plot.
///   - featureCount: The total number of features (columns).
///   - featureRate: The feature rate in Hz.
///   - font: The font to use when drawing the labels.
///   - minSpace: The minimum amount of horizontal space between labels.
internal func drawXLabels(in context: CGContext,
                          plotRect: CGRect,
                          featureCount: Int,
                          featureRate: CGFloat,
                          font: Font,
                          minSpace: CGFloat = 20)
{

  // Determine the total number of seconds represented in the plot.
  let totalSeconds = CGFloat(featureCount) / featureRate

  // Get the time in seconds for the start of each frame.
  let frameStartTimes = (0..<featureCount).map({CGFloat($0) / featureRate})

  // Calculate the width of each frame.
  let frameWidth = plotRect.width / CGFloat(featureCount)

  // Generate a label for each frame.
  let xLabels: [String] = frameStartTimes.map({
    String(describing: $0, maxPrecision: 3, minPrecision: 1)
  })

  // Create the attributes with which to draw the labels.
  let attributes: [NSAttributedStringKey:Any] = [.font: font]

  // Calculate the label sizes.
  let labelSizes = xLabels.map({($0 as NSString).size(withAttributes: attributes)})

  // Get the largest width value.
  guard let maxLabelWidth = labelSizes.map(\.width).max() else { return }

  // Determine the number of plot points that correspond to one second.
  let pointsPerSecond = plotRect.width / totalSeconds

  // Calculate the number of labels that will fit without overlap.
  let labelCount = min(Int(plotRect.width / (maxLabelWidth + minSpace)), featureCount)

  // Calculate the stride needed to draw `labelCount` labels.
  let strideLength = Int(ceil(CGFloat(featureCount) / CGFloat(labelCount)))

  // Set the stroke and fill colors.
  context.setFillColor(Color.black.cgColor)
  context.setStrokeColor(Color.black.cgColor)

  // Iterate by striding through the time through `totalSeconds`.
  for index in stride(from: 0, to: featureCount, by: strideLength) {

    // Get the frame's start time.
    let startTime = frameStartTimes[index]

    // Get the size of the label.
    let labelSize = labelSizes[index]

    // Calculate the frame's offset from the plot origin.
    let xOffset = startTime * pointsPerSecond

    // Calculate the origin for the label.
    let labelOrigin = CGPoint(x: plotRect.minX + xOffset - labelSize.width / 2,
                              y: plotRect.maxY + 10)

    // Draw the label.
    (xLabels[index] as NSString).draw(at: labelOrigin, withAttributes: attributes)

    // Calculate the offset to the start of the frame.
    let frameOffset = frameWidth * CGFloat(index)

    // Calculate the two points for the marker.
    let markerStart = CGPoint(x: plotRect.minX + frameOffset, y: plotRect.maxY + 8)
    let markerEnd = CGPoint(x: plotRect.minX + frameOffset, y: plotRect.maxY)

    // Draw the marker.
    context.strokeLineSegments(between: [markerStart, markerEnd])

  }

}

/// Draws labels for the y axis.
///
/// - Parameters:
///   - yLabels: The labels to draw in ascending order.
///   - context: The context within which to draw the labels.
///   - plotRect: The bounding rectangle for the values of the graph.
///   - alignment: How the labels should be aligned.
///   - minSpace: The minimum amount of vertical space between labels. The default is `4`.
/// - Returns: The attributes used to draw the labels.
internal func draw(yLabels: [String],
                   in context: CGContext,
                   plotRect: CGRect,
                   alignment: NSTextAlignment,
                   minSpace: CGFloat = 4) -> [NSAttributedStringKey:Any]
{

  // Get the total number of rows.
  let rowCount = yLabels.count

  // Calculate the height of each row.
  let rowHeight = plotRect.height / CGFloat(rowCount)

  // Calculate a reasonable point size for the font.
  let pointSize = max(min(rowHeight, 18), 12)

  // Create the font.
  let font = (CTFont.light as Font).withSize(pointSize)

  // Create a paragraph style with a line height equal to the font's point size.
  let style = NSMutableParagraphStyle()
  style.lineSpacing = 0
  style.minimumLineHeight = pointSize
  style.maximumLineHeight = pointSize

  // Create the attributes dictionary for sizing and drawing the label.
  let attributes: [NSAttributedStringKey:Any] = [.font: font, .paragraphStyle: style]

  // Map the labels to their sizes.
  let labelSizes = yLabels.map({($0 as NSString).size(withAttributes: attributes)})

  // Get the largest width value.
  guard let maxLabelWidth = labelSizes.map(\.width).max() else { return attributes }

  // Set the stroke and fill colors.
  context.setFillColor(Color.black.cgColor)
  context.setStrokeColor(Color.black.cgColor)

  // Establish the amount of white space between the axis and the labels.
  let axisPadding: CGFloat = 10

  // Calculate a stride length that allows for drawing as many labels as possible while
  // maintaining the legibility of the labels.
  let strideLength = Int(ceil((pointSize + minSpace) / rowHeight))

  // Iterate the row indices by the calculated stride.
  for rowIndex in stride(from: 0, to: rowCount, by: strideLength) {

    // Calculate the vertical center for the row.
    let centerY = plotRect.minY  + CGFloat(rowCount - rowIndex - 1) * rowHeight + rowHeight / 2

    // Retrieve the label size.
    let labelSize = labelSizes[rowIndex]

    // Calculate the vertical offset for the label by negating half the label's height and adding
    // a twiddle factor of 2.
    let yOffset = -labelSize.height / 2 + 2

    // Establish a variable for holding the label's horizontal offset.
    let xOffset: CGFloat

    // Switch on the specified label alignment.
    switch alignment {

      case .left:

        // Left-align the labels by subtracting the padding and the width of the longest label.
        xOffset = -axisPadding - maxLabelWidth

      case .right:

        // Right align by subtracting the padding and the width of the label
        xOffset = -axisPadding - labelSize.width

      default:

        // Center align by subtracting the padding and the width of the longest label and
        // adding back half the label's actual width.
        xOffset = -axisPadding - maxLabelWidth + labelSize.width / 2

    }

    // Calculate the origin for the label.
    let origin = CGPoint(x: plotRect.minX + xOffset, y: centerY + yOffset)

    // Draw the label.
    (yLabels[rowIndex] as NSString).draw(at: origin, withAttributes: attributes)

    // Calculate the two points for the marker.
    let markerStart = CGPoint(x: plotRect.minX - 8, y: centerY)
    let markerEnd = CGPoint(x: plotRect.minX, y: centerY)

    // Draw the marker.
    context.strokeLineSegments(between: [markerStart, markerEnd])
  }

  return attributes

}

/// Draws a grid across the plot to aid with debugging graphing functions.
///
/// - Parameters:
///   - context: The context in which to draw the grid.
///   - plotRect: The bounding rectangle for the plot.
///   - totalRows: The total number of rows in the graph.
///   - totalColumns: The total number of columns in the graph.
internal func drawGrid(with context: CGContext,
                       plotRect: CGRect,
                       totalRows: Int,
                       totalColumns: Int)
{

  let rowHeight = plotRect.height / CGFloat(totalRows)
  let halfRowHeight = rowHeight / 2

  for row in 0 ..< totalRows {

    var offset = CGFloat(row) * rowHeight

    context.setStrokeColor(Color.red.cgColor)
    context.setLineWidth(2)

    context.strokeLineSegments(between: [CGPoint(x: plotRect.minX, y: plotRect.minY + offset),
                                         CGPoint(x: plotRect.maxX, y: plotRect.minY + offset)])

    offset += halfRowHeight

    context.setLineWidth(1)
    context.setStrokeColor(Color.blue.cgColor)

    context.strokeLineSegments(between: [CGPoint(x: plotRect.minX, y: plotRect.minY + offset),
                                         CGPoint(x: plotRect.maxX, y: plotRect.minY + offset)])
  }

  context.setStrokeColor(Color.red.cgColor)
  context.setLineWidth(2)

  context.strokeLineSegments(between: [CGPoint(x: plotRect.minX, y: plotRect.maxY),
                                       CGPoint(x: plotRect.maxX, y: plotRect.maxY)])

  let columnWidth = plotRect.width / CGFloat(totalColumns)
  let halfColumnWidth = columnWidth / 2

  for column in 0 ..< totalColumns {

    var offset = CGFloat(column) * columnWidth

    context.setStrokeColor(Color.red.cgColor)
    context.setLineWidth(2)

    context.strokeLineSegments(between: [CGPoint(x: plotRect.minX + offset, y: plotRect.minY),
                                         CGPoint(x: plotRect.minX + offset, y: plotRect.maxY)])

    offset += halfColumnWidth

    context.setLineWidth(1)
    context.setStrokeColor(Color.blue.cgColor)

    context.strokeLineSegments(between: [CGPoint(x: plotRect.minX + offset, y: plotRect.minY),
                                         CGPoint(x: plotRect.minX + offset, y: plotRect.maxY)])

  }

  context.setStrokeColor(Color.red.cgColor)
  context.setLineWidth(2)

  context.strokeLineSegments(between: [CGPoint(x: plotRect.maxX, y: plotRect.minY),
                                       CGPoint(x: plotRect.maxX, y: plotRect.maxY)])

}

/// Draws a color map legend to the right of a data plot.
///
/// - Parameters:
///   - colorMap: The color map for which to draw a legend.
///   - context: The context in which to draw the legend.
///   - plotRect: The bounding rectangle for the data plot.
///   - mapWidth: The width to make the color map legend.
///   - labelAttributes: The attributes to use when drawing legend labels.
internal func draw(colorMap: ColorMap,
                   in context: CGContext,
                   plotRect: CGRect,
                   mapWidth: CGFloat,
                   labelAttributes: [NSAttributedStringKey:Any])
{

  // Calculate the height for each color index's rectangle.
  let rowHeight = plotRect.height/CGFloat(colorMap.count)

  // Calculate the rectangle for the color map.
  let colorMapRect = CGRect(x: plotRect.maxX + 20, y: plotRect.minY,
                      width: mapWidth, height: plotRect.height)

  // Calculate the size of the rectangle for a single color map index.
  let colorMapIndexSize = mapWidth × rowHeight

  // Iterate through the reversed color map indices.
  for (index, colorIndex) in colorMap.indices.reversed().enumerated() {

    // Calculate the y offset for this color index.
    let yOffset = CGFloat(index) * rowHeight

    // Create the origin for this color index.
    let colorMapIndexOrigin = CGPoint(x: colorMapRect.minX,
                                      y: colorMapRect.minY + yOffset)

    // Create the rectangle for this color index.
    let colorMapIndexRect = CGRect(origin: colorMapIndexOrigin, size: colorMapIndexSize)

    // Set the fill to the color for this index.
    context.setFillColor(colorMap[colorIndex].cgColor)

    // Fill the rectangle with the color.
    context.fill(colorMapIndexRect)

  }

  // Outline the color map.
  context.stroke(colorMapRect, width: 1)

  let steps: [CGFloat] = [0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875, 1]

  for step in steps {

    let label = step.description as NSString

    let labelHeight = label.size(withAttributes: labelAttributes).height

    let yOffset = colorMapRect.height - colorMapRect.height * step - labelHeight / 2

    let origin = CGPoint(x: colorMapRect.maxX + 4, y: colorMapRect.minY + yOffset)

    label.draw(at: origin, withAttributes: labelAttributes)

  }

}

/// Draws the specified title into the specified context.
///
/// - Parameters:
///   - title: The title to draw.
///   - context: The context in which to draw `title`.
///   - imageRect: The bounding rectangle for the entire image.
internal func draw(title: String?, in context: CGContext, imageRect: CGRect) {

  // Unwrap the title.
  guard title != nil else { return }
  let title = title! as NSString

  // Create a paragraph style for centering text.
  let style = NSMutableParagraphStyle()
  style.alignment = .center

  // Create a font for the title.
  let font = (CTFont.bold as Font).withSize(22)

  let attributes: [NSAttributedStringKey:Any] = [.font: font, .paragraphStyle: style]

  // Get the height of the title.
  let titleHeight = title.size(withAttributes: attributes).height

  // Create the origin and size for the title's rectangle.
  let titleOrigin = CGPoint(x: 0, y: 50 - titleHeight/2)
  let titleSize = imageRect.width × 50

  // Draw the title.
  title.draw(in: CGRect(origin: titleOrigin, size: titleSize),
             withAttributes: attributes)

}
