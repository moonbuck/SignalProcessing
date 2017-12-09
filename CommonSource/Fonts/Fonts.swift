//
//  Fonts.swift
//  Chord Finder
//
//  Created by Jason Cardwell on 8/30/17.
//  Copyright (c) 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import CoreText

/// A set of names for bundled fonts that have been registered with the font manager.
private var registeredFonts: Set<String> = []

/// Retrieves the URL for a bundled font from the framework's bundle.
///
/// - Parameter name: The name of the font file without the extension.
/// - Returns: The URL for the bundled font with `name`.
private func url(forFont name: String) -> URL {

  let bundleIdentifer: String

  #if os(iOS)
    bundleIdentifer = "com.moondeerstudios.SignalProcessing-iOS"
  #else
    bundleIdentifer = "com.moondeerstudios.SignalProcessing-Mac"
  #endif

  guard let bundle = Bundle(identifier: bundleIdentifer) else {
    fatalError("Failed to retrieve the framework's bundle.")
  }

  guard let url = bundle.url(forResource: name, withExtension: "ttf") else {
    fatalError("Missing font '\(name)'")
  }

  return url

}

/// Registers a bundled font with the font manager.
///
/// - Parameter name: The name of the bundled font.
private func registerFont(name: String) {

  // Get the url for the bundled font.
  let fontURL = url(forFont: name) as NSURL

  // Register the font url with the font manager.
  guard CTFontManagerRegisterFontsForURL(fontURL, CTFontManagerScope.process, nil) else {
    fatalError("Font registration failed for font '\(name)'")
  }

  // Add the font name to the set of registered fonts.
  registeredFonts.insert(name)

}

/// Generates a `CTFont` from a font name. The font is registered with the font manager when
/// necessary.
///
/// - Parameter name: The name of the font.
/// - Returns: The font with `name` and a point size of `10`.
private func font(name: String, size: CGFloat = 10) -> CTFont {

  // Make sure the font has been registered.
  if !registeredFonts.contains(name) { registerFont(name: name) }

  // Return the font with a point size of `10`.
  return CTFontCreateWithName(name as CFString, size, nil)

}

extension CTFont {

  public static var halfLine: CTFont { return font(name: "InputMonoCompressed-Regular", size: 5) }
  public static var bold: CTFont { return font(name: "InputMonoCompressed-Bold") }
  public static var boldItalic: CTFont { return font(name: "InputMonoCompressed-BoldItalic") }
  public static var regular: CTFont { return font(name: "InputMonoCompressed-Regular") }
  public static var italic: CTFont { return font(name: "InputMonoCompressed-Italic") }
  public static var light: CTFont { return font(name: "InputMonoCompressed-Light") }
  public static var lightItalic: CTFont { return font(name: "InputMonoCompressed-LightItalic") }
  public static var extraLight: CTFont { return font(name: "InputMonoCompressed-ExtraLight") }
  public static var extraLightItalic: CTFont { return font(name: "InputMonoCompressed-ExtraLightItalic") }
  public static var thin: CTFont { return font(name: "InputMonoCompressed-Thin") }
  public static var thinItalic: CTFont { return font(name: "InputMonoCompressed-ThinItalic") }
  public static var medium: CTFont { return font(name: "InputMonoCompressed-Medium") }
  public static var mediumItalic: CTFont { return font(name: "InputMonoCompressed-MediumItalic") }
  public static var black: CTFont { return font(name: "InputMonoCompressed-Black") }
  public static var blackItalic: CTFont { return font(name: "InputMonoCompressed-BlackItalic") }

}
