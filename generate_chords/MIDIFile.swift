//
//  MIDIFile.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/24/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import Foundation
import typealias CoreMIDI.MIDITimeStamp
import MoonKit

/// Struct that holds the data for a complete MIDI file.
struct MIDIFile: ByteArrayConvertible, CustomStringConvertible {

  /// The collection of track chunks that make up the file's contents.
  let tracks: [TrackChunk]

  /// The file's header.
  let header: HeaderChunk

  init(tracks: [[MIDIEvent]]) {

    var trackChunks: [TrackChunk] = []

    for (index, events) in tracks.enumerated() {

      // Create the track name MIDI event.
      let trackName: MIDIEvent =
        .meta(MIDIEvent.MetaEvent(data: .sequenceTrackName(name: "Track \(index + 1)")))

      // Create the MIDI event specifying the end of the track.
      let endOfTrack: MIDIEvent =
        .meta(MIDIEvent.MetaEvent(data: .endOfTrack, time: events.last?.time ?? 0))

      let trackEvents = [trackName] + events + [endOfTrack]

      trackChunks.append(TrackChunk(events: trackEvents))

    }

    header = HeaderChunk(numberOfTracks: UInt16(trackChunks.count + 1))
    self.tracks = trackChunks

  }

  /// Initializing with a file url.
  /// - Throws: Any error encountered initializing via `init(data:)`.
  init(file: URL) throws { try self.init(data: try Data(contentsOf: file)) }

  /// Initializing with raw data.
  /// - Throws: `Error.fileStructurallyUnsound`, `Error.invalidHeader`.
  init(data: Data) throws {

    // The file's header should be a total of fourteen bytes.
    let headerSize = 14

    // Check that there are enough bytes for the file's header.
    guard data.count > headerSize else {
      throw Error.fileStructurallyUnsound("Not enough bytes in file")
    }

    // Initialize `header` with the first fourteen bytes in `data`.
    header = try HeaderChunk(data: data.prefix(headerSize))

    // Create a variable for tracking the number of decoded tracks.
    var tracksRemaining = header.numberOfTracks

    // Create an array for holding track chunks decoded but not yet processed.
    var unprocessedTracks: [TrackChunk] = []

    // Start with the index just past the decoded header.
    var currentIndex = headerSize

    // Iterate while the number of tracks decoded is less than the the total specified in the file's header.
    while tracksRemaining > 0 {

      // Check that there are at least enough bytes remaining for a track's preamble.
      guard data.endIndex - currentIndex > 8 else {
        throw Error.fileStructurallyUnsound("Not enough bytes for track count specified in header.")
      }

      // Check that chunk begins with 'MTrk'.
      guard String(data: data[currentIndex ..< (currentIndex + 4)], encoding: .utf8) == "MTrk" else {
        throw Error.invalidHeader("Expected chunk header with type 'MTrk'")
      }

      currentIndex += 4  // Move past 'MTrk'

      // Get the byte count for the chunk's data.
      let chunkLength = Int(Byte4(data[currentIndex ..< (currentIndex + 4)]))

      currentIndex += 4 // Move past the chunk size.

      // Check that there are at least enough bytes remaining for the decoded chunk size.
      guard currentIndex + chunkLength <= data.endIndex else {
        throw Error.fileStructurallyUnsound("Not enough bytes in track chunk \(unprocessedTracks.count)")
      }

      // Calculate the range for the chunk's data.
      let range = currentIndex ..< (currentIndex + chunkLength)

      // Get the chunk's data.
      let chunkData = data[range]

      // Create a new `TrackChunk` instance using the chunk's data.
      let chunk = try TrackChunk(data: chunkData)

      // Append the decoded chunk to the collection of unprocessed tracks.
      unprocessedTracks.append(chunk)

      currentIndex += chunkLength  // Move past the decoded chunk.

      tracksRemaining -= 1  // Decrement the number of tracks that remain.

    }

    // Create an array for accumulating track chunks as they are processed.
    var processedTracks: [TrackChunk] = []

    // Iterate the decoded track chunks.
    for trackChunk in unprocessedTracks {

      // Create a variable for holding the tick offset.
      var ticks: UInt64 = 0

      // Create an array for accumulating the track's events as they are processed.
      var processedEvents: [MIDIEvent] = []

      // Iterate the track chunk's events.
      for var trackEvent in trackChunk.events {

        // Retrieve the event's delta value.
        guard let delta = trackEvent.delta else {
          throw Error.fileStructurallyUnsound("Track event missing delta value")
        }

        // Advance `ticks` by the event's delta value.
        ticks += delta

        // Modify the event's time using the current tick offset.
        trackEvent.time = ticks

        // Append the modified event.
        processedEvents.append(trackEvent)

      }

      // Create a new track chunk composed of the processed events.
      let processedTrack = TrackChunk(events: processedEvents)

      // Append the processed track chunk.
      processedTracks.append(processedTrack)

    }

    // Intialize `tracks` with the processed track chunks.
    tracks = processedTracks

  }

  /// The collection of raw bytes consisting of the header's bytes followed by each of the track's bytes.
  var bytes: [UInt8] {

    // Create an array for accumulating the file's bytes, initializing the array with header's bytes.
    var bytes = header.bytes

    // Create an array for holding the arrays of bytes generated by the tracks.
    var trackData: [[UInt8]] = []

    // Create a tempo track
    var tempoTrackBytes: [UInt8] = []

    let deltaTimeBytes = VariableLengthQuantity.zero.bytes
    tempoTrackBytes.append(contentsOf: deltaTimeBytes)
    tempoTrackBytes.append(contentsOf:
      MIDIEvent.meta(MIDIEvent.MetaEvent(data: .timeSignature(signature: .fourFour,
                                                              clocks: 36,
                                                              notes: 8))).bytes)
    tempoTrackBytes.append(contentsOf: deltaTimeBytes)
    tempoTrackBytes.append(contentsOf:
      MIDIEvent.meta(MIDIEvent.MetaEvent(data: .tempo(bpm: 120))).bytes)
    tempoTrackBytes.append(contentsOf: deltaTimeBytes)
    tempoTrackBytes.append(contentsOf:
      MIDIEvent.meta(MIDIEvent.MetaEvent(data: .endOfTrack)).bytes)

    trackData.append(tempoTrackBytes)

    // Iterate the track chunks.
    for track in tracks {

      // Create a variable for holding the time of the most recently encoded track event.
      var previousTime: MIDITimeStamp = 0

      // Create an array for holding the encoded track chunk.
      var trackBytes: [UInt8] = []

      // Iterate the events in the track chunk.
      for event in track.events {

        // Get the event's tick offset, using the previous time if the event's time is less than the
        // previous time so that the delta calculation results in a value of `0`.
        let eventTime = max(event.time, previousTime)

        // Calculate the delta for `event`.
        let delta = VariableLengthQuantity(eventTime - previousTime)

        // Append the bytes for the event's delta value.
        trackBytes.append(contentsOf: delta.bytes)

        // Append the bytes for the event.
        trackBytes.append(contentsOf: event.bytes)

        // Update the previous time to the event's time.
        previousTime = eventTime

      }

      // Append the track's bytes.
      trackData.append(trackBytes)

    }

    // Iterate the arrays of the track's bytes to append each track's bytes to `bytes`.
    for trackBytes in trackData {

      // Append 'MTrk' to mark the beginning of a track chunk.
      bytes.append(contentsOf: Array("MTrk".utf8))

      // Append the size of `trackBytes`.
      bytes.append(contentsOf: UInt32(trackBytes.count).bytes)

      // Append the track's data.
      bytes.append(contentsOf: trackBytes)

    }

    return bytes

  }

  var description: String {
    return "\(header)\n\(tracks.map({$0.description}).joined(separator: "\n"))"
  }

  /// An enumeration of the possible errors thrown by `MIDIFile`.
  enum Error: LocalizedError {
    case fileStructurallyUnsound (String)
    case invalidHeader (String)
    case invalidLength (String)
    case unsupportedEvent (String)
    case unsupportedFormat (String)

    var errorDescription: String? {
      switch self {
        case .fileStructurallyUnsound: return "File structurally unsound"
        case .invalidHeader:           return "Invalid header"
        case .invalidLength:           return "Invalid length"
        case .unsupportedEvent:        return "Unsupported event"
        case .unsupportedFormat:       return "Unsupported format"
      }
    }

    var failureReason: String? {
      switch self {
        case .fileStructurallyUnsound(let reason),
             .invalidHeader(let reason),
             .invalidLength(let reason),
             .unsupportedEvent(let reason),
             .unsupportedFormat(let reason):
          return reason
      }
    }
  }

  /// Struct to hold the header chunk of a MIDI file.
  struct HeaderChunk: CustomStringConvertible {

    /// The total number of bytes for a valid header chunk.
    static let byteCount = 14

    /// The MIDI file format.
    static let format: UInt16 = 1

    /// The number of bytes in the header's data.
    static let dataSize: UInt32 = 6

    /// The number of tracks specified by the header.
    let numberOfTracks: UInt16

    /// The subbeat division specified by the header.
    let division: UInt16 = 480

    /// The collection of raw bytes for the header.
    var bytes: [UInt8] {

      // Initialize an array with the bytes of `type`.
      var result: [UInt8] = Array("MThd".utf8)

      // Append the size of the chunk's data.
      result.append(contentsOf: HeaderChunk.dataSize.bytes)

      // Append the bytes of `format`.
      result.append(contentsOf: HeaderChunk.format.bytes)

      // Append the bytes of `numberOfTracks`.
      result.append(contentsOf: numberOfTracks.bytes)

      // Append the bytes of `division`.
      result.append(contentsOf: division.bytes)

      return result

    }

    /// Initialize with the number of tracks.
    init(numberOfTracks: UInt16) { self.numberOfTracks = numberOfTracks }

    /// Initialize with raw bytes.
    /// - Throws: 
    ///   `Error.invalidLength` when `data.count != HeaderChunk.byteCount` or `data` specifies a size other
    ///   than `HeaderChunk.dataSize`.
    ///
    ///   `Error.invalidHeader` when data does not begin with 'MThd'
    ///
    ///   `Error.unsupportedFormat` when `data` specifies a file format other than `HeaderChunk.format`.
    init(data: Data.SubSequence) throws {

      // Check that `data` contains the required number of bytes.
      guard data.count == HeaderChunk.byteCount else {
        throw Error.invalidLength("Header chunk must be 14 bytes")
      }

      // Check that `data` begins with 'MThd'.
      guard String(data[data.startIndex ..< (data.startIndex + 4)]) == "MThd" else {
        throw Error.invalidHeader("Expected chunk header with type 'MThd'")
      }

      // Check that the data's preamble specifies six bytes of data.
      guard HeaderChunk.dataSize == UInt64(data[(data.startIndex + 4) ..< (data.startIndex + 8)]) else {
        throw Error.invalidLength("Header must specify length of 6")
      }

      // Check that the data specifies the correct file format.
      guard HeaderChunk.format == UInt16(data[(data.startIndex + 8) ..< (data.startIndex + 10)]) else {
        throw Error.unsupportedFormat("Format must be 00 00 00 00, 00 00 00 01, 00 00 00 02")
      }

      // Intialize `numberOfTracks` with a value decoded from the remaining bytes in data.
      numberOfTracks = UInt16(data[(data.startIndex + 10) ..< (data.startIndex + 12)])

    }

    var description: String {
      return [
        "MThd",
        "format: \(HeaderChunk.format)",
        "number of tracks: \(numberOfTracks)",
        "division: \(division)"
        ].joined(separator: "\n\t")
    }

  }

  /// Struct to hold a track chunk for a MIDI file.
  struct TrackChunk: CustomStringConvertible {

    /// The four character ascii string identifying the chunk as a track chunk.
    let type = Byte4("MTrk".utf8)

    /// The collection of MIDI events for the track.
    var events: [MIDIEvent] = []

    /// Initializing an empty track chunk.
    init() {}

    /// Initializing with an array of MIDI events.
    init(events: [MIDIEvent]) { self.events = events }

    /// Initializing with raw bytes.
    /// - Throws: `Error.invalidLength`, `Error.invalidHeader`, `Error.invalidLength`.
    init(data: Data.SubSequence) throws {

      // Check that there are at least enough bytes for the preamble.
      guard data.count > 8 else { throw Error.invalidLength("Not enough bytes in chunk") }

      // Check that the `data` specifies a track chunk
      guard String(data[data.startIndex ..< (data.startIndex + 4)]) == "MTrk" else {
        throw Error.invalidHeader("Track chunk header must be of type 'MTrk'")
      }

      // Get the size of the chunk's data.
      let chunkLength = Byte4(data[(data.startIndex + 4) ..< (data.startIndex + 8)])

      // Check that the size specified in the preamble and the size of the data provided are a match.
      guard data.count == Int(chunkLength) + 8 else {
        throw Error.invalidLength("Length specified in bytes and the length of the bytes do not match")
      }

      // Start with the index just past the chunk's preamble.
      var currentIndex = data.startIndex + 8

      // Create an array for accumulating decoded MIDI events.
      var events: [MIDIEvent] = []

      // Iterate through the remaining bytes of `data`.
      while currentIndex < data.endIndex {

        // Create an additional index set to the current index.
        var i = currentIndex

        // Iterate through the bytes until reaching the end of the variable length quantity.
        while data[i] & 0x80 != 0 { i += 1 }

        // Get the delta value for the event.
        let delta = UInt64(VariableLengthQuantity(bytes: data[currentIndex ... i]))

        // Move current index to just past the bytes of the delta.
        currentIndex = i + 1

        // Store the first index of the bytes containing the event data.
        let eventStart = currentIndex

        // Handle according to the first byte of the data.
        switch data[currentIndex] {

          case 0xFF:
            // The event is a meta event. Create and append either a node or meta event.

            // Move the current index past the first two bytes of the event's data.
            currentIndex = currentIndex &+ 2

            // Update `i` to the current index.
            i = currentIndex

            // Iterate through the bytes until reaching the end of the variable length quantity.
            while data[i] & 0x80 != 0 { i += 1 }

            // Get the size of the event's data.
            let dataLength = Int(VariableLengthQuantity(bytes: data[currentIndex ... i]))

            // Move the current index to the last byte of the event's data.
            currentIndex = i &+ dataLength

            // Get the event's data.
            let eventData = data[eventStart...currentIndex]

            // Create and append an event of the decoded type.
            events.append(.meta(try MIDIEvent.MetaEvent(delta: delta, data: eventData)))

            // Move the current index past the decoded event.
            currentIndex = currentIndex &+ 1

          default:
            // Decode a channel event or throw an error.

            // Get the kind of channel event
            guard let type = MIDIEvent.ChannelEvent.Status.Kind(rawValue: data[currentIndex] >> 4) else {
              throw Error.unsupportedEvent("\(data[currentIndex] >> 4) is not a supported ChannelEvent")
            }

            // Get the event's data.
            let eventData = data[currentIndex ..< (currentIndex + type.byteCount)]

            // Create and append a new channel event using `eventData`.
            events.append(.channel(try MIDIEvent.ChannelEvent(delta: delta, data: eventData)))

            // Move the current index past the event's data.
            currentIndex = currentIndex &+ type.byteCount

        }

      }

      // Intialize `events` with the decoded events.
      self.events = events

    }

    var description: String {
      return "MTrk\n\(events.map({$0.description}).joined(separator: "\n"))"
    }

  }

  /// Struct for converting values to MIDI variable length quanity representation
  ///
  /// These numbers are represented 7 bits per byte, most significant bits first.
  /// All bytes except the last have bit 7 set, and the last byte has bit 7 clear.
  /// If the number is between 0 and 127, it is thus represented exactly as one byte.
  struct VariableLengthQuantity: CustomStringConvertible, CustomDebugStringConvertible {

    /// The variable length quantity as a stream of raw bytes.
    let bytes: [UInt8]

    /// The variable length quantity equal to `0`.
    static let zero = VariableLengthQuantity(0)

    /// The variable length quantity's represented value as a stream of raw bytes.
    var representedValue: [UInt8] {

      // Split the variable length quantity's bytes into groups of 8.
      let groups = bytes.segment(8)

      // Create an array for accumulating the resolved 8-byte groups as an unsigned 64 bit integer.
      var resolvedGroups: [UInt64] = []

      // Iterate the 8-byte groups.
      for group in groups {

        // Check that the group is not empty.
        guard !group.isEmpty else { continue }

        // Convert the group of 8 bytes into an unsigned 64 bit integer.
        var groupValue = UInt64(group[0])

        // Check that the value needs to be decoded.
        guard groupValue & 0x80 != 0 else {
          resolvedGroups.append(groupValue)
          continue
        }

        // Filter the value to include only the bits contributing to the represented number.
        groupValue &= UInt64(0x7F)

        // Create a variable for tracking the index.
        var i = 1

        // Create a variable for holding the byte to test for the flag bit.
        var next = UInt8(0)

        // Repeat until the tested byte does not have the flag bit set.
        repeat {

          // Check that there is something left.
          guard i < group.count else { break }

          // Get the next byte to test.
          next = group[i]

          // Increment the index.
          i = i &+ 1

          // Update the group's value.
          groupValue = (groupValue << UInt64(7)) + UInt64(next & 0x7F)

        } while next & 0x80 != 0

        // Appended the decoded value for the group.
        resolvedGroups.append(groupValue)

      }

      // Create a flattened array of the bytes of the group values.
      var resolvedBytes = resolvedGroups.flatMap { $0.bytes }

      // Removing leading zeroes.
      while resolvedBytes.count > 1 && resolvedBytes.first == 0 { resolvedBytes.remove(at: 0) }

      return resolvedBytes

    }

    /// Intializing with a stream of raw bytes.
    init<S:Swift.Sequence>(bytes b: S) where S.Iterator.Element == UInt8 { bytes = Array(b) }

    /// Initialize from any `ByteArrayConvertible` type holding the represented value
    init<B:ByteArrayConvertible>(_ value: B) {

      // Get the value's bytes as an unsigned 64-bit integer.
      var value = UInt64(value.bytes)

      // Initialize a buffer with the first 7 bits contributing to the represented value.
      var buffer = value & 0x7F

      while value >> 7 > 0 {
        value = value >> 7
        buffer <<= 8
        buffer |= 0x80
        buffer += value & 0x7F
      }

      // Create an array for accumulating the variable length quantity's bytes.
      var result: [Byte] = []

      repeat {

        result.append(UInt8(buffer & 0xFF))

        guard buffer & 0x80 != 0 else { break }

        buffer = buffer >> 8

      } while true

      // Remove leading zeroes.
      while let firstByte = result.first, result.count > 1 && firstByte == 0 { result.remove(at: 0) }

      // Intialize `bytes` with the accumulated bytes.
      bytes = result

    }

    var description: String { return "\(UInt64(self))" }

    var debugDescription: String {

      let representedValue = self.representedValue

      var result = "\(type(of: self).self) {"

      result += [
        "bytes (hex, decimal): (\(String(hexBytes: bytes)), \(UInt64(bytes)))",
        "representedValue (hex, decimal): (\(String(hexBytes: representedValue)), \(UInt64(self)))"
      ].joined(separator: "; ")

      result += "}"

      return result

    }

  }

}

extension UInt64 {

  /// Initializing with MIDI file's variable length quantity.
  init(_ quanity: MIDIFile.VariableLengthQuantity) {
    self.init(quanity.bytes)
  }

}

extension Int {

  /// Initializing with MIDI file's variable length quantity.
  init(_ quanity: MIDIFile.VariableLengthQuantity) {
    self.init(quanity.bytes)
  }

}
