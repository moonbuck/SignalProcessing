//
//  FontStyle.swift
//  Chord Finder
//
//  Created by Jason Cardwell on 8/30/17.
//  Copyright (c) 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import CoreText

private let halfLineParagraphStyle: CTParagraphStyle = {

  // Calculate the line spacing.
  var lineSpacing: CGFloat = -2.6

  // Create the paragraph style settings.
  var setting = CTParagraphStyleSetting(spec: .lineSpacingAdjustment,
                                        valueSize: MemoryLayout<CGFloat>.size,
                                        value: &lineSpacing)

  // Create the paragraph style.
  let paragraphStyle = CTParagraphStyleCreate(&setting, 1);

  return paragraphStyle

}()

private let paragraphStyle: CTParagraphStyle = {

  // Calculate the line spacing.
  var lineSpacing: CGFloat = -1.6

  // Create the paragraph style settings.
  var setting = CTParagraphStyleSetting(spec: .lineSpacingAdjustment,
                                        valueSize: MemoryLayout<CGFloat>.size,
                                        value: &lineSpacing)

  // Create the paragraph style.
  let paragraphStyle = CTParagraphStyleCreate(&setting, 1);

  return paragraphStyle

}()

private let paragraphStyleCentered: CTParagraphStyle = {

  // Calculate the line spacing.
  var lineSpacing: CGFloat = -1.6

  // Create the paragraph style settings.
  var lineSpacingSetting = CTParagraphStyleSetting(spec: .lineSpacingAdjustment,
                                                   valueSize: MemoryLayout<CGFloat>.size,
                                                   value: &lineSpacing)

  var alignment: CTTextAlignment = .center
  var alignmentSetting = CTParagraphStyleSetting(spec: .alignment,
                                                 valueSize: MemoryLayout<CTTextAlignment>.size,
                                                 value: &alignment)

  let settings = [lineSpacingSetting, alignmentSetting]

  // Create the paragraph style.
  let paragraphStyle = CTParagraphStyleCreate(settings, 2);

  return paragraphStyle

}()

private let halfLineAttributes: [NSAttributedStringKey:Any] = [
  .font: CTFont.halfLine,
  .paragraphStyle: halfLineParagraphStyle
]

private let thinAttributes: [NSAttributedStringKey:Any] = [
  .font: CTFont.thin,
  .paragraphStyle: paragraphStyle
]

private let extraLightAttributes: [NSAttributedStringKey:Any] = [
  .font: CTFont.extraLight,
  .paragraphStyle: paragraphStyle
]

private let lightAttributes: [NSAttributedStringKey:Any] = [
  .font: CTFont.light,
  .paragraphStyle: paragraphStyle
]

private let regularAttributes: [NSAttributedStringKey:Any] = [
  .font: CTFont.regular,
  .paragraphStyle: paragraphStyle
]

private let mediumAttributes: [NSAttributedStringKey:Any] = [
  .font: CTFont.medium,
  .paragraphStyle: paragraphStyle
]

private let boldAttributes: [NSAttributedStringKey:Any] = [
  .font: CTFont.bold,
  .paragraphStyle: paragraphStyle
]

private let blackAttributes: [NSAttributedStringKey:Any] = [
  .font: CTFont.black,
  .paragraphStyle: paragraphStyle
]

private let thinItalicAttributes: [NSAttributedStringKey:Any] = [
  .font: CTFont.thinItalic,
  .paragraphStyle: paragraphStyle
]

private let extraLightItalicAttributes: [NSAttributedStringKey:Any] = [
  .font: CTFont.extraLightItalic,
  .paragraphStyle: paragraphStyle
]

private let lightItalicAttributes: [NSAttributedStringKey:Any] = [
  .font: CTFont.lightItalic,
  .paragraphStyle: paragraphStyle
]

private let italicAttributes: [NSAttributedStringKey:Any] = [
  .font: CTFont.italic,
  .paragraphStyle: paragraphStyle
]

private let mediumItalicAttributes: [NSAttributedStringKey:Any] = [
  .font: CTFont.mediumItalic,
  .paragraphStyle: paragraphStyle
]

private let boldItalicAttributes: [NSAttributedStringKey:Any] = [
  .font: CTFont.boldItalic,
  .paragraphStyle: paragraphStyle
]

private let blackItalicAttributes: [NSAttributedStringKey:Any] = [
  .font: CTFont.blackItalic,
  .paragraphStyle: paragraphStyle
]

private let thinAttributesCentered: [NSAttributedStringKey:Any] = [
  .font: CTFont.thin,
  .paragraphStyle: paragraphStyleCentered
]

private let extraLightAttributesCentered: [NSAttributedStringKey:Any] = [
  .font: CTFont.extraLight,
  .paragraphStyle: paragraphStyleCentered
]

private let lightAttributesCentered: [NSAttributedStringKey:Any] = [
  .font: CTFont.light,
  .paragraphStyle: paragraphStyleCentered
]

private let regularAttributesCentered: [NSAttributedStringKey:Any] = [
  .font: CTFont.regular,
  .paragraphStyle: paragraphStyleCentered
]

private let mediumAttributesCentered: [NSAttributedStringKey:Any] = [
  .font: CTFont.medium,
  .paragraphStyle: paragraphStyleCentered
]

private let boldAttributesCentered: [NSAttributedStringKey:Any] = [
  .font: CTFont.bold,
  .paragraphStyle: paragraphStyleCentered
]

private let blackAttributesCentered: [NSAttributedStringKey:Any] = [
  .font: CTFont.black,
  .paragraphStyle: paragraphStyleCentered
]

private let thinItalicAttributesCentered: [NSAttributedStringKey:Any] = [
  .font: CTFont.thinItalic,
  .paragraphStyle: paragraphStyleCentered
]

private let extraLightItalicAttributesCentered: [NSAttributedStringKey:Any] = [
  .font: CTFont.extraLightItalic,
  .paragraphStyle: paragraphStyleCentered
]

private let lightItalicAttributesCentered: [NSAttributedStringKey:Any] = [
  .font: CTFont.lightItalic,
  .paragraphStyle: paragraphStyleCentered
]

private let italicAttributesCentered: [NSAttributedStringKey:Any] = [
  .font: CTFont.italic,
  .paragraphStyle: paragraphStyleCentered
]

private let mediumItalicAttributesCentered: [NSAttributedStringKey:Any] = [
  .font: CTFont.mediumItalic,
  .paragraphStyle: paragraphStyleCentered
]

private let boldItalicAttributesCentered: [NSAttributedStringKey:Any] = [
  .font: CTFont.boldItalic,
  .paragraphStyle: paragraphStyleCentered
]

private let blackItalicAttributesCentered: [NSAttributedStringKey:Any] = [
  .font: CTFont.blackItalic,
  .paragraphStyle: paragraphStyleCentered
]

public enum FontStyle {

  case halfLine

  case thin, extraLight, light, regular, medium, bold, black
  case thinItalic, extraLightItalic, lightItalic, italic, mediumItalic, boldItalic, blackItalic

  case thinCentered, extraLightCentered, lightCentered, regularCentered, mediumCentered,
       boldCentered, blackCentered
  case thinItalicCentered, extraLightItalicCentered, lightItalicCentered, italicCentered,
       mediumItalicCentered, boldItalicCentered, blackItalicCentered

  public var attributes: [NSAttributedStringKey:Any] {

    switch self {

      case .halfLine:                 return halfLineAttributes
      case .thin:                     return thinAttributes
      case .extraLight:               return extraLightAttributes
      case .light:                    return lightAttributes
      case .regular:                  return regularAttributes
      case .medium:                   return mediumAttributes
      case .bold:                     return boldAttributes
      case .black:                    return blackAttributes
      case .thinItalic:               return thinItalicAttributes
      case .extraLightItalic:         return extraLightItalicAttributes
      case .lightItalic:              return lightItalicAttributes
      case .italic:                   return italicAttributes
      case .mediumItalic:             return mediumItalicAttributes
      case .boldItalic:               return boldItalicAttributes
      case .blackItalic:              return blackItalicAttributes
      case .thinCentered:             return thinAttributesCentered
      case .extraLightCentered:       return extraLightAttributesCentered
      case .lightCentered:            return lightAttributesCentered
      case .regularCentered:          return regularAttributesCentered
      case .mediumCentered:           return mediumAttributesCentered
      case .boldCentered:             return boldAttributesCentered
      case .blackCentered:            return blackAttributesCentered
      case .thinItalicCentered:       return thinItalicAttributesCentered
      case .extraLightItalicCentered: return extraLightItalicAttributesCentered
      case .lightItalicCentered:      return lightItalicAttributesCentered
      case .italicCentered:           return italicAttributesCentered
      case .mediumItalicCentered:     return mediumItalicAttributesCentered
      case .boldItalicCentered:       return boldItalicAttributesCentered
      case .blackItalicCentered:      return blackItalicAttributesCentered

    }

  }

}

/// Extension of attributed strings with `FontStyle` related functionality.
extension NSAttributedString {

  public convenience init(string: String, style: FontStyle) {
    self.init(string: string, attributes: style.attributes)
  }

}

/// Extension of mutable attributed strings with `FontStyle` related functionality.
extension NSMutableAttributedString {

  public func append(_ string: String, style: FontStyle) {
    append(NSAttributedString(string: string, attributes: style.attributes))
  }

  public static func +=(lhs: NSMutableAttributedString, rhs: (String, FontStyle)) {
    lhs.append(NSAttributedString(string: rhs.0, attributes: rhs.1.attributes))
  }

}
