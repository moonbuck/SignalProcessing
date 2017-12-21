//
//  SplitByMarker.swift
//  split_audio
//
//  Created by Jason Cardwell on 12/20/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation
import SignalProcessing
import AudioToolbox
import AVFoundation

//private typealias Marker = (position: AVAudioFramePosition, label: String)

func split(using markers: [CAFFile.Marker], and labels: [String]) throws {

  guard markers.count > 0 && labels.count >= markers.count else {
    print("Markers insufficient for splitting the audio file.")
    exit(EXIT_FAILURE)
  }

//  let markers: [Marker] = markers.filter({$0.type == kCAFMarkerType_Generic}).map {
//    (position: AVAudioFramePosition($0.framePosition), label: labels[Int($0.id - 1)])
//  }

  let genericMarkers = markers.filter({$0.type == kCAFMarkerType_Generic})

  let file = try AVAudioFile(forReading: arguments.inputURL)

  let totalSamples = AVAudioFrameCount(file.length)

  // Calculate the largest segment size.

  var maxSegmentSize: Float64 = 0
  var previousOffset = genericMarkers[0].framePosition.rounded()
  for index in 1 ..< genericMarkers.count {
    let nextOffset = genericMarkers[index].framePosition.rounded()
    let difference = nextOffset - previousOffset
    if difference > maxSegmentSize { maxSegmentSize = difference }
    previousOffset = nextOffset
  }


  guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat,
                                      frameCapacity: AVAudioFrameCount(maxSegmentSize))
    else
  {
    fatalError("Failed to allocate audio buffer.")
  }

  try autoreleasepool {

    for (index, marker) in genericMarkers.enumerated() {

      file.framePosition = AVAudioFramePosition(marker.framePosition)

      let sampleCount =
        genericMarkers.distance(from: index, to: genericMarkers.endIndex) == 1
          ? totalSamples - AVAudioFrameCount(marker.framePosition)
          : AVAudioFrameCount(genericMarkers[index + 1].framePosition - marker.framePosition)

      try file.read(into: buffer, frameCount: sampleCount)

      let label = labels[Int(marker.id) - 1]

      try write(buffer: buffer, for: label, settings: file.fileFormat.settings)

    }
  }

}

func split(using marker: [CAFFile.Marker]) throws {
  //TODO: Implement the  function
  fatalError("\(#function) not yet implemented.")
}

private func write(buffer: AVAudioPCMBuffer, for label: String, settings: [String:Any]) throws {

  var fileName = label.replacingOccurrences(of: "/", with: "_")
  if let suffix = arguments.fileNameSuffix { fileName += "_\(suffix)" }
  fileName += ".caf"

  let url = arguments.outputDirectory.appendingPathComponent(fileName)

  print("writing segment for marker labeled '\(label)' to '\(url)'...", terminator: "")



  let file = try AVAudioFile(forWriting: url, settings: settings)
  try file.write(from: buffer)

  print("finished")
  
}
