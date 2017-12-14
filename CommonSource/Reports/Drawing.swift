//
//  Drawing.swift
//  SignalProcessing
//
//  Created by Jason Cardwell on 12/8/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation

#if os(iOS)
  import UIKit
#else
  import AppKit
#endif

public func createImage(size: CGSize,
                        isData: Bool = false,
                        drawingHandler: @escaping (CGContext) -> Void) -> Image
{

  let colorSpace: CGColorSpace
  let bytesPerRow: Int
  let bitmapInfo: UInt32

  if isData {

    guard let space = CGColorSpace(name: CGColorSpace.genericGrayGamma2_2) else {
      fatalError("Failed to create color space.")
    }
    colorSpace = space

    bytesPerRow = Int(size.width)
    bitmapInfo = CGImageAlphaInfo.none.rawValue


  } else {

    guard let space = CGColorSpace(name: CGColorSpace.sRGB) else {
      fatalError("Failed to create color space.")
    }
    colorSpace = space

    bytesPerRow = Int(size.width * 4)
    bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

  }

  // Create the context.
  guard let context = CGContext(data: nil,
                                width: Int(size.width),
                                height: Int(size.height),
                                bitsPerComponent: 8,
                                bytesPerRow: bytesPerRow,
                                space: colorSpace,
                                bitmapInfo: bitmapInfo)
  else
  {
    fatalError("Failed to create new bitmap context.")
  }

  // Flip the coordinate system.
  context.translateBy(x: 0, y: size.height)
  context.scaleBy(x: 1, y: -1)

  // Turn of antialiasing if `isData`.
  if isData { context.setShouldAntialias(false) }

  #if os(iOS)

    UIGraphicsPushContext(context)

  #else

    NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: true)

  #endif

  drawingHandler(context)

  guard let cgImage = context.makeImage() else {
    fatalError("Failed to get image from context.")
  }

  let image = Image(cgImage: cgImage)

  #if os(iOS)

    UIGraphicsPopContext()

  #else

    NSGraphicsContext.current = nil

  #endif

  return image

}


