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

public func createImage(size: CGSize, drawingHandler: @escaping (CGContext) -> Void) -> Image {

  #if os(iOS)

    UIGraphicsBeginImageContextWithOptions(size, true, 0)

    guard let context = UIGraphicsGetCurrentContext() else {
      fatalError("Failed to create new image context.")
    }

    drawingHandler(context)

    guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
      fatalError("Failed to get image from current image context.")
    }

    UIGraphicsEndImageContext()

    return image

  #else

    return NSImage(size: NSSizeFromCGSize(size), flipped: true) {
      _ in

      guard let context = NSGraphicsContext.current else {
        fatalError("Failed to get current graphics context.")
      }

      drawingHandler(context.cgContext)

      return true
    }


  #endif

}


