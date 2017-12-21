//
//  CollectionSubranges.swift
//  SignalProcessing
//
//  Created by Jason Cardwell on 12/20/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation

extension Collection where Self.Index == Int, Self.IndexDistance == Int {

  /// Generates a subrange suitable for slicing using the provided start index and length.
  ///
  /// - Parameters:
  ///   - start: The lower bound for the range
  ///   - length: The amount to offset `start`.
  /// - Returns: The range formed from `start ..< (start + length)`.
  public func subrange(start: Index, length: Int) -> CountableRange<Index> {
    let end = index(start, offsetBy: length)
    return start ..< end
  }

  /// Generates a subrange suitable for slicing using the provided start index and length.
  ///
  /// - Parameters:
  ///   - offset: The offset from `startIndex` for the lower bound of the range
  ///   - length: The amount to add to `offset` for the upper bound of the range.
  /// - Returns: The range formed from `(startIndex + offset) ..< (startIndex + offset + length)`.
  public func subrange(offset: Int, length: Int) -> CountableRange<Index> {
    let start = index(startIndex, offsetBy: offset)
    let end = index(start, offsetBy: length)
    return start ..< end
  }

  /// Generates a partial range from the specified offset to the collection's `endIndex`.
  ///
  /// - Parameter offset: The offset from `startIndex` to use as the range's lower bound.
  /// - Returns: The range formed from `(startIndex + offset)...`.
  public func subrange(fromOffset offset: Int) -> CountablePartialRangeFrom<Index> {
    let start = index(startIndex, offsetBy: offset)
    return start...
  }

}
