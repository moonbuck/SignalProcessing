//
//  Bytes.swift
//  MoonKit
//
//  Created by Jason Cardwell on 11/8/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//
import Foundation

public protocol ByteArrayConvertible: Equatable, Coding, DataConvertible {
  var bytes: [Byte] { get }
  init(_ bytes: [Byte])
  init<S:Sequence>(_ bytes: S) where S.Iterator.Element == Byte
}

public extension ByteArrayConvertible {
  var data: Data {
    let bytes = self.bytes
    return Data(bytes: UnsafePointer<UInt8>(bytes), count: bytes.count)
  }

  init?(data: Data) {
    self.init(data)
  }

  init?(coder: NSCoder) {
    guard let bytes = coder.decodeData() else { return nil }
    self.init(bytes)
  }

  func encodeWithCoder(_ coder: NSCoder) {
    let bytes = Data(bytes: self.bytes)
    coder.encode(bytes)
  }

}


public func ==<B:ByteArrayConvertible>(lhs: B, rhs: B) -> Bool {
  let leftBytes = lhs.bytes, rightBytes = rhs.bytes
  guard leftBytes.count == rightBytes.count else { return false }
  for (leftByte, rightByte) in zip(leftBytes, rightBytes) {
    guard leftByte  == rightByte else { return false }
  }
  return true
}

extension ByteArrayConvertible {
  public init<S:Sequence>(_ bytes: S) where S.Iterator.Element == Byte {
    self.init(Array(bytes))
  }
}

fileprivate func _bytes<T>(_ value: T) -> [Byte] {
  var value = value
  return withUnsafeBytes(of: &value) { Array($0.reversed()) }
}

extension UInt: ByteArrayConvertible {
  public var bytes: [Byte] { return _bytes(self) }
  public init(_ bytes: [Byte]) {
    self = MemoryLayout<UInt>.size == 8 ? UInt(UInt64(bytes)) : UInt(UInt32(bytes))
  }
}

extension Int: ByteArrayConvertible {
  public var bytes: [Byte] { return _bytes(self) }
  public init<S:Sequence>(_ bytes: S) where S.Iterator.Element == Byte { self = Int(UInt(bytes)) }
}


extension UInt8: ByteArrayConvertible {
  public var bytes: [Byte] { return _bytes(self) }
  public init(_ bytes: [Byte]) {
    guard let byte = bytes.first else { self = 0; return }
    self = byte
  }
}
extension Int8: ByteArrayConvertible {
  public var bytes: [Byte] { return _bytes(self) }
  public init(_ bytes: [Byte]) { self = Int8(UInt8(bytes)) }
}

extension UInt16: ByteArrayConvertible {
  public var bytes: [Byte] { return _bytes(self) }
  public init(_ bytes: [Byte]) {
    let count = bytes.count
    guard count < 3 else { self = UInt16(bytes[count - 2 ..< count]); return }
    switch bytes.count {
    case 2:
      self = UInt16(bytes[0]) << 8 | UInt16(bytes[1])
    case 1:
      self = UInt16(bytes[0])
    default:
      self = 0
    }
  }
}

extension Int16: ByteArrayConvertible {
  public var bytes: [Byte] { return _bytes(self) }
  public init(_ bytes: [Byte]) { self = Int16(UInt16(bytes)) }
}

extension UInt32: ByteArrayConvertible {
  public var bytes: [Byte] { return _bytes(self) }
  public init(_ bytes: [Byte]) {
    let count = bytes.count
    guard count > 2 else { self = UInt32(UInt16(bytes)); return }
    self = UInt32(UInt16(bytes[0 ..< count - 2])) << 16 | UInt32(UInt32(bytes[count - 2 ..< count]))
  }
}

extension Int32: ByteArrayConvertible {
  public var bytes: [Byte] { return _bytes(self) }
  public init(_ bytes: [Byte]) { self = Int32(UInt32(bytes)) }
}

extension UInt64: ByteArrayConvertible {
  public var bytes: [Byte] {return _bytes(self) }
  public init(_ bytes: [Byte]) {
    let count = bytes.count
    guard count > 4 else { self = UInt64(UInt32(bytes)); return }
    self = UInt64(UInt32(bytes[0 ..< count - 4])) << 32 | UInt64(UInt32(bytes[count - 4 ..< count]))
  }
}

extension Int64: ByteArrayConvertible {
  public var bytes: [Byte] { return _bytes(self) }
  public init(_ bytes: [Byte]) { self = Int64(UInt64(bytes)) }
}

extension String: ByteArrayConvertible {

  public var bytes: [Byte] {

    return Array(utf8)

  }

  public init<S:Sequence>(_ bytes: S) where S.Iterator.Element == Byte {
    self.init(Array(bytes))
  }

  public init(_ bytes: [Byte]) {
    let endIndex = bytes.index(of: 0) ?? bytes.endIndex
    let scalars = String.UnicodeScalarView(bytes[..<endIndex].map(UnicodeScalar.init))
    self = String(scalars)
  }

}
