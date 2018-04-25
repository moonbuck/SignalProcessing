//
//  Buffers.swift
//  Chord Finder
//
//  Created by Jason Cardwell on 7/22/17.
//  Copyright (c) 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import Accelerate

public typealias FloatBuffer = UnsafeMutablePointer<Float>
public typealias FloatBuffer2D = UnsafeMutablePointer<UnsafeMutablePointer<Float>>

public typealias Float64Buffer = UnsafeMutablePointer<Float64>
public typealias Float64Buffer2D = UnsafeMutablePointer<UnsafeMutablePointer<Float64>>


extension UnsafeMutablePointer where Pointee == Float64 {

  /// Initializes a row-major contiguous buffer using values from a 2D array. The longest
  /// row in `array` determines the number of columns and rows are zero-padded as needed.
  ///
  /// - Parameter array: The 2D array of values to copy.
  public init(_ array: [[Float64]]) {

    let rowCount = array.count

    guard let columnCount = array.max(by: {$0.count < $1.count})?.count else {
      self = Float64Buffer.allocate(capacity: 0)
      return
    }

    let count = rowCount * columnCount

    let buffer = Float64Buffer.allocate(capacity: count)

    vDSP_vclrD(buffer, 1, vDSP_Length(count))

    for row in array.indices {

      let availableColumns = vDSP_Length(array[row].count)

      vDSP_mmovD(array[row],
                 buffer + (row * columnCount),
                 availableColumns,
                 1,
                 availableColumns,
                 availableColumns)

      let pad = columnCount - Int(availableColumns)
      if pad > 0 {
        (buffer + (row * columnCount + Int(availableColumns))).initialize(repeating: 0, count: pad)
      }
    }

    self = buffer

  }

  /// Initializes a row-major contiguous buffer using values from a 2D row-major buffer.
  ///
  /// - Parameters:
  ///   - buffer2D: The 2D buffer of values to copy.
  ///   - rowCount: The number of rows in `buffer2D`.
  ///   - columnCount: The number of columns in each row of `buffer2D`.
  public init(_ buffer2D: Float64Buffer2D, rowCount: Int, columnCount: Int) {

    let count = rowCount * columnCount

    let buffer = Float64Buffer.allocate(capacity: count)

    for row in 0 ..< rowCount {

      let columnCountʹ = vDSP_Length(columnCount)

      vDSP_mmovD(buffer2D[row],
                 buffer + (row * columnCount),
                 columnCountʹ,
                 1,
                 columnCountʹ,
                 columnCountʹ)

    }
    
    self = buffer
    
  }
  
  /// Returns the row-major buffer converted into a 2D array.
  ///
  /// - Parameters:
  ///   - rowCount: The number of rows in the buffer.
  ///   - columnCount: The number of columns in the buffer.
  /// - Returns: A row-major-indexed 2D array containing the buffer's values.
  public func array(rowCount: Int, columnCount: Int) -> [[Float64]] {

    return (0 ..< rowCount).map {
      Array(UnsafeBufferPointer(start: self + ($0 * columnCount), count: columnCount))
    }

  }

  /// Returns the row-major buffer converted into a 2D buffer.
  ///
  /// - Parameters:
  ///   - rowCount: The number of rows in the buffer.
  ///   - columnCount: The number of columns in the buffer.
  /// - Returns: A row-major-indexed 2D buffer containing the buffer's values.
  public func buffer2D(rowCount: Int, columnCount: Int) -> Float64Buffer2D {

    let buffer2D = Float64Buffer2D.allocate(capacity: rowCount)
    let columnCountʹ = vDSP_Length(columnCount)
    for row in 0 ..< rowCount {
      let rowBuffer = Float64Buffer.allocate(capacity: columnCount)
      vDSP_mmovD(self + (row * columnCount),
                rowBuffer,
                columnCountʹ,
                1,
                columnCountʹ,
                columnCountʹ)
      (buffer2D + row).initialize(to: rowBuffer)
    }

    return buffer2D
    
  }

  /// Transposes a row-major buffer to column-major and vice-versa.
  ///
  /// - Parameters:
  ///   - rowCount: The number of rows as currently ordered.
  ///   - columnCount: The number of columns as currently ordered.
  public mutating func transpose(rowCount: Int, columnCount: Int, pad: Int = 0) {

    let totalCount = (rowCount + pad) * columnCount
    let selfʹ = Float64Buffer.allocate(capacity: totalCount)

    if pad == 0 {
      vDSP_mtransD(self, 1, selfʹ, 1, vDSP_Length(columnCount), vDSP_Length(rowCount))
    } else {
      vDSP_vclrD(selfʹ, 1, vDSP_Length(totalCount))
      for row in 0 ..< rowCount {
        for column in 0 ..< columnCount {
          let currentValue = self[row * columnCount + column]
          let transposedPointer = selfʹ + (column * (rowCount + pad) + row)
          transposedPointer.initialize(to: currentValue)
        }
      }
    }

    // Not sure if it is right to deallocate memory here.
    deallocate()
    self = selfʹ
  }

}

extension UnsafeMutablePointer where Pointee == UnsafeMutablePointer<Float64> {


  /// Allocates memory for a 2D buffer and initializes to `0`. Memory for the rows is
  /// assigned as one large contiguous chunk of memory. The `columnCount` values for
  /// the first pointer are followed immediately by `columnCount` values for the second
  /// pointer and so on…
  ///
  ///
  /// - Parameters:
  ///   - rowCount: The number of rows.
  ///   - columnCount: The number of columns per row.
  /// - Returns: The fully initialized 2D buffer.
  public static func allocate2D(rowCount: Int,
                                columnCount: Int) -> UnsafeMutablePointer
  {

    let buffer = UnsafeMutablePointer<Float64>.allocate(capacity: rowCount * columnCount)
    vDSP_vclrD(buffer, 1, vDSP_Length(rowCount * columnCount))

    let result = allocate(capacity: rowCount)

    for i in 0 ..< rowCount {

      (result + i).initialize(to: buffer + (i * columnCount))

    }

    return result

  }

  /// Initializes a row-major indexed 2D buffer with the values of the specified array.
  ///
  ///
  /// - Parameters:
  ///   - array: The 2D array with values to copy into the intialized 2D buffer.
  ///   - pad: The number of `0`s to append to each row. The default is `0`.
  public init(_ array: [[Float64]], pad: UInt = 0) {

    let buffer = Float64Buffer2D.allocate(capacity: array.count)

    let pad = Int(pad)

    for (i, row) in array.enumerated() {

      let c = vDSP_Length(row.count)
      let rowʹ = Float64Buffer.allocate(capacity: row.count + pad)
      vDSP_mmovD(row, rowʹ, c, 1, c, c)
      if pad > 0 { (rowʹ + row.count).initialize(repeating: 0, count: pad) }
      (buffer + i).initialize(to: rowʹ)
    }

    self = buffer

  }

  /// Returns the row-major indexed 2D buffer converted into a 2D array.
  ///
  /// - Parameters:
  ///   - rowCount: The number of rows in the buffer.
  ///   - columnCount: The number of columns in the buffer.
  /// - Returns: A row-major array containing the buffer's values.
  public func array(rowCount: Int, columnCount: Int) -> [[Float64]] {

    return Array(UnsafeBufferPointer(start: self, count: rowCount)).map {
      Array(UnsafeBufferPointer(start: $0, count: columnCount))
    }

  }

}

