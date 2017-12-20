//
//  main.swift
//  split_audio
//
//  Created by Jason Cardwell on 12/18/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation

let arguments = Arguments()

print(arguments)

let markers = getMarkers(from: arguments.inputFile)
print("total markers: \(markers.count)")

