//
//  main.swift
//  caf_info
//
//  Created by Jason Cardwell on 12/19/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import MoonKit
import SignalProcessing

let arguments = Arguments()

let file: CAFFile

do {
  guard let fileʹ = try CAFFile(url: arguments.inputURL) else {
    print("The specified file is not a valid CAF file.")
    exit(EXIT_FAILURE)
  }
  file = fileʹ
} catch {
  print("Error reading from '\(arguments.inputURL.path)': \(error.localizedDescription)")
  exit(EXIT_FAILURE)
}

var isTrailing = false

if arguments.dumpMarkers {

  if let markersChunk = file.markers {

    let strings = file.strings?.data.strings

    print("""
      Markers found in '\(arguments.inputURL.lastPathComponent)' \
      (time type = \(markersChunk.data.timeTypeDescription)):
      """)

    let markers = markersChunk.data.markers

    let maxIndex = markers.count.description.count
    let maxType = markers.map(\.typeDescription.count).max() ?? 0
    let maxPosition = (markers.map(\.framePosition).max() ?? 0).description.count
    let maxID = (markers.map(\.id).max() ?? 0).description.count
    let maxTime = markers.map(\.timeDescription.count).max() ?? 0
    let maxChannel = (markers.map(\.channel).max() ?? 0).description.count

    for (markerIndex, marker) in markers.enumerated() {

      let index = markerIndex.description.padded(to: maxIndex, alignment: .right)
      let type = marker.typeDescription.padded(to: maxType, alignment: .right)
      let position = marker.framePosition.description.padded(to: maxPosition, alignment: .right)
      let id = marker.id.description.padded(to: maxID, alignment: .right)
      let time = marker.timeDescription.padded(to: maxTime, alignment: .right)
      let channel = marker.channel.description.padded(to: maxChannel, alignment: .right)

      print("""
        [\(index)]  Marker { type: \(type)  position: \(position)  id: \(id)  time: \(time)  \
        channel: \(channel) }  '\(strings?[Int(marker.id - 1)] ?? "")'
        """)

    }

  } else {

    print("No markers were found in '\(arguments.inputURL.lastPathComponent)'")

  }

  isTrailing = true

}

if arguments.dumpStrings {

  if isTrailing { print("") }

  if let stringsChunk = file.strings {

    print("Strings found in '\(arguments.inputURL.lastPathComponent)':")

    let strings = stringsChunk.data.strings
    let ids = stringsChunk.data.ids

    let maxIndex = strings.count.description.count
    let maxID = (ids.map(\.id).max() ?? 0).description.count
    let maxOffset = (ids.map(\.startByteOffset).max() ?? 0).description.count

    for (index, (stringID, string)) in zip(ids, strings).enumerated() {

      let indexʹ = index.description.padded(to: maxIndex, alignment: .right)
      let id = stringID.id.description.padded(to: maxID, alignment: .right)
      let offset = stringID.startByteOffset.description.padded(to: maxOffset, alignment: .right)

      print("[\(indexʹ)]  String { id: \(id)  offset: \(offset) }  '\(string)'")

    }

  } else {

    print("No strings were found in '\(arguments.inputURL.lastPathComponent)'")

  }

  isTrailing = true

}

if arguments.dumpStructure {

  if isTrailing { print("") }

  print("\(file)")

  isTrailing = true

}

if arguments.dumpAudioDescription {

  if isTrailing { print("") }

  let audioDescription = file.audioDescription.data

  let precision = audioDescription.formatFlags.isFloat ? "float" : "int"
  let endianness = audioDescription.formatFlags.isLittleEndian ? "little-endian" : "big-endian"

  print("""
    Audio description contained by '\(arguments.inputURL.lastPathComponent)':
    sample rate: \(audioDescription.sampleRate)
    format ID: \(audioDescription.formatID.stringValue)
    sample values: (\(precision), \(endianness))
    bytes per packet: \(audioDescription.bytesPerPacket)
    frames per packet: \(audioDescription.framesPerPacket)
    channels per frame: \(audioDescription.channelsPerFrame)
    bits per channel: \(audioDescription.bitsPerChannel)
    """)

  isTrailing = true

}

if arguments.dumpChannelLayout {

  if isTrailing { print("") }

  if let channelLayout = file.channelLayout {

    let channels = channelLayout.data.bitmapDescription
                     .dropFirst().dropLast() .split(separator: "|").joined(separator: ", ")

    print("""
      Channel layout contained by '\(arguments.inputURL.lastPathComponent)':
      type: \(channelLayout.data.layoutTagDescription)
      channels: \(channels)
      """)

    let descriptions = channelLayout.data.descriptions

    if !descriptions.isEmpty {

      print("channel descriptions:")

      let maxIndex = descriptions.count.description.count
      let maxLabel = descriptions.map(\.labelDescription.count).max() ?? 0
      let maxFirst = descriptions.map({$0.coordinates.0.description.count}).max() ?? 0
      let maxSecond = descriptions.map({$0.coordinates.1.description.count}).max() ?? 0
      let maxThird = descriptions.map({$0.coordinates.2.description.count}).max() ?? 0

      for (channelIndex, description) in channelLayout.data.descriptions.enumerated() {
        let index = channelIndex.description.padded(to: maxIndex, alignment: .right)
        let label = description.labelDescription.padded(to: maxLabel, alignment: .right)
        let units = (description.flags.contains(.meters)
                       ? "Meters"
                       : "Relative").padded(to: 8, alignment: .right)
        let coordinateKind = (description.flags.contains(.sphericalCoordinates)
                                ? "Spherical"
                                : "Rectangular").padded(to: 11, alignment: .right)
        let first = description.coordinates.0.description.padded(to: maxFirst, alignment: .right)
        let second = description.coordinates.1.description.padded(to: maxSecond, alignment: .right)
        let third = description.coordinates.2.description.padded(to: maxThird, alignment: .right)
        print("""
          [\(index)]  Channel { label: \(label)  units: \(units)  kind: \(coordinateKind)  \
          coordinates: (\(first), \(second), \(third)) }
        """)

      }

    }

  } else {

    print("""
      Channel layout in '\(arguments.inputURL.lastPathComponent)' is assumed to be \
      \(file.audioDescription.data.channelsPerFrame == 2 ? "stereo" : "mono")
      """)

  }

}
