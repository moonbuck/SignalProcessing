//
//  Arguments.swift
//  chords
//
//  Created by Jason Cardwell on 1/6/18.
//  Copyright © 2018 Moondeer Studios. All rights reserved.
//
import Foundation
import func Docopt.parse
import SignalProcessing
import Schema

prefix operator >> // Use
prefix operator ∈  // Type
prefix operator ∀  // Pred
prefix operator ⊆  // List
prefix operator ⊨  // Dict
prefix operator ~/ // Regex

let chordsUsage = """
Usage: chords [options] <command> [<args>...]

Arguments:
  <command>  The command to execute
  <args>     One or more arguments to pass through to <command>

Options:
  --with-root=<root>  A note to use as the chord's root interval
  --pitches           Only print the pitches to stdout.

The commands are:
  index  Lookup via pattern index.
  name   Lookup via pattern name.
  help   View command-specific usage
"""

let indexUsage = """
Usage: chords index <idx>

Arguments:
<idx>  The index of the pattern to lookup. (0-73)

"""

let nameUsage = """
Usage: chords name <name>

Arguments:
  <name>  The name of the pattern to lookup. This takes the form of a chord name minus the root.

"""

let helpUsage = """
Usage: chords help <command>

Arguments:
<command>  The command for which usage should be displayed.

"""

enum Command: String {
  case index, name, help
}

struct Arguments: CustomStringConvertible {

  let command: Command
  let root: Pitch?
  let pitchesOnly: Bool
  let pattern: ChordPattern?

  init() {

    let schema = Schema([
      "<command>": >>Command.init(rawValue:),
      "--with-root": ∈NSNull.self || (∈String.self && >>Pitch.init(stringValue:)),
      "--pitches": ∈NSNumber.self,
      "<args>": ∈[String].self
      ], ignoreExtras: true)

    let arguments: [String:Any]

    do {
      arguments = try schema.validate(parse(chordsUsage, optionsFirst: true))
    } catch {
      print("Error:", error)
      print(chordsUsage)
      exit(1)
    }

    let command = arguments["<command>"] as! Command
    self.command = command
    self.root = arguments["--with-root"] as? Pitch
    self.pitchesOnly = (arguments["--pitches"] as! NSNumber).boolValue
    
    let argv = [command.rawValue] + (arguments["<args>"] as! [String])

    do {

      switch command {

        case .index:

          let schema = Schema([
            "<idx>": (∈Int.self && ∀{$0 >= 0 && $0 <= 74})
                     && >>{(i:Int) -> ChordPattern in ChordPattern.all[i]}
            ], ignoreExtras: true)

          let arguments: [String:Any] = try schema.validate(parse(indexUsage, argv: argv))

          pattern = (arguments["<idx>"] as! ChordPattern)

        case .name:

          let schema = Schema([
            "<name>": >>ChordPattern.init(suffix:)
            ], ignoreExtras: true)

          let arguments: [String:Any] = try schema.validate(parse(nameUsage, argv: argv))

          pattern = (arguments["<name>"] as! ChordPattern)

        case .help:

          let schema = Schema(["<command>": >>Command.init(rawValue:)], ignoreExtras: true)
          let arguments: [String:Any] = try schema.validate(parse(helpUsage, argv: argv))

          switch arguments["<command>"] as! Command {
              case .index: print(indexUsage); exit(0)
              case .name: print(nameUsage); exit(0)
              case .help: print(helpUsage); exit(0)
          }

      }

    } catch {
      print("Error:", error)
      print(chordsUsage)
      exit(1)
    }
  }

  var description: String {

    return """
      command: \(command)
      root: \(root?.description ?? "nil")
      pattern: \(pattern?.description ?? "nil")
      """

  }

}
