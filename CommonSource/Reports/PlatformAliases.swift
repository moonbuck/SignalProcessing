//
//  PlatformAliases.swift
//  SignalProcessing
//
//  Created by Jason Cardwell on 12/8/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation

#if os(iOS)

  import UIKit

  public typealias Color = UIColor
  public typealias EdgeInsets = UIEdgeInsets
  public typealias BezierPath = UIBezierPath
  public typealias Font = UIFont

#else

  import AppKit

  public typealias Color = NSColor
  public typealias EdgeInsets = NSEdgeInsets
  public typealias BezierPath = NSBezierPath
  public typealias Font = NSFont

  extension NSFont {

    public func withSize(_ fontSize: CGFloat) -> NSFont {
      return NSFont(name: fontName, size: fontSize - 2)! // Size reduced to avoid clipping.
    }

  }

#endif