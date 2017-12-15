//
//  MIDIEvent.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/29/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import Foundation
import typealias CoreMIDI.MIDITimeStamp

/// A protocol with properties common to all types representing a MIDI event.
private protocol _MIDIEvent: CustomStringConvertible {

  /// The event's tick offset.
  var time: MIDITimeStamp { get set }

  /// The event's tick offset.
  var delta: UInt64? { get set }

  /// The MIDI event expressed in raw bytes.
  var bytes: [UInt8] { get }

}

/// An enumeration of MIDI event types.
enum MIDIEvent: Hashable, CustomStringConvertible {

  /// The `MIDIEvent` wraps a `MetaEvent` instance.
  case meta (MetaEvent)

  /// The `MIDIEvent` wraps a `ChannelEvent` instance.
  case channel (ChannelEvent)

  /// The wrapped MIDI event upcast to `_MIDIEvent`.
  private var baseEvent: _MIDIEvent {

    // Consider the MIDI event.
    switch self {
      case .meta(let event):
        // Return the wrapped `MetaEvent`.

        return event

      case .channel(let event):
        // Return the wrapped `ChannelEvent`.

        return event

    }

  }

  /// Initialize with an event.
  /// 
  /// - Parameter baseEvent: The MIDI event to wrap.
  private init(_ baseEvent: _MIDIEvent) {

    // Consider the event to wrap.
    switch baseEvent {

      case let event as MetaEvent:
        // Wrap the `MetaEvent`.

        self = .meta(event)

      case let event as ChannelEvent:
        // Wrap the `ChannelEvent`.

        self = .channel(event)

      default:
        // This case is unreachable because one of the previous cases must match. This
        // can be known because `_MIDIEvent` is a private protocol, meaning declarations
        // of conformance appear within this file.

        fatalError("Failed to downcast event")

    }

  }

  /// The base midi event exposed as `Any`.
  var event: Any { return baseEvent }

  /// The wrapped MIDI event's tick offset.
  var time: MIDITimeStamp {

    get {

      // Return the bar-beat time of the wrapped MIDI event.
      return baseEvent.time

    }

    set {

      // Create a mutable copy of the wrapped MIDI event.
      var event = baseEvent

      // Update the MIDI event's bar-beat time.
      event.time = newValue

      // Replace `self` with a `MIDIEvent` wrapping the updated MIDI event.
      self = MIDIEvent(event)

    }

  }

  /// The wrapped MIDI event's tick offset.
  var delta: UInt64? {

    get {

      // Return the wrapped MIDI event's delta value.
      return baseEvent.delta

    }

    set {

      // Create a mutable copy of the wrapped MIDI event.
      var event = baseEvent

      // Update the MIDI event's delta value.
      event.delta = newValue

      // Replace `self` with a `MIDIEvent` wrapping the updated MIDI event.
      self = MIDIEvent(event)

    }

  }

  /// The base event encoded as an array of `UInt8` values.
  var bytes: [UInt8] { return baseEvent.bytes }

  /// Returns `true` iff the two values are of the same enumeration case and the two MIDI
  /// event values they wrap are equal.
  ///
  /// - Parameters:
  ///   - lhs: One of the two `MIDIEvent` values to compare for equality.
  ///   - rhs: The other of the two `MIDIEvent` values to compare for equality.
  /// - Returns: `true` if the two values are equal and `false` otherwise.
  static func ==(lhs: MIDIEvent, rhs: MIDIEvent) -> Bool {

    // Consider the two values.
    switch (lhs, rhs) {

      case let (.meta(event1), .meta(event2))
        where event1 == event2:
        // `lhs` and `rhs` wrap equal `MetaEvent` values. Return `true`.

        return true

      case let (.channel(event1), .channel(event2))
        where event1 == event2:
        // `lhs` and `rhs` wrap equal `ChannelEvent` values. Return `true`.

        return true

      default:
        // `lhs` and `rhs` wrap unequal MIDI event values. Return `false`.

        return false

    }

  }

  var hashValue: Int {

    // Group the MIDI event's raw bytes into `UInt64` values.
    let byteGroups = bytes.segment(8).map(UInt64.init)

    // Reduce the groups using a bitwise XOR and get the hash value.
    let bytesHash = byteGroups.reduce(0, ^).hashValue

    // Get the hash value for `delta`.
    let deltaHash = delta?.hashValue ?? 0

    // Get the hash value for `time`.
    let timeHash = time.hashValue

    // Return the result of combining the three hash values using a bitwise XOR.
    return bytesHash ^ deltaHash ^ timeHash

  }

  var description: String {

    // Return the description for the wrapped MIDI event.
    return baseEvent.description

  }

  /// A structure for representing a meta MIDI event. The signature of a meta MIDI event is
  /// as follows: 
  ///        
  /// \<delta *(4 bytes)*\> **FF** \<type *(1 byte)*\> \<data length *(variable length
  /// quantity)*\> \<data *(data length bytes)*\>
  ///
  /// - TODO: Why do we show the delta value in the description when we do not include the
  ///         corresponding raw bytes in the derived `bytes` value?
  struct MetaEvent: _MIDIEvent, Hashable {

    var time: MIDITimeStamp

    var delta: UInt64?

    /// The data contained by the meta MIDI event.
    var data: Data

    var bytes: [UInt8] {

      // Get the raw bytes for the event's data.
      let dataBytes = data.bytes

      // Get the size of `dataBytes` represented as a variable length quantity.
      let dataLength = MIDIFile.VariableLengthQuantity(dataBytes.count)

      // Create an array for accumulating the event's raw bytes initialized with the byte
      // marking the MIDI event as meta.
      var bytes: [UInt8] = [0xFF]

      // Append the byte specifying the meta event's type.
      bytes.append(data.type)

      // Append the bytes specifying the length of the event's data.
      bytes.append(contentsOf: dataLength.bytes)

      // Append the event's data bytes.
      bytes.append(contentsOf: dataBytes)

      // Return the collected bytes.
      return bytes

    }

    /// Initializing with data and a bar-beat time.
    ///
    /// - Parameters:
    ///   - data: The meta MIDI event data that will be held by the new `MetaEvent`.
    ///   - time: The tick offset for the new `MetaEvent`. The default is `0`.
    init(data: Data, time: MIDITimeStamp = 0) {

      // Initialize `data` with the specified data.
      self.data = data

      // Initialize `time` with the specified bar-beat time.
      self.time = time

    }

    /// Initializing with a tick offset and a slice of data.
    ///
    /// - Parameters:
    ///   - delta: The tick offset for the new `MetaEvent`.
    ///   - data: The slice of raw bytes used to initialize `data` for the new `MetaEvent`.
    ///
    /// - Throws: `MIDIFile.Error.invalidLength` when `data.count < 3` or the byte count
    ///           specified within `data` does not correspond with the actual bytes, 
    ///           `MIDIFile.Error.invalidHeader` when the first byte does not equal `0xFF`,
    ///           Any error encountered initializing the `data` property with the specified
    ///           data bytes.
    init(delta: UInt64, data: Foundation.Data.SubSequence) throws {

      // Initialize `delta` with the specified tick offset.
      self.delta = delta

      // Check that there are at least 3 raw bytes in `data`.
      guard data.count >= 3 else {

        // Throw an invalid length error.
        throw MIDIFile.Error.invalidLength("Not enough bytes in the data provided.")

      }

      // Check the first byte of data.
      guard data[data.startIndex] == 0xFF else {

        // Throw an invalid header error.
        throw MIDIFile.Error.invalidHeader("The first byte of data must equal 0xFF")

      }

      // Create a variable to hold the current index, beginning with the second byte.
      var currentIndex = data.startIndex + 1

      // Get the byte specifying the meta MIDI event's type.
      let typeByte = data[currentIndex]

      // Increment the index past the type byte.
      currentIndex += 1

      // Create a variable to hold the index of the final byte of the variable length 
      // quantity representing the expected number of bytes in the meta MIDI event's data.
      var last7BitByte = currentIndex

      // Iterate through the raw bytes while the iterated byte when interpretted as a 7-bit 
      // value followed by a flag bit has the flag bit set.
      while data[last7BitByte] & 0x80 != 0 {

        // Increment `last7BitByte` to check the next byte for the end of the variable
        // length quantity.
        last7BitByte += 1

      }

      // Get the variable length quantity bytes that contain the expected data size.
      let dataLengthBytes = data[currentIndex ... last7BitByte]

      // Get the expected length of the meta MIDI event's data by converting a variable
      // length quantity initialized with the determined subrange of bytes.
      let dataLength = Int(MIDIFile.VariableLengthQuantity(bytes: dataLengthBytes))

      // Set the current index to the location of the next unproccessed byte.
      currentIndex = last7BitByte + 1

      // Check that the number of bytes remaining matches the expected data length.
      guard data.endIndex == currentIndex &+ dataLength else {

        // Throw an invalid length error.
        throw MIDIFile.Error.invalidLength("Specified length does not match actual")

      }

      // Initialize `data` using `typeByte` and the remaining bytes.
      self.data = try Data(type: typeByte, data: data[currentIndex...])

      // Initialize `time` with `zero`.
      time = 0

    }
    
    /// Initializing with a bar-beat time and the meta MIDI event's data.
    ///
    /// - Parameters:
    ///   - time: The tick offset represented as a bar-beat time for the new `MetaEvent`.
    ///   - data: The data for the new `MetaEvent`.
    init(time: MIDITimeStamp, data: Data) {

      // Initialize `time` with the specified bar-beat time.
      self.time = time

      // Initialize `data` with the specified data.
      self.data = data

    }

    var hashValue: Int {

      // Return the result of combining the hash values for `time`, `data`, and `delta`
      // using a bitwise XOR.
      return time.hashValue ^ data.hashValue ^ (delta?.hashValue ?? 0)

    }

    /// Returns `true` iff the two events have equal `time`, `delta`, and `data` values.
    static func ==(lhs: MetaEvent, rhs: MetaEvent) -> Bool {
      return lhs.time == rhs.time && lhs.delta == rhs.delta && lhs.data == rhs.data
    }

    var description: String { return "\(time) \(data)" }

    /// An enumeration encapsulating the data for a meta MIDI event representable by an
    /// instance of `MetaEvent`.
    enum Data: Hashable, CustomStringConvertible {

      /// A string in the general sense.
      case text (text: String)

      /// A string intended to serve as a copyright notice.
      case copyrightNotice (notice: String)

      /// A string specifying the name of a sequence or track.
      case sequenceTrackName (name: String)

      /// A string specifying the name of an instrument.
      case instrumentName (name: String)

      /// A string for labeling a particular tick offset.
      case marker (name: String)

      /// A string specifying the name of a device.
      case deviceName (name: String)

      /// A string specifying the name of a program.
      case programName (name: String)

      /// Used to mark the end of a track.
      case endOfTrack

      /// A double value containing the number of beats per minute.
      case tempo (bpm: Double)

      /// The components needed for expressing the time signature: a `TimeSignature` value
      /// which holds the numerator and denominator of the time signature as it would be 
      /// notated, a `UInt8` specifying the number of MIDI clocks per metronome click, and
      /// a `UInt8` specifying the number of thirty-second notes per 24 MIDI clocks.
      case timeSignature (signature: TimeSignature, clocks: UInt8, notes: UInt8)

      /// The byte that follows `FF`, when transmitting a meta MIDI event, to specify the 
      /// type of event.
      var type: UInt8 {

        // Return the byte that corresponds with the data.
        switch self {

          case .text:              return 0x01
          case .copyrightNotice:   return 0x02
          case .sequenceTrackName: return 0x03
          case .instrumentName:    return 0x04
          case .marker:            return 0x06
          case .programName:       return 0x08
          case .deviceName:        return 0x09
          case .endOfTrack:        return 0x2F
          case .tempo:             return 0x51
          case .timeSignature:     return 0x58

        }

      }

      /// The raw bytes of data for use in MIDI packet transmissions.
      var bytes: [UInt8] {

        // Consider the data.
        switch self {

          case .text(let text),
               .copyrightNotice(let text),
               .sequenceTrackName(let text),
               .instrumentName(let text),
               .marker(let text),
               .programName(let text),
               .deviceName(let text):
            // The data is composed of a single string of text. Return the string's bytes.

            return text.bytes

          case .endOfTrack:
            // The data is empty. Return an empty array.

            return []

          case let .tempo(tempo):
            // The data contains the number of beats per minute. Convert to the number of
            // microseconds per MIDI quarter-note and return the three least significant
            // bytes.

            return Array(UInt32(60_000_000 / tempo).bytes.dropFirst())

          case let .timeSignature(signature, clocks, notes):
            // The data contains a structure and two bytes. Return the bytes of the 
            // structure followed by the other two bytes.

            return signature.bytes + [clocks, notes]

        }

      }

      /// Initializing with the data's event type and the data's raw bytes.
      ///
      /// - Parameters:
      ///   - type: The byte specifying the type of event for the new `Data` instance.
      ///   - data: The raw byte representation for the new `Data` instance.
      /// - Throws: `MIDIFile.Error.invalidLength` when the number of bytes in `data` is
      ///           inconsistent with the number expected for `type`, 
      ///           `MIDIFile.Error.unsupportedEvent` when `type` does not match the type
      ///           value for one of the `Data` enumeration cases.
      init(type: UInt8, data: Foundation.Data.SubSequence) throws {

        // Consider the type-specifying byte.
        switch type {

          case 0x01:
            // The type is `text`.

            self = .text(text: String(data))

          case 0x02:
            // The type is `copyrightNotice`.

            self = .copyrightNotice(notice: String(data))

          case 0x03:
            // The type is `sequenceTrackName`.

            self = .sequenceTrackName(name: String(data))

          case 0x04:
            // The type is `instrumentName`.

            self = .instrumentName(name: String(data))

          case 0x06:
            // The type is `marker`.

            self = .marker(name: String(data))

          case 0x08:
            // The type is `programName`.

            self = .programName(name: String(data))

          case 0x09:
            // The type is `deviceName`.

            self = .deviceName(name: String(data))

          case 0x2F:
            // The type is `endOfTrack`.

            // Check that the specified collection of raw bytes is empty.
            guard data.isEmpty else {

              // Throw an `invalidLength` error.
              throw MIDIFile.Error.invalidLength("An end-of-track event has no data.")

            }

            self = .endOfTrack

          case 0x51:
            // The type is `tempo`.

            // Check that there are 3 bytes of data.
            guard data.count == 3 else {

              // Create an error message.
              let message = "Expected 3 bytes of data for tempo event."

              // Throw an `invalidLength` error.
              throw MIDIFile.Error.invalidLength(message)

            }

            // Convert the three bytes specifying microseconds per quarter-note into a
            // double specifying the beats per minute.
            let bpm = Double(60_000_000 / UInt32(data))

            self = .tempo(bpm: bpm)

          case 0x58:
            // The type is `timeSignature`.

            // Check that there are 4 bytes of data.
            guard data.count == 4 else {

              // Create an error message.
              let message = "TimeSignature event data should have a 4 byte length"

              // Throw an `invalidLength` error.
              throw MIDIFile.Error.invalidLength(message)

            }

            // Create a time signature with the first two bytes.
            let signature = TimeSignature(data.prefix(2))

            // The third byte holds the number of MIDI clocks per metronome click.
            let clocks = data[data.startIndex &+ 2]

            // The fourth byte holds the number of thirty-second notes per 24 MIDI clocks.
            let notes = data[data.startIndex &+ 3]

            self = .timeSignature(signature: signature, clocks: clocks, notes: notes)

          default:
            // The specified type is not one of the supported meta event types.

            // Create an error message.
            let message = "\(String(hexBytes: [type])) is not a supported meta event type."

            // Throw an `unsupportedEvent` error.
            throw MIDIFile.Error.unsupportedEvent(message)

        }

      }

      var description: String {

        // Consider the data.
        switch self {

          case .text(let text):
            return "text '\(text)'"

          case .copyrightNotice(let text):
            return "copyright '\(text)'"

          case .sequenceTrackName(let text):
            return "sequence/track name '\(text)'"

          case .instrumentName(let text):
            return "instrument name '\(text)'"

          case .marker(let text):
            return "marker '\(text)'"

          case .programName(let text):
            return "program name '\(text)'"

          case .deviceName(let text):
            return "device name '\(text)'"

          case .endOfTrack:
            return "end of track"

          case .tempo(let bpm):
            return "tempo \(bpm)"

          case .timeSignature(let signature, _ , _):
            return "time signature \(signature.beatsPerBar)╱\(signature.beatUnit)"

        }

      }

      var hashValue: Int {

        // Get the hash value for the data's type value.
        let typeHash = type.hashValue

        // Create a variable for the hash value of the data's actual 'data'.
        let dataHash: Int

        // Consider the data.
        switch self {

          case .text (let text),
               .copyrightNotice (let text),
               .sequenceTrackName (let text),
               .instrumentName (let text),
               .marker (let text),
               .deviceName (let text),
               .programName (let text):
            // The hash value for the data's actual 'data' is the string's hash value.

            dataHash = text.hashValue

          case .endOfTrack:
            // The data has no actual 'data' so the hash value is `0`.

            dataHash = 0

          case .tempo (let bpm):
            // The hash value for the data's actual 'data' is the double's hash value.

            dataHash = bpm.hashValue

          case .timeSignature (let signature, let clocks, let notes):
            // The hash value of the data's actual 'data' is the bitwise XOR of the 
            // hash values for the `signature`, `clocks`, and `notes`.

            dataHash = signature.hashValue ^ clocks.hashValue ^ notes.hashValue

        }

        // Return the bitwise XOR of two hash values.
        return typeHash ^ dataHash

      }

      /// Returns `true` iff the two values are the same enumeration case with equal
      /// associated values.
      static func ==(lhs: Data, rhs: Data) -> Bool {

        // Consider the two values.
        switch (lhs, rhs) {

          case let (.text(text1), .text(text2)),
               let (.copyrightNotice(text1), .copyrightNotice(text2)),
               let (.sequenceTrackName(text1), .sequenceTrackName(text2)),
               let (.instrumentName(text1), .instrumentName(text2)),
               let (.marker(text1), .marker(text2)),
               let (.deviceName(text1), .deviceName(text2)),
               let (.programName(text1), .programName(text2)):
            // The two values are of the same case with an associated string value. Return
            // the result of evaluating the two strings for equality.

          return text1 == text2

          case (.endOfTrack, .endOfTrack):
            // The two values are both `endOfTrack`. Since there are no associated values
            // to consider, return `true`.

            return true

          case let (.tempo(bpm1), .tempo(bpm2)):
            // The two values are both `tempo`. Return the result of evaluating the two
            // double values for equality.

            return bpm1 == bpm2


          case let (.timeSignature(s1, c1, n1), .timeSignature(s2, c2, n2)):
            // The two values are both `timeSignature`. Return the result of evaluating
            // their associated values for equality.

            return s1 == s2 && c1 == c2 && n1 == n2

          default:
            // The values are not of the same enumeration case, return `false`.

            return false

        }

      }

    } // MIDIEvent.MetaEvent.Data

  } // MIDIEvent.MetaEvent

  /// Struct to hold data for a channel event where
  /// event = \<delta time\> \<status\> \<data1\> \<data2\>
  struct ChannelEvent: _MIDIEvent, Hashable {

    var time: MIDITimeStamp

    var delta: UInt64?

    /// Structure representing the channel event's status byte.
    var status: Status

    /// The first byte of data attached to the channel event. All channel events contain at
    /// least one byte of data.
    var data1: UInt8

    /// The second byte of data attached to the channel event. Some channel events, such
    /// as a channel event specifying a program change, have only one byte of data.
    var data2: UInt8?

    var bytes: [UInt8] {

      // Create an array for accumulating bytes intialized with the status byte and the
      // first byte of data.
      var result = [status.value, data1]

      // Check whether there is an additional byte of data.
      if let data2 = data2 {

        // Append the second byte of data.
        result.append(data2)

      }

      // Return the array of bytes.
      return result

    }

    /// Initializing with a tick offset, a bar-beat time, and the raw bytes for a channel
    /// event.
    ///
    /// - Parameters:
    ///   - delta: The tick offset for the new channel event.
    ///   - data: The collection of `UInt8` values for a MIDI transmission of the new
    ///           channel event.
    ///   - time: The event offset expressed as a bar-beat time. The default is `zero`.
    /// - Throws: `MIDIFile.Error.invalidLength` when `data` is empty or there is a mismatch
    ///           between the number of bytes provided in `data` and the number of bytes
    ///           expected for the kind of channel event specified by the status byte 
    ///           obtained from `data`, any error encountered intializing a `Status` value
    ///           with the status byte obtained from `data`.
    init(delta: UInt64,
         data: Foundation.Data.SubSequence,
         time: MIDITimeStamp = 0) throws
    {

      // Initialize `delta` with the specified delta value.
      self.delta = delta

      // Get the status byte from `data`.
      guard let statusByte = data.first else {

        // Create an error message.
        let message = "\(#function) requires a non-empty collection of `UInt8` values."

        // Throw an `invalidLength` error.
        throw MIDIFile.Error.invalidLength(message)

      }

      // Initialize `status` using the first byte of data.
      status = try Status(statusByte: statusByte)

      // Check the number of raw bytes against the count expected per the kind of event.
      guard data.count == status.kind.byteCount else {

        // Create an error message.
        let message = "The number of bytes provided does not match the number expected."

        // Throw an `invalidLength` error.
        throw MIDIFile.Error.invalidLength(message)

      }

      // Initialize `data1` with the second byte of the data provided.
      data1 = data[data.startIndex + 1]

      // Consider the expected number of bytes.
      switch status.kind.byteCount {

        case 3:
          // `data` is expected to contain the status byte and two data bytes.

          // Initialize `data2` with the third byte of the data provided.
          data2 = data[data.startIndex &+ 2]

        default:
          // `data` is only expected to contain the status byte and a data byte.

          // Initialize `data2` with a `nil` value.
          data2 = nil

      }

      // Initialize `time` with the specified bar-beat time.
      self.time = time

    }

    /// Initializing with kind and channel values for a `Status` value, the data bytes, and
    /// a bar-beat time.
    ///
    /// - Parameters:
    ///   - type: The `Status.Kind` value to use when initializing the new channel event's
    ///            `status` property.
    ///   - channel: The channel value to use when initializing the new channel event's
    ///              `status` property.
    ///   - data1: The first byte of data for the new channel event.
    ///   - data2: The optional second byte of data for the new channel event. The default
    ///            is `nil`.
    ///   - time: The tick offset represented as a bar-beat time. The default is `zero`.
    /// - Throws: `MIDIFile.Error.unsupportedEvent` when the `nil` status of `data2` does
    ///           not match the expected `nil` status as determined by the value of `type`.
    init(type: Status.Kind,
         channel: UInt8,
         data1: UInt8,
         data2: UInt8? = nil,
         time: MIDITimeStamp = 0) throws
    {

      // Consider the expected bytes for specified type.
      switch type.byteCount {

        case 3 where data2 == nil:
          // A second data byte is expected but not provided.

          // Create an error message.
          let message = "\(type) expects a second data byte but `data2` is `nil`."

          // Throw an `unsupportedEvent` error.
          throw MIDIFile.Error.unsupportedEvent(message)

        case 2 where data2 != nil:
          // A second data byte is provided but not expected.

          // Create an error message.
          let message = "\(type) expects a single data byte but `data2` is not `nil`."

          // Throw an `unsupportedEvent` error.
          throw MIDIFile.Error.unsupportedEvent(message)

        default:
          // The expected and provided bytes match.

          break

      }

      // Initialize `status` using the specified kind and channel.
      status = Status(kind: type, channel: channel)

      // Initialize `data1` with the specified byte.
      self.data1 = data1

      // Initialize `data2` with the specified byte.
      self.data2 = data2

      // Initialize `time` with the specified bar-beat time value.
      self.time = time

    }

    var description: String {

      // Create a string with the event's time and status values.
      var result = "\(time) \(status) "

      // Consider the kind of channel event.
      switch status.kind {

        case .noteOn, .noteOff:
          // The channel event is a 'note-on' or 'note-off' event.

          // Append the `MIDINote` and `Velocity` values created with the event's data.
          result += "note: \(data1) velocity: \(data2!)"

        default:
          // The channel event is not a 'note-on' or 'note-off' event.

          // Append the first byte of data.
          result += "\(data1)"

          // Check if there is a second byte of data.
          if let data2 = data2 {

            // Append the second byte of data.
            result += " \(data2)"
          }

      }

      return result

    }

    var hashValue: Int {

      // Return the bitwise XOR of hash values of the channel event's properties,
      // substituting `0` for any `nil` property values.
      return time.hashValue
           ^ (delta?.hashValue ?? 0)
           ^ status.hashValue
           ^ data1.hashValue
           ^ (data2?.hashValue ?? 0)

    }

    /// Returns `true` iff all property values of the two channel events are equal.
    static func ==(lhs: ChannelEvent, rhs: ChannelEvent) -> Bool {

      // Return the result of evaluating the properties of the two values for equality.
      return lhs.status == rhs.status
          && lhs.data1 == rhs.data1
          && lhs.time == rhs.time
          && lhs.data2 == rhs.data2
          && lhs.delta == rhs.delta

    }

    /// A structure representing a channel event's status byte.
    struct Status: Hashable, CustomStringConvertible {

      /// The kind of channel event specified by the status.
      var kind: Kind

      /// The MIDI channel specified by the status.
      var channel: UInt8

      /// The status byte for a MIDI transmission of a channel event with the status.
      var value: UInt8 {

        // Return a `UInt8` value whose four most significant bits are obtained from the
        // raw value for `kind` and whose four least significant bits are obtained from 
        // the value of `channel`.
        return (kind.rawValue << 4) | channel

      }

      var description: String { return "\(kind) (\(channel))" }

      var hashValue: Int {

        // Return the bitwise XOR of the hash values for `kind` and `channel`.
        return kind.hashValue ^ channel.hashValue

      }

      /// Initializing with the status byte of a channel event.
      ///
      /// - Parameter statusByte: The `UInt8` value containing the status byte of a 
      ///                         channel event MIDI transmission.
      /// - Throws: `MIDIFile.Error.unsupportedEvent` when the kind specified by
      ///           `statusByte` does not match the raw value for one of the cases in the
      ///           `Kind` enumeration.
      init(statusByte: UInt8) throws {

        // Initialize a `Kind` value using the four most significant bits shifted into the
        // four least significant bits.
        guard let kind = Status.Kind(rawValue: statusByte >> 4) else {

          // Create an error message.
          let message = "\(statusByte >> 4) is not a supported channel event."

          // Throw an `unsupportedEvent` error.
          throw MIDIFile.Error.unsupportedEvent(message)

        }

        // Initialize `kind` with the value initialized using `statusByte`.
        self.kind = kind

        // Initialize `channel` by masking `statusByte` to be within the range `0...15`.
        channel = statusByte & 0xF

      }

      /// Initializing with kind and channel values.
      /// 
      /// - Parameters:
      ///   - kind: The kind of channel event indicated by the new status value.
      ///   - channel: The channel value for the new status value.
      init(kind: Kind, channel: UInt8) {

        // Initialize `kind` with the specified value.
        self.kind = kind

        // Initialize `channel` with the specified value.
        self.channel = channel

      }

      /// Returns `true` iff the `value` values of the two status values are equal.
      static func ==(lhs: Status, rhs: Status) -> Bool {
        return lhs.value == rhs.value
      }

      /// An enumeration of the seven MIDI channel voice messages where the raw value of a
      /// case is equal to the four bit number stored in the four most significant bits of
      /// a channel event's status byte.
      enum Kind: UInt8 {

        /// Specifies a channel event containing a MIDI note to stop playing and a release
        /// velocity.
        case noteOff = 0x8

        /// Specifies a channel event containing a MIDI note to start playing and a 
        /// velocity.
        case noteOn = 0x9

        /// Specifies a channel event containing a MIDI note for polyphonic aftertouch and
        /// a pressure value.
        case polyphonicKeyPressure = 0xA

        /// Specifies a channel event containing a MIDI control and a value to apply.
        case controlChange = 0xB

        /// Specifies a channel event containing a MIDI program value.
        case programChange = 0xC

        /// Specifies a channel event containing a pressure value for channel aftertouch.
        case channelPressure = 0xD

        /// Specifies a channel event containing 'LSB' and 'MSB' pitch wheel values.
        case pitchBendChange = 0xE

        /// The total number of bytes in a channel event whose status byte's four most
        /// significant bits are equal to the kind's raw value. The value of this property
        /// will be `3` when a second data byte is expected and `2` otherwise.
        var byteCount: Int {

          // Consider the kind.
          switch self {

          case .controlChange, .programChange, .channelPressure:
            // The kind specifies a channel event expecting only one byte of data.

            return 2

          default:
            // The kind specifies a channel event expecting two bytes of data.

            return 3

          }

        }

      } // MIDIEvent.ChannelEvent.Status.Kind

    } // MIDIEvent.ChannelEvent.Status

  } // MIDIEvent.ChannelEvent

} // MIDIEvent

