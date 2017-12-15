//
//  SequenceManipulation.swift
//  generate_midi_chords
//
//  Created by Jason Cardwell on 12/7/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation

public enum SegmentOptions<PadType> {
  case padFirstGroup(PadType)
  case padLastGroup(PadType)
  case unpaddedFirstGroup
  case unpaddedLastGroup
}

public extension Sequence {

  /**
   bisect:

   - parameter predicate: (Self.Generator.Element) throws -> Bool
  */
  public func bisect(predicate: (Self.Iterator.Element) throws -> Bool) rethrows -> ([Self.Iterator.Element], [Self.Iterator.Element]) {
    var group1: [Self.Iterator.Element] = [], group2: [Self.Iterator.Element] = []
    for element in self { if try predicate(element) { group1.append(element) } else { group2.append(element) } }
    return (group1, group2)
  }


  /**
  segment:options:

  - parameter segmentSize: Int = 2
  - parameter options: SegmentOptions<Generator.Element> = .Default

  - returns: [[Generator.Element]]
  */
  public func segment(_ segmentSize: Int = 2, options: SegmentOptions<Iterator.Element> = .unpaddedLastGroup) -> [[Iterator.Element]] {
    var result: [[Iterator.Element]] = []
    var array: [Iterator.Element] = []
    let segmentSize = segmentSize > 1 ? segmentSize : 1

    switch options {
      case .unpaddedLastGroup:
        for element in self {
          if array.count == segmentSize { result.append(array); array = [] }
          array.append(element)
        }
        result.append(array)

      case .padLastGroup(let p):
        for element in self {
          if array.count == segmentSize { result.append(array); array = [] }
          array.append(element)
        }
        while array.count < segmentSize { array.append(p) }
        result.append(array)

      case .unpaddedFirstGroup:
        for element in reversed() {
          if array.count == segmentSize { result.insert(array, at: 0); array = [] }
          array.insert(element, at: 0)
        }
        result.insert(array, at: 0)

      case .padFirstGroup(let p):
        for element in self {
          if array.count == segmentSize { result.insert(array, at: 0); array = [] }
          array.insert(element, at: 0)
        }
        while array.count < segmentSize { array.insert(p, at: 0) }
        result.insert(array, at: 0)

    }

    return result
  }

}
