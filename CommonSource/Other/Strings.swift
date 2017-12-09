//
//  Strings.swift
//  SignalProcessing
//
//  Created by Jason Cardwell on 9/22/17.
//  Copyright © 2017 Moondeer Studios. All rights reserved.
//

import Foundation

extension String {

  public enum Alignment { case left, center, right }

  public func padded(to length: Int, alignment: Alignment = .left) -> String {

    guard count < length else { return self }

    switch alignment {

    case .left:

      return self + " " * (length - count)

    case .center:

      return " " * ((length - count) / 2) + self + " " * ((length - count) - ((length - count) / 2))

    case .right:

      return " " * (length - count) + self

    }

  }

}
