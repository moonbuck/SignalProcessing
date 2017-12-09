//
//  AudioBuffers.swift
//  Chord Finder
//
//  Created by Jason Cardwell on 7/20/17.
//  Copyright (c) 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import AVFoundation
import Accelerate

/// Extending `AVAudioPCMBuffer` to more easily work with mono and/or 64 bit formats.
extension AVAudioPCMBuffer {

  /// Derived property for the buffer downmixed to mono.
  public var mono: AVAudioPCMBuffer {

    // Check that the buffer isn't already mono or just return it.
    guard format.channelCount > 1 else { return self }

    // Create a new format the same as the current format except for the number of channels.
    guard let newFormat = AVAudioFormat(commonFormat: format.commonFormat,
                                        sampleRate: format.sampleRate,
                                        channels: 1,
                                        interleaved: format.isInterleaved)
    else
    {
      fatalError("Failed to create single channel audio format.")
    }

    // Create a new audio converter.
    guard let audioConverter = AVAudioConverter(from: format, to: newFormat) else {
      fatalError("Failed to create audio converter.")
    }

    // Create a new buffer to hold the downmixed audio.
    guard let monoBuffer = AVAudioPCMBuffer(pcmFormat: newFormat,
                                            frameCapacity: frameCapacity)
      else
    {
      fatalError("Failed to create new buffer using mono format.")
    }

    // Create a flag for indicating whether the source buffer has been returned from the callback.
    var sourceBufferReturned = false

    // Create the callback that feeds input to the converter.
    let inputBlock: AVAudioConverterInputBlock = {
      [unowned self] in

      // Check whether the buffer's content has already been provided.
      guard !sourceBufferReturned else {
        $1.pointee = .endOfStream
        return nil
      }

      $1.pointee = .haveData
      sourceBufferReturned = true

      return self

    }

    // Create an error pointer.
    var error: NSError? = nil

    // Convert the buffer.
    let status = audioConverter.convert(to: monoBuffer, error: &error, withInputFrom: inputBlock)

    // Check thet status.
    switch status {

    case .haveData, .inputRanDry:
      // The mono buffer has data.

      return monoBuffer

    case .endOfStream, .error:
      // Conversion failed and/or target buffer has no data.

      fatalError("Conversion to single channel failed: \(error!)")

    }

  }

  /// Derived property for the buffer downmixed to mono and with 64 bit values.
  public var mono64: AVAudioPCMBuffer {

    // Check that the buffer isn't already mono or just return it.
    guard format.channelCount > 1 || format.commonFormat != .pcmFormatFloat64 else { return self }

    // Create a new format the same as the current format except for the number of channels.
    guard let newFormat = AVAudioFormat(commonFormat: .pcmFormatFloat64,
                                        sampleRate: format.sampleRate,
                                        channels: 1,
                                        interleaved: format.isInterleaved)
    else
    {
      fatalError("Failed to create single channel audio format.")
    }

    // Create a new audio converter.
    guard let audioConverter = AVAudioConverter(from: format, to: newFormat) else {
      fatalError("Failed to create audio converter.")
    }

    // Create a new buffer to hold the downmixed audio.
    guard let monoBuffer = AVAudioPCMBuffer(pcmFormat: newFormat,
                                            frameCapacity: frameCapacity)
      else
    {
      fatalError("Failed to create new buffer using mono format.")
    }

    // Create a flag for indicating whether the source buffer has been returned from the callback.
    var sourceBufferReturned = false

    // Create the callback that feeds input to the converter.
    let inputBlock: AVAudioConverterInputBlock = {
      [unowned self] in

      // Check whether the buffer's content has already been provided.
      guard !sourceBufferReturned else {
        $1.pointee = .endOfStream
        return nil
      }

      $1.pointee = .haveData
      sourceBufferReturned = true

      return self

    }

    // Create an error pointer.
    var error: NSError? = nil

    // Convert the buffer.
    let status = audioConverter.convert(to: monoBuffer, error: &error, withInputFrom: inputBlock)

    // Check thet status.
    switch status {

    case .haveData, .inputRanDry:
      // The mono buffer has data.

      return monoBuffer

    case .endOfStream, .error:
      // Conversion failed and/or target buffer has no data.

      fatalError("Conversion to single channel failed: \(error!)")

    }

  }

  /// Accessor for the underlying audio as 64 bit values or `nil` if buffer is not 64 bit.
  public var float64ChannelData: UnsafePointer<UnsafeMutablePointer<Float64>>? {

    guard case .pcmFormatFloat64 = format.commonFormat else { return nil }


    let underlyingBuffers = UnsafeMutableAudioBufferListPointer(mutableAudioBufferList)

    let channels = UnsafeMutablePointer<UnsafeMutablePointer<Float64>>.allocate(capacity: Int(format.channelCount))

    for (index, channelBuffer) in underlyingBuffers.enumerated() {

      guard let channelData = channelBuffer.mData else { return nil }

      let float64ChannelData = channelData.bindMemory(to: Float64.self, capacity: Int(frameCapacity))

      (channels + index).initialize(to: float64ChannelData)

    }

    return UnsafePointer(channels)

  }

  /// Initializing with the contents of an audio file.
  ///
  /// - Parameters:
  ///   - url: The url for the audio file to load.
  /// - Throws: Any error encountered reading the audio file into the new buffer.
  public convenience init(contentsOf url: URL) throws {

    // Get the audio file.
    let audioFile = try AVAudioFile(forReading: url)

    // Determine the necessary capacity for the PCM buffer.
    let capacity = AVAudioFrameCount(audioFile.length)

    // Create a PCM buffer with capacity for the contents of `audioFile`.
    self.init(pcmFormat: audioFile.processingFormat, frameCapacity: capacity)!

    // Read the audio file into the buffer.
    try audioFile.read(into: self)

  }

}

/// A single channel audio buffer with data sampled at 44100 Hz, 22050 Hz, 4410 Hz, and 882 Hz.
public struct MultirateAudioPCMBuffer {

  /// The duration of the buffer's audio content given in seconds.
  public var duration: Float { return Float(signals[44100]!.count) / 44100 }

  /// Storage for the audio signal at various sample rates.
  private let signals: [SampleRate:SignalVector]

  /// Initializing with the contents of an audio file.
  ///
  /// - Parameters:
  ///   - url: The url for the audio file to load.
  ///   - filters: An array of filters to be applied to the audio signal.
  /// - Throws: Any error encountered creating the `AVAudioPCMBuffer` or
  ///           `MultirateAudioPCMBuffer.Error.failureToCreateConverter` if conversion fails
  public init(contentsOf url: URL, filters: [SignalFilter] = []) throws {

    // Get the audio file.
    let audioFile = try AVAudioFile(forReading: url)

    // Determine the necessary capacity for the PCM buffer.
    let capacity = AVAudioFrameCount(audioFile.length)

    // Create a PCM buffer with capacity for the contents of `audioFile`.
    guard let audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat,
                                             frameCapacity: capacity)
    else
    {
      throw Error.invalidFile
    }

    // Read the audio file into the buffer.
    try audioFile.read(into: audioBuffer)

    // Initialize with the buffer.
    try self.init(buffer: audioBuffer, filters: filters)

  }

  /// Initialize from a single buffer which will be converted to single channel buffers
  /// with the necessary sample rates.
  ///
  /// - Parameters:
  ///   - buffer: The buffer from which the three buffers will be generated.
  ///   - filters: An array of filters to be applied to the audio signal.
  /// - Requires: `buffer` must have a sample rate equal to or greater than 44100 Hz.
  /// - Throws: `MultirateAudioPCMBuffer.Error.invalidSampleRate`
  public init(buffer: AVAudioPCMBuffer, filters: [SignalFilter] = []) throws {

    // Check whether `buffer` has a high enough sample rate.
    guard buffer.format.sampleRate >= 44100 else { throw Error.invalidSampleRate }

    // Obtain the buffer downmixed to mono and using 64 bit floating point values.
    let monoBuffer = buffer.mono64

    // Apply any supplied filters before multirate conversion.
    for filter in filters { filter.process(signal: monoBuffer) }

    // Convert `buffer` to create the four single-channel buffers.
    var signals: [SampleRate:SignalVector] = [:]
    signals[44100] = try convert(sourceBuffer: monoBuffer, to: 44100)
    signals[22050] = try convert(sourceBuffer: monoBuffer, to: 22050)
    signals[4410]  = try convert(sourceBuffer: monoBuffer, to: 4410)
    signals[882]   = try convert(sourceBuffer: monoBuffer, to: 882)
    signals[441]   = try convert(sourceBuffer: monoBuffer, to: 441)

    self.signals = signals

  }


  /// Returns the signal for the specified sample rate.
  public subscript(sampleRate: SampleRate) -> SignalVector {
    return signals[sampleRate]!
  }


  public enum Error: String, Swift.Error {

    case invalidSampleRate = "The supplied buffer must have a sample rate ≥ 44100 Hz."
    case failureToCreateConverter = "Failed to create the `AVAudioConverter`."
    case invalidFormat = "Invalid audio format configuration."
    case invalidBuffer = "Invalid buffer configuration."
    case conversionError = "Error converting buffer."
    case channelDataError = "Failed to access the buffer's channel data."
    case invalidFile = "Failed to load audio file content."

  }

}

/// Creates and configures a new `AVAudioConverter` instance using the specified formats.
///
/// - Parameters:
///   - sourceFormat: The source format for the converter.
///   - targetFormat: The destination format for the converter.
/// - Returns: The newly created and configured converter.
/// - Throws: `MultirateAudioPCMBuffer.Error.failureToCreateConverter`
private func audioConverter(withSourceFormat sourceFormat: AVAudioFormat,
                            targetFormat: AVAudioFormat) throws -> AVAudioConverter
{

  // Create the converter.
  guard let converter = AVAudioConverter(from: sourceFormat, to: targetFormat) else {

    throw MultirateAudioPCMBuffer.Error.failureToCreateConverter

  }

  // Configure the converter for maximum quality.
  converter.sampleRateConverterQuality = AVAudioQuality.max.rawValue

  // Configure the converter to use a 'mastering' grade algorithm for down(mixing/sampling).
  converter.sampleRateConverterAlgorithm = AVSampleRateConverterAlgorithm_Mastering

  // Configure the converter to operate without 'priming'.
  converter.primeMethod = .none

  return converter

}

/// Converts a buffer with a stereo or mono signal to a mono signal at the specified sample rate.
///
/// - Parameters:
///   - sourceBuffer: The buffer with the signal to convert.
///   - rate: The sample rate to which the signal will be converted.
/// - Returns: A buffer with the converted signal.
/// - Throws: Any error that arises from a problem audio format or invalid buffer data.
private func convert(sourceBuffer: AVAudioPCMBuffer, to rate: SampleRate) throws -> SignalVector {

  // Get the sample rate as a `Double` value.
  let targetSampleRate = Float64(rate.rawValue)

  // Create the target format.
  guard let targetFormat = AVAudioFormat(commonFormat: .pcmFormatFloat64,
                                         sampleRate: targetSampleRate,
                                         channels: 1,
                                         interleaved: false)
    else
  {
    throw MultirateAudioPCMBuffer.Error.invalidFormat
  }

  // Get the input format from the buffer.
  let sourceFormat = sourceBuffer.format

  // Create a new audio converter.
  let converter = try audioConverter(withSourceFormat: sourceFormat, targetFormat: targetFormat)

  // Calculate the scaling factor for the sample count.
  let scalingFactor = targetSampleRate / sourceBuffer.format.sampleRate

  // Get the total number of frames in the source buffer.
  let sourceTotalFrames = Int(sourceBuffer.frameLength)

  // Calculate the frame capacity needed for the downsampled buffer.
  let targetTotalFrames = Int((Float64(sourceTotalFrames) * scalingFactor).rounded(.up))

  // Create a buffer to hold the converted signal.
  guard let targetBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat,
                                            frameCapacity: AVAudioFrameCount(targetTotalFrames))
  else
  {
    throw MultirateAudioPCMBuffer.Error.invalidBuffer
  }

  // Create a flag for indicating whether the source buffer has been returned from the callback.
  var sourceBufferReturned = false

  // Create the callback that feeds input to the converter.
  let inputBlock: AVAudioConverterInputBlock = {

    guard !sourceBufferReturned else {
      $1.pointee = .endOfStream
      return nil
    }

    $1.pointee = .haveData
    sourceBufferReturned = true

    return sourceBuffer

  }

  // Create an error pointer.
  var error: NSError? = nil

  // Convert the buffer.
  let status = converter.convert(to: targetBuffer, error: &error, withInputFrom: inputBlock)

  // Check thet status.
  switch status {

    case .haveData, .inputRanDry:
      // The target buffer has data.

      guard let float64BufferData = targetBuffer.float64ChannelData?.pointee else {
        throw MultirateAudioPCMBuffer.Error.channelDataError
      }

      // Allocate storage for copying the data.
      return SignalVector(copying: float64BufferData, count: Int(targetBuffer.frameLength))

    case .endOfStream, .error:
      // Conversion failed and/or target buffer has no data.

      throw error ?? MultirateAudioPCMBuffer.Error.conversionError

  }

}