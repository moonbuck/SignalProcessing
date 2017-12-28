//
//  Split.swift
//  split_audio
//
//  Created by Jason Cardwell on 12/20/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import SignalProcessing
import AudioToolbox
import AVFoundation
import MoonKit

private var checkedDirectories: Set<URL> = []

/// Generates a URL for saving a new file given the segment label and the source.
///
/// - Parameters:
///   - label: The label for the segment being written to file.
///   - source: The source from which the segment was read.
/// - Returns: A URL for saving the segment to file.
private func urlForNewFile(label: String, source: CAFFile) -> URL {

  var suffix = ""

  if let regex = arguments.fileNameSuffixRegEx,
     let match = regex.firstMatch(in: source.url.lastPathComponent),
     match.captures.count > 1,
     let firstCapture = match.captures[1]
  {
    suffix = "_" + String(firstCapture.substring)
  } else if let suffixʹ = arguments.fileNameSuffix {
    suffix = "_" + suffixʹ
  }

  let legalCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ()#+")
  let illegalCharacters = legalCharacters.inverted

  let fileName = "\(label)\(suffix).caf".replacingCharacters(in: illegalCharacters, with: "_")

  let url: URL
  let root = arguments.outputDirectory

  if arguments.createSubdirectories {

    let subdirectoryName = source.url.deletingPathExtension().lastPathComponent + "-split"
    let subdirectory = root.appendingPathComponent(subdirectoryName, isDirectory: true)

    if !checkedDirectories.contains(subdirectory) {
      do {
        guard try checkDirectory(url: subdirectory, createDirectories: true) else {
          print("Unable to create subdirectory '\(subdirectoryName)'.")
          exit(EXIT_FAILURE)
        }
        checkedDirectories.insert(subdirectory)
      } catch {
        print("Error creating subdirectory '\(subdirectoryName)': \(error.localizedDescription)")
        exit(EXIT_FAILURE)
      }
    }

    url = subdirectory.appendingPathComponent(fileName)

  } else {

    url = root.appendingPathComponent(fileName)

  }

  return url

}

/// Writes a file segment to a new file.
///
/// - Parameters:
///   - buffer: The buffer to write to file.
///   - label: The marker label associated with the contents of `buffer`.
///   - source: The source for the segment.
///   - settings: The settings to pass to `AVAudioFile` on initialization.
/// - Throws: Any error thrown by `AVAudioFile.init(forWriting:settings:)`
private func write(buffer: AVAudioPCMBuffer,
                   for label: String,
                   source: CAFFile,
                   settings: [String:Any]) throws
{

  let url = urlForNewFile(label: label, source: source)

  let file = try AVAudioFile(forWriting: url, settings: settings)
  try file.write(from: buffer)

}

/// Extracts the list of markers and the list of strings from an instance of `CAFile`.
/// Prints a message and terminates the process if valid markers and labels are not found
/// in `file`.
///
/// - Parameter file: The file from which to extract the markers and labels.
/// - Returns: The markers and labels extracted from `file`.
private func getMarkersAndLabels(from file: CAFFile) -> (markers: [CAFFile.Marker],
                                                         labels: [String])
{

  guard let markers = file.markers?.data.markers,
        let labels = file.strings?.data.strings
    else
  {
    print("Labeled markers not found in the audio file has no markers.")
    exit(EXIT_FAILURE)
  }

  guard markers.count > 0 && labels.count >= markers.count else {
    print("Markers insufficient for splitting the audio file.")
    exit(EXIT_FAILURE)
  }

  return (markers: markers, labels: labels)

}

/// Splits a CAF file by using the file's labeled markers to segment the content.
///
/// - Parameter file: The file to split.
/// - Throws: Any error encountered while reading the source file or writing a segment.
func split(file: CAFFile) throws {

  if arguments.verbose {
    print("splitting file '\(file.url.lastPathComponent)'...", terminator: "")
  }

  let (markers, labels) = getMarkersAndLabels(from: file)

  let genericMarkers = markers.filter({$0.type == kCAFMarkerType_Generic})

  let audioFile = try AVAudioFile(forReading: file.url)

  let totalSamples = AVAudioFrameCount(audioFile.length)

  // Calculate the largest segment size.
  var maxSegmentSize: Float64 = 0
  var previousOffset = genericMarkers[0].framePosition.rounded()
  for index in 1 ..< genericMarkers.count {
    let nextOffset = genericMarkers[index].framePosition.rounded()
    let difference = nextOffset - previousOffset
    if difference > maxSegmentSize { maxSegmentSize = difference }
    previousOffset = nextOffset
  }


  guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat,
                                      frameCapacity: AVAudioFrameCount(maxSegmentSize))
    else
  {
    fatalError("Failed to allocate audio buffer.")
  }

  try autoreleasepool {

    for (index, marker) in genericMarkers.enumerated() {

      audioFile.framePosition = AVAudioFramePosition(marker.framePosition)

      let sampleCount =
        genericMarkers.distance(from: index, to: genericMarkers.endIndex) == 1
          ? totalSamples - AVAudioFrameCount(marker.framePosition)
          : AVAudioFrameCount(genericMarkers[index + 1].framePosition - marker.framePosition)

      try audioFile.read(into: buffer, frameCount: sampleCount)

      let label = labels[Int(marker.id) - 1]

      try write(buffer: buffer,
                for: label,
                source: file,
                settings: audioFile.fileFormat.settings)

    }
  }

  if arguments.verbose { print("finished") }

}


