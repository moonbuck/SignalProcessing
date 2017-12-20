//
//  Parsing.swift
//  caf_info
//
//  Created by Jason Cardwell on 12/19/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import AudioToolbox

/// Opens the audio file at the specified URL.
///
/// - Parameter url: The URL for the audio file to open.
/// - Returns: The file ID for the opened audio file.
func openAudioFile(url: URL) -> AudioFileID {

  var file: AudioFileID?
  guard AudioFileOpenURL(url as CFURL, .readPermission, kAudioFileCAFType, &file) == noErr,
    let fileʹ = file
    else
  {
    print("Unable to open input audio file '\((url).path)'.")
    exit(EXIT_FAILURE)
  }

  return fileʹ

}


func getMarkers(from file: AudioFileID) -> [(marker: String, offset: Float64)] {

  var byteCount: UInt32 = 0
  AudioFileGetPropertyInfo(file, kAudioFilePropertyMarkerList, &byteCount, nil)

  let markerCount = NumBytesToNumAudioFileMarkers(Int(byteCount))
  guard markerCount > 0 else { return [] }

  let markerList = UnsafeMutablePointer<AudioFileMarkerList>.allocate(capacity: markerCount)
  defer { markerList.deallocate(capacity: markerCount) }
  AudioFileGetProperty(file, kAudioFilePropertyMarkerList, &byteCount, markerList)

  var markers: [(marker: String, offset: Float64)] = []

  withUnsafePointer(to: &markerList.pointee.mMarkers) {
    (pointer: UnsafePointer<AudioFileMarker>) -> Void in

    for index in 0 ..< markerCount {

      let marker = (pointer + index).pointee
      //      guard marker.mType == 0 else { continue }

      let framePosition = marker.mFramePosition
      guard let name = marker.mName?.takeUnretainedValue() else { continue }

      print(name as String)

      markers.append((marker: name as String, offset: framePosition))

    }

  }


  return markers

}

/// Checks that the specified bytes designate a valid CAF file header.
///
/// - Parameter data: The bytes to parse as a CAF file header.
/// - Returns: `true` if the parsed type is 'caff' and the parsed version is ≥ `1`,
///             and `false` otherwise.
func isValidCAFFile(data: Data) -> Bool {

  guard data.count == 8 else { fatalError("Invalid byte count for a file header.") }

//  let typeBytes = data[data.startIndex..<data.index(data.startIndex, offsetBy: 4)]
//  let typeScalars = String.UnicodeScalarView(typeBytes.map(UnicodeScalar.init))
//  let type = String(typeScalars)
  var startIndex = data.startIndex
  var endIndex = data.index(startIndex, offsetBy: 4)
  let type = String(data[startIndex ..< endIndex])

  guard type == "caff" else { return false }

  startIndex = data.index(startIndex, offsetBy: 4)
  endIndex = data.index(startIndex, offsetBy: 2)

  let version = UInt16(data[startIndex ..< endIndex])

  guard version > 0 else { return false }

  return true

}


