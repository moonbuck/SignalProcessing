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
internal func draw(dataBoxes: [[Int]],
                  in context: CGContext,
                  plotRect: CGRect,
                  using colorMap: ColorMap)
{

  // Fill the plot with the color map's preffered background color.
  colorMap.preferredBackgroundColor.setFill()
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

  // Set black as the stroke color and outline the plot.
  context.setStrokeColor(Color.black.cgColor)
  context.stroke(plotRect, width: 1)

}

/// Draws the x axis labels for a feature plot.
///
/// - Parameters:
///   - context: The context in which to draw the labels.
///   - plotRect: The bounding rectangle for the data plot.
///   - featureCount: The total number of features (columns).
///   - featureRate: The feature rate in Hz.
///   - font: The font to use when drawing the labels.
internal func drawXLabels(in context: CGContext,
                          plotRect: CGRect,
                          featureCount: Int,
                          featureRate: CGFloat,
                          font: Font)
{

  // Determine the total number of seconds represented in the plot.
  let totalSeconds = CGFloat(featureCount) / featureRate

  // Determine the number of plot points that correspond to one second.
  let pointsPerSecond = plotRect.width / totalSeconds

  let xLabelSize = 40 × 40

  let steps = Int(plotRect.width / xLabelSize.width)

  let increment = totalSeconds / CGFloat(steps)

  let style = NSMutableParagraphStyle()
  style.alignment = .center

  let attributes: [NSAttributedStringKey:Any] = [.font: font, .paragraphStyle: style]

  // Iterate by striding through the time through `totalSeconds`.
  for step in 0 ... steps {

    let time = increment * CGFloat(step)

    // Create the label using the number of seconds for this iteration.
    let label = String(format: "%.1lf", time) as NSString

    // Calculate the label's height.
    let labelHeight = label.size(withAttributes: attributes).height

    // Calculate the origin for the label.
    let labelOrigin = CGPoint(x: plotRect.minX + pointsPerSecond * time - 20,
                              y: plotRect.maxY + 20 - labelHeight/2)

    // Create the rectangle within which to draw the label.
    let labelRect = CGRect(origin: labelOrigin, size: xLabelSize)

    // Draw the label.
    label.draw(in: labelRect, withAttributes: attributes)

  }

}

/// Draws labels for the y axis.
///
/// - Parameters:
///   - yLabels: The labels to draw in ascending order.
///   - context: The context within which to draw the labels.
///   - plotRect: The bounding rectangle for the values of the graph.
///   - labelWidth: The width to make the labels.
/// - Returns: The attributes used to draw the labels.
internal func draw(yLabels: [String],
                  in context: CGContext,
                  plotRect: CGRect,
                  labelWidth: CGFloat) -> [NSAttributedStringKey:Any]
{

  let rowCount = yLabels.count
  let rowHeight = plotRect.height / CGFloat(rowCount)

  // TODO: Handle row heights too small to use as font point sizes.

  let font = (CTFont.light as Font).withSize(min(rowHeight, 18))

  let style = NSMutableParagraphStyle()
  style.lineSpacing = 0
  style.maximumLineHeight = rowHeight

  let attributes: [NSAttributedStringKey:Any] = [.font: font, .paragraphStyle: style]

  context.setFillColor(Color.black.cgColor)

  for (rowIndex, label) in (yLabels as [NSString]).enumerated() {

    let labelSize = label.size(withAttributes: attributes)

    let padding = (rowHeight - labelSize.height) / 2

    let yOffset = CGFloat(rowCount - rowIndex - 1) * rowHeight + padding
    let origin = CGPoint(x: plotRect.minX - labelWidth, y: plotRect.minY + yOffset)

    label.draw(at: origin, withAttributes: attributes)

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
