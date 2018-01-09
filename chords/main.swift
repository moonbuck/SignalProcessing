//
//  main.swift
//  chords
//
//  Created by Jason Cardwell on 1/6/18.
//  Copyright © 2018 Moondeer Studios. All rights reserved.
//
import Foundation
import SignalProcessing


let arguments = Arguments()

switch arguments.command {

case .name, .index:
  guard let pattern = arguments.pattern else {
    fatalError("Expected a pattern or an early exit.")
  }

  if let root = arguments.root {
    dumpInfo(for: pattern, with: root)
  } else {
    dumpInfo(for: pattern)
  }

case .help:
  fatalError("Expected an early exit.")

}
