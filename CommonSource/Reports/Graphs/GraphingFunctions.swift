import Foundation
import AVFoundation
import CoreText

#if os(iOS)
  import UIKit
#else
  import AppKit
#endif

private let DRAW_GRIDS = false

infix operator ×

public func ×(lhs: CGFloat, rhs: CGFloat) -> CGSize {
  return CGSize(width: lhs, height: rhs)
}


// MARK: - Plotting

public func chromaPlot(features: ChromaFeatures,
                       mapSize: ColorMap.Size = .s64,
                       mapKind: ColorMap.Kind = .grayscale,
                       title: String? = nil) -> Image
{
  return chromaPlot(features: features,
                    featureRate: CGFloat(features.featureRate),
                    mapSize: mapSize,
                    mapKind: mapKind,
                    title: title)
}

public func chromaPlot<Source>(features: Source,
                               featureRate: CGFloat,
                               mapSize: ColorMap.Size = .s64,
                               mapKind: ColorMap.Kind = .grayscale,
                               title: String? = nil) -> Image
  where Source:Collection, Source.Element == ChromaVector, Source.IndexDistance == Int
{

  // Establish the size of the image.
  let imageSize = 1000×800

  return createImage(size: imageSize) {
    context in

    let rect = CGRect(origin: .zero, size: imageSize)

    // Create a color map to use for fill colors.
    let colorMap = ColorMap(size: mapSize, kind: mapKind)

    // Establish the amount of vertical space allotted to the title.
    let titleHeight: CGFloat = title == nil ? 50 : 100

    // Get the origin offset and plot size from `rect`.
    let plotOrigin = CGPoint(x: rect.origin.x + 100, y: rect.origin.y + titleHeight)
    let plotSize = (rect.size.width - 246) × (rect.size.height - 80 - titleHeight)
    let plotRect = CGRect(origin: plotOrigin, size: plotSize)

    // Fill the rect with white.
    context.setFillColor(Color.white.cgColor)
    context.fill(rect)

    // Map the provided values their color indexes.
    let dataBoxes = features.map {$0.map({colorMap[$0]})}

    // Draw the data boxes.
    draw(dataBoxes: dataBoxes, in: context, plotRect: plotRect, using: colorMap)

    // Draw the y labels.
    let labelAttributes = draw(yLabels: Chroma.all.map(\.description),
                               in: context,
                               plotRect: plotRect,
                               labelWidth: 24)

    // Draw the x labels.
    drawXLabels(in: context,
                plotRect: plotRect,
                featureCount: features.count,
                featureRate: featureRate,
                font: labelAttributes[.font] as! Font)


    // Draw the color map.
    draw(colorMap: colorMap,
         in: context,
         plotRect: plotRect,
         mapWidth: 37,
         labelAttributes: labelAttributes)

    // Draw the title.
    draw(title: title, in: context, imageRect: rect)

    if DRAW_GRIDS {
      drawGrid(with: context, plotRect: plotRect, totalRows: 12, totalColumns: features.count)
    }

  }

}

public func pitchPlot(features: PitchFeatures,
                      range: CountableClosedRange<Pitch> = 0...127,
                      mapKind: ColorMap.Kind = .heat,
                      title: String? = nil) -> Image
{
  return pitchPlot(features: features,
                   featureRate: CGFloat(features.featureRate),
                   range: range,
                   mapKind: mapKind,
                   title: title)
}

public func pitchPlot<Source>(features: Source,
                              featureRate: CGFloat,
                              range: CountableClosedRange<Pitch> = 0...127,
                              mapKind: ColorMap.Kind = .heat,
                              title: String? = nil) -> Image
  where Source:Collection,
        Source.Element == PitchVector,
        Source.IndexDistance == Int,
        Source.Index == Int
{

  // Establish the size of the image.
  let imageSize = 1000×(20 * CGFloat(range.count) + 200)

  return createImage(size: imageSize) {
    context in

    // Create the bounding box with the height dictated by the number of rows.
    let rect = CGRect(origin: .zero, size: imageSize)

    // Create a color map to use for fill colors.
    let colorMap = ColorMap(size: .s64, kind: mapKind)

    // Establish the amount of vertical space allotted to the title.
    let titleHeight: CGFloat = title == nil ? 50 : 100

    // Get the origin offset and plot size from `rect`.
    let plotOrigin = CGPoint(x: rect.origin.x + 100, y: rect.origin.y + titleHeight)
    let plotSize = (rect.size.width - 246) × (rect.size.height - 80 - titleHeight)
    let plotRect = CGRect(origin: plotOrigin, size: plotSize)

    // Fill the rectangle with white.
    context.setFillColor(Color.white.cgColor)
    context.fill(rect)

    // Map the provided values their color indexes.
    let dataBoxes = features.map {$0[range].map({colorMap[$0]})}

    // Draw the data boxes.
    draw(dataBoxes: dataBoxes, in: context, plotRect: plotRect, using: colorMap)

    // Draw the y labels.
    let labelAttributes = draw(yLabels: range.map(\.description),
                               in: context,
                               plotRect: plotRect,
                               labelWidth: 40)

    // Draw the x labels.
    drawXLabels(in: context,
                plotRect: plotRect,
                featureCount: features.count,
                featureRate: featureRate,
                font: labelAttributes[.font] as! Font)


    // Draw the color map.
    draw(colorMap: colorMap,
         in: context,
         plotRect: plotRect,
         mapWidth: 37,
         labelAttributes: labelAttributes)


    // Draw the title.
    draw(title: title, in: context, imageRect: rect)

    if DRAW_GRIDS {
      drawGrid(with: context, plotRect: plotRect, totalRows: range.count, totalColumns: features.count)
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

