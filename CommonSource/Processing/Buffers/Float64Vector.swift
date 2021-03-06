//
//  Float64Vector.swift
//  Chord Finder
//
//  Created by Jason Cardwell on 8/26/17.
//  Copyright (c) 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import Accelerate
import AVFoundation

public protocol Float64Vector: class, CustomReflectable, CustomStringConvertible {

  /// Storage for the `Float64` values.
  var storage: Float64Buffer { get }

  /// The number of `Float64` values in `storage`.
  var count: Int { get }

  /// Whether the vector is responsible for the memory allocated for `storage`.
  var ownsMemory: Bool { get }

  /// Initializing with the vector size.
  init(count: Int)

  /// Initialize with existing storage.
  init(storage: Float64Buffer, count: Int, assumeOwnership: Bool)

}

/// A protocol for types that conform to `Float64Vector` and always have the same size.
public protocol ConstantSizeFloat64Vector: Float64Vector {

  /// The number of `Float64` values in `storage`.
  static var count: Int { get }

  /// Initializer for a vector of zeros.
  init()

  /// Initialize with existing storage.
  init(storage: Float64Buffer, assumeOwnership: Bool)

}

infix operator • : MultiplicationPrecedence
infix operator ~
prefix operator ∑

// Extending `Float64Vector` with some basic Collection protocol support and some common behaviour.
extension Float64Vector {

  public var startIndex: Int { return 0 }
  public var endIndex: Int { return count }
  public func index(after i: Int) -> Int { return i &+ 1 }

  /// Initializing with an array of values for filling the vector.
  ///
  /// - Parameter values: The array of values. This must have at least `Self.count` elements.
  public init(values: [Float64]) {
    self.init(count: values.count)
    cblas_dcopy(Int32(values.count), values, 1, storage, 1)
  }

  /// Initializing from an existing vector.
  ///
  /// - Parameter vector: The vector with values to copy into the new vector.
  public init(_ vector: Self) {
    self.init(count: vector.count)
    let countu = vDSP_Length(vector.count)
    vDSP_mmovD(vector.storage, storage, countu, 1, countu, countu)
  }

  /// Initializing from an existing buffer.
  ///
  /// - Parameters:
  ///   - buffer: The values to copy.
  ///   - count: The total number of values.
//  public init(storage buffer: Float64Buffer, count: Int, assumeOwnership: Bool) {
//    self.init(count: count)
//    let countu = vDSP_Length(count)
//    vDSP_mmovD(buffer, storage, countu, 1, countu, countu)
//  }

  /// Accessors for the `Self.count` `Float64` values.
  ///
  /// - Parameter position: An index into the vector.
  public subscript(position: Int) -> Float64 {
    get { return (storage + position).pointee }
    set { (storage + position).initialize(to: newValue) }
  }

  public var customMirror: Mirror {
    return Array(UnsafeBufferPointer(start: storage, count: count)).customMirror
  }

  public var description: String {
    return "(\((0..<count).map({String(format: "%8.6lf", storage[$0])}).joined(separator: ", ")))"
  }

  /// Adds two vectors to generate a new vector.
  ///
  /// - Parameters:
  ///   - lhs: The first vector to be added.
  ///   - rhs: The second vector to be added.
  /// - Returns: The result of adding `lhs` and `rhs` together.
  public static func +(lhs: Self, rhs: Self) -> Self {
    assert(lhs.count == rhs.count, "`lhs` and `rhs` must have the same number of values.")
    let count = lhs.count
    let result = Self(count: count)
    vDSP_vaddD(lhs.storage, 1, rhs.storage, 1, result.storage, 1, vDSP_Length(count))
    return result
  }

  /// Adds two vectors overwriting the first vector with the result.
  ///
  /// - Parameters:
  ///   - lhs: The first vector to be added and to which the result will be written.
  ///   - rhs: The second vector to be added.
  public static func +=(lhs: inout Self, rhs: Self) {
    assert(lhs.count == rhs.count, "`lhs` and `rhs` must have the same number of values.")
    let count = vDSP_Length(lhs.count)
    vDSP_vaddD(lhs.storage, 1, rhs.storage, 1, lhs.storage, 1, count)
  }

  /// Subtracts one vector from another to generate a new vector.
  ///
  /// - Parameters:
  ///   - lhs: The vector from which to subtract `rhs`.
  ///   - rhs: The vector to subtract from `lhs`.
  /// - Returns: The result of subtracting `rhs` from `lhs`.
  public static func -(lhs: Self, rhs: Self) -> Self {
    assert(lhs.count == rhs.count, "`lhs` and `rhs` must have the same number of values.")
    let count = lhs.count
    let result = Self(count: count)
    vDSP_vsubD(lhs.storage, 1, rhs.storage, 1, result.storage, 1, vDSP_Length(count))
    return result
  }

  /// Modifies a vector by subtracting another vector.
  ///
  /// - Parameters:
  ///   - lhs: The vector from which to subtract `rhs`. It's values will be overwritten with result.
  ///   - rhs: The vector to subtract from `lhs`.
  public static func -=(lhs: inout Self, rhs: Self) {
    assert(lhs.count == rhs.count, "`lhs` and `rhs` must have the same number of values.")
    let count = vDSP_Length(lhs.count)
    vDSP_vsubD(lhs.storage, 1, rhs.storage, 1, lhs.storage, 1, count)
  }

  /// Calculates the inner product for the specified vectors.
  ///
  /// - Parameters:
  ///   - lhs: The first operand.
  ///   - rhs: The second operand.
  /// - Returns: The inner product of `lhs` and `rhs`.
  public static func •(lhs: Self, rhs: Self) -> Float64 {
    assert(lhs.count == rhs.count, "`lhs` and `rhs` must have the same number of values.")
    let count = vDSP_Length(lhs.count)
    var result = 0.0
    vDSP_dotprD(lhs.storage, 1, rhs.storage, 1, &result, count)
    return result
  }

  /// Calculates the sum of the elements of the specified vector.
  ///
  /// - Parameter value: The vector to sum.
  /// - Returns: The sum of all the elements in `value`.
  public static prefix func ∑(value: Self) -> Float64 {
    var result = 0.0
    vDSP_sveD(value.storage, 1, &result, vDSP_Length(value.count))
    return result
  }

  /// The similarity score for two vectors calculated by dividing the inner product for the
  /// vectors by the sum of their norms.
  ///
  /// - Parameters:
  ///   - lhs: The first operand.
  ///   - rhs: The second operand.
  /// - Returns: A scalar value that constitutes the similarity score for the two vectors.
  public static func ~(lhs: Self, rhs: Self) -> Float64 {
    assert(lhs.count == rhs.count, "`lhs` and `rhs` must have the same number of values.")
    let count = Int32(lhs.count)
    let numerator = lhs • rhs
    let lhsNorm = cblas_dnrm2(count, lhs.storage, 1)
    let rhsNorm = cblas_dnrm2(count, rhs.storage, 1)
    let denominator = lhsNorm + rhsNorm
    return numerator / denominator
  }

  public var indicesByValue: [Int] {

    var indices: [UInt] = Array(0..<UInt(count))

    vDSP_vsortiD(storage, &indices, nil, vDSP_Length(count), -1)

    return indices.map({Int($0)})

  }

  public func indices(ordered: ComparisonResult, threshold: Float64) -> [Int] {

    var indices = indicesByValue

    switch ordered {

      case .orderedAscending:
        indices.reverse()
        if let dropIndex = indices.firstIndex(where: {storage[$0] > threshold}) {
          indices.removeSubrange(dropIndex..<indices.endIndex)
        }

      default:
        if let dropIndex = indices.firstIndex(where: {storage[$0] < threshold}) {
          indices.removeSubrange(dropIndex..<indices.endIndex)
        }

    }

    return indices

  }

  /// Determines whether two vectors are equal by testing equality of all elements in the vectors.
  ///
  /// - Parameters:
  ///   - lhs: The first of the two vectors to compare.
  ///   - rhs: The second of the two vectors to compare.
  /// - Returns: `true` if all values in `lhs` are equal to their counterpart in `rhs`.
  public static func ==(lhs: Self, rhs: Self) -> Bool {

    guard lhs.count == rhs.count else { return false }

    for index in 0 ..< lhs.count {

      guard lhs.storage[index] == rhs.storage[index] else { return false }

    }

    return true

  }

}

extension ConstantSizeFloat64Vector {

  public var count: Int { return Self.count }
  
  public init(count: Int) {
    self.init()
  }

  public init(storage: Float64Buffer, count: Int, assumeOwnership: Bool) {
    self.init(storage: storage, assumeOwnership: assumeOwnership)
  }

}

/// A structure for representing a vector of 128 `Float64` values with indices that correspond
/// to the 128 pitch values.
public final class PitchVector: Collection, ConstantSizeFloat64Vector, Equatable {

  public typealias Element = Float64

  public static let count = 128

  public let count = 128

  private typealias BinCount = Int
  private typealias WindowLength = Int

  /// A private cache of bin-to-pitch indexes.
  private static var binMaps: [SampleRate: [BinCount: [WindowLength: [Pitch]]]] = [:]

  /// Retrieves the pitch index for the specified parameters from the cache, creating it
  /// if it does not exist.
  ///
  /// - Parameters:
  ///   - binCount: The total number of bins.
  ///   - windowLength: The length of the window used to calculate the bins.
  ///   - sampleRate: The sample rate associated with the bins.
  /// - Returns: The cached or created pitch index.
  private static func pitchIndex(binCount: Int,
                                 windowLength: Int,
                                 sampleRate: SampleRate) -> [Pitch]
  {

    if let map = binMaps[sampleRate]?[binCount]?[windowLength] { return map }

    let map = binMap(windowLength: windowLength, sampleRate: sampleRate)

    if binMaps[sampleRate] == nil { binMaps[sampleRate] = [:] }

    if binMaps[sampleRate]![binCount] == nil { binMaps[sampleRate]![binCount] = [:] }

    binMaps[sampleRate]![binCount]![windowLength] = map

    return map

  }

  /// Storage for the `Float64` values.
  public let storage: Float64Buffer

  public let ownsMemory: Bool

  deinit {
    if ownsMemory { storage.deallocate() }
  }

  /// Initialize an all-zero vector.
  public init() {

    ownsMemory = true
    storage = Float64Buffer.allocate(capacity: 128)
    vDSP_vclrD(storage, 1, 128)

  }

  /// Initializing with a buffer of values for filling the vector.
  ///
  /// - Parameters:
  ///   - storage: The buffer of values to use. This must have at least 128 elements.
  ///   - assumeOwnership: Whether the vector should be responsible for the allocated memory.
  public init(storage: Float64Buffer, assumeOwnership: Bool) {
    self.storage = storage
    ownsMemory = assumeOwnership
  }

  /// Initializing from an FFT calculation.
  ///
  /// - Parameters:
  ///   - fft: The FFT bins to redistribute into pitch energies.
  ///   - windowLength: The length of the window used to calculate `bins`.
  ///   - sampleRate: The sample rate of the signal.
  public convenience init(bins: BinVector, windowLength: Int, sampleRate: SampleRate) {

    self.init()

    // Fetch the index for bin-to-pitch conversion.
    let pitchIndex = PitchVector.pitchIndex(binCount: bins.count,
                                            windowLength: windowLength,
                                            sampleRate: sampleRate)

    // Iterate the enumerated `pitchIndex` to generate bin-pitch pairs.
    for (bin, pitch) in pitchIndex.enumerated() {

      // Check that the bin is not before the first representable MIDI pitch.
      guard pitch >= 0 else { continue }

      // Check that the pitch value is still within the acceptable range.
      guard pitch <= 127 else { break }

      // Add the bin's value to the pitch vector.
      self[pitch] += bins[bin]

    }

  }


  /// Accessors for the 128 `Float` values.
  ///
  /// - Parameter pitch: The pitch to use as an index into the vector.
  public subscript(pitch: Pitch) -> Float64 {
    get { return (storage + pitch.rawValue).pointee }
    set { (storage + pitch.rawValue).initialize(to: newValue) }
  }

  /// Accessor for a subsequence that takes a countable range of pitches.
  ///
  /// - Parameter bounds: The pitches to include in the slice.
  public subscript(bounds: CountableRange<Pitch>) -> Slice<PitchVector> {
    return self[bounds.lowerBound.rawValue..<bounds.upperBound.rawValue]
  }

  /// Accessor for a subsequence that takes a countable closed range of pitches.
  ///
  /// - Parameter bounds: The pitches to include in the slice.
  public subscript(bounds: CountableClosedRange<Pitch>) -> Slice<PitchVector> {
    return self[bounds.lowerBound.rawValue...bounds.upperBound.rawValue]
  }

  public var pitchesByValue: [Pitch] {
    return indicesByValue.map({Pitch(rawValue: $0)})
  }

  public func pitches(ordered: ComparisonResult, threshold: Float64) -> [Pitch] {
    return indices(ordered: ordered, threshold: threshold).map(Pitch.init(rawValue:))
  }

}

/// Generates a mapping from an FFT bin to the raw value of its corresponding pitch.
///
/// - Parameters:
///   - windowLength: The length of the window used in FFT calculations.
///   - sampleRate: The sample rate of the signal being processed.
/// - Returns: An array holding raw pitch values for each bin.
private func binMap(windowLength: Int, sampleRate: SampleRate) -> [Pitch] {

  // Get the sample rate as a float value.
  let sampleRate = Float(sampleRate.rawValue)

  // Calculate the number of bins as half the window length.
  let count = windowLength / 2 + 1

  let binIndices = FloatBuffer.allocate(capacity: count)

  // Get the count as an Accelerate friendly type.
  let countu = vDSP_Length(count)

  // Fill the vector with elements `0` through `count - 1`.
  var zero: Float = 0
  var one: Float = 1
  vDSP_vramp(&zero, &one, binIndices, 1, countu)

  // Multiply the `k` values by `sampleRate` divided by `440 * windowLength`.
  var multiplier = exp2(66 - log2(Float(windowLength))) * (sampleRate/55)
  vDSP_vsmul(binIndices, 1, &multiplier, binIndices, 1, countu)

  // Take the base 2 log of the values.
  var count32 = Int32(count)
  vvlog2f(binIndices, binIndices, &count32)

  // Multiply the values by `12`.
  var twelve: Float = 12
  vDSP_vsmul(binIndices, 1, &twelve, binIndices, 1, countu)


  // Subtract one or two to correct for an undiagnosed error.
  switch 1 << Int(log2(Float(windowLength))) == windowLength {

    case true:

      var two: Float = 2
      two.negate()
      vDSP_vsadd(binIndices, 1, &two, binIndices, 1, countu)

    case false:

      one.negate()
      vDSP_vsadd(binIndices, 1, &one, binIndices, 1, countu)

  }



  // Allocate memory for converting to `Int`.
  let pitches8 = UnsafeMutablePointer<Int8>.allocate(capacity: count)
  vDSP_vfix8(binIndices, 1, pitches8, 1, countu)

  let pitches = UnsafeMutablePointer<Pitch>.allocate(capacity: count)

  // Initialize `pitches` by converting each value in `binIndices`.
  for index in 0 ..< count {

    (pitches + index).initialize(to: Pitch(rawValue: Int(pitches8[index])))

  }

  // Deallocate memory.
  binIndices.deallocate()
  pitches8.deallocate()

  // Fix the first value if the second is less than 0.
  if pitches[1] < 0 { pitches[0] = Pitch(rawValue: Int.min) }

  let array = Array(UnsafeBufferPointer(start: pitches, count: count))

  pitches.deallocate()

  return array

}

/// A structure for representing a vector of 12 `Float64` values with indices that correspond
/// to the 12 chroma values.
public final class ChromaVector: Collection, ConstantSizeFloat64Vector, Equatable {

  public typealias Element = Float64

  public static let count = 12

  public let count = 12

  /// Storage for the `Float64` values.
  public let storage: Float64Buffer

  public let ownsMemory: Bool

  deinit {
    if ownsMemory { storage.deallocate() }
  }

  /// Initialize an all-zero vector.
  public init() {

    ownsMemory = true
    storage = Float64Buffer.allocate(capacity: 12)
    vDSP_vclrD(storage, 1, 12)

  }

  /// Initializing with a buffer of values for filling the vector.
  ///
  /// - Parameter storage: The buffer of values to use. This must have at least 12 elements.
  public init(storage: Float64Buffer, assumeOwnership: Bool) {
    self.storage = storage
    ownsMemory = assumeOwnership
  }

  /// Accessors for the 12 `Float` values.
  ///
  /// - Parameter chroma: The chroma to use as an index into the vector.
  public subscript(chroma: Chroma) -> Float64 {
    get { return (storage + chroma.rawValue).pointee }
    set { (storage + chroma.rawValue).initialize(to: newValue) }
  }

  public var chromasByValue: [Chroma] {
    return indicesByValue.map({Chroma(rawValue: $0)})
  }

  public func chromas(ordered: ComparisonResult, threshold: Float64) -> [Chroma] {
    return indices(ordered: ordered, threshold: threshold).map(Chroma.init(rawValue:))
  }

}

/// A structure for representing the bins for an FFT calculation.
public final class BinVector: Collection, Float64Vector, Equatable {

  public typealias Element = Float64

  public let count: Int

  /// Storage for the `Float64` values.
  public let storage: Float64Buffer

  public let ownsMemory: Bool

  deinit {
    if ownsMemory { storage.deallocate() }
  }

  /// Initialize an all-zero vector.
  public init(count: Int) {

    ownsMemory = true
    self.count = count
    storage = Float64Buffer.allocate(capacity: count)
    vDSP_vclrD(storage, 1, vDSP_Length(count))

  }

  /// Initializing with a buffer of values for filling the vector.
  ///
  /// - Parameters:
  ///   - storage: The buffer of values to use.
  ///   - count: The number of values in `storage`.
  ///   - assumeOwnership: Whether the vector should be responsible for the allocated memory.
  public init(storage: Float64Buffer, count: Int, assumeOwnership: Bool) {
    self.storage = storage
    self.count = count
    ownsMemory = assumeOwnership
  }

  /// Initializing by copying the contents of an array.
  ///
  /// - Parameter array: The array with values to copy.
  public convenience init(array: [Float64]) {
    self.init(count: array.count)
    let countu = vDSP_Length(array.count)
    vDSP_mmovD(array, storage, countu, 1, countu, countu)
  }

  /// Returns the frequency for a bin given a sample rate and window size.
  ///
  /// - Parameters:
  ///   - bin: The bin for which a frequency is desired.
  ///   - sampleRate: The sample rate corresponding to the FFT calculation.
  ///   - windowSize: The window size used for the FFT calculation.
  /// - Returns: The frequency associated with the start of `bin`.
  public func frequency(for bin: Int,
                        sampleRate: SampleRate,
                        windowSize: Int) -> Frequency
  {
    return Frequency(rawValue: (Float64(bin) * Float64(sampleRate.rawValue)) / Float64(windowSize))
  }

  public var detailedDescription: String {

    var result = "{\n"

    for (bin, value) in enumerated() {

      result += "  \(String(format: "% 5li", bin)):  \(value)\n"

    }

    result += "}"

    return result

  }

}

/// A structure for holding the values of a signal.
public final class SignalVector: Collection, Float64Vector, Equatable {

  public typealias Element = Float64

  public let count: Int

  /// Storage for the `Float64` values.
  public let storage: Float64Buffer

  /// Flag indicating whether the signal vector is responsible for freeing allocated memory.
  public let ownsMemory: Bool

  deinit {
    if ownsMemory { storage.deallocate() }
  }

  /// Initialize an all-zero vector.
  public init(count: Int) {

    self.count = count
    storage = Float64Buffer.allocate(capacity: count)
    ownsMemory = true
    vDSP_vclrD(storage, 1, vDSP_Length(count))

  }

  /// Initialize by copying the specified storage.
  ///
  /// - Parameters:
  ///   - buffer: A pointer to the contiguous memory location for the values to copy.
  ///   - count: The number of values to copy from `storage`.
  ///   - capacity: Optionally, specifies the total number of values for which to allocate
  ///               memory in the vector.
  public convenience init(copying buffer: Float64Buffer, count: Int, capacity: Int? = nil) {

    self.init(count: capacity ?? count)

    let countu = vDSP_Length(count)
    vDSP_mmovD(buffer, storage, countu, 1, countu, countu)

  }

  /// Initializing with a buffer of values for filling the vector.
  ///
  /// - Parameters:
  ///   - storage: The buffer of values to use.
  ///   - count: The number of values in `storage`.
  ///   - assumeOwnership: Whether to assume ownership of the memory allocated for `storage`.
  public init(storage: Float64Buffer, count: Int, assumeOwnership: Bool) {
    self.storage = storage
    self.count = count
    ownsMemory = assumeOwnership
  }

  /// Initializing with an array to wrap.
  ///
  /// - Parameter array: The array to wrap, allowing access to the array's storage via `storage`.
  public init(array: inout [Float64]) {
    storage = array.withUnsafeMutableBufferPointer { $0.baseAddress! }
    count = array.count
    ownsMemory = false
  }

  /// Initializing with the contents of an audio buffer.
  ///
  /// - Parameter buffer: The buffer with the content to use.
  public convenience init(buffer: AVAudioPCMBuffer, copy: Bool = false) {

    guard let channelData = buffer.float64ChannelData?.pointee else {
      fatalError("Buffer contains invalid channel data.")
    }

    let count = Int(buffer.frameLength)

    if copy {
      self.init(count: count)
      let countu = vDSP_Length(count)
      vDSP_mmovD(channelData, storage, countu, 1, countu, countu)
    } else {
      self.init(storage: channelData, count: count, assumeOwnership: false)
    }

  }

}
