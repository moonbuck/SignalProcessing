//
//  Windower.swift
//  SignalProcessing
//
//  Created by Jason Cardwell on 10/2/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//
import Foundation

public protocol Windower {

  var length: Int { get }

  func cut(buffer: Float64Buffer)
  func cut(source: Float64Buffer, destination: Float64Buffer)

}
