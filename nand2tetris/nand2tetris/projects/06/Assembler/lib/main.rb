#!/usr/bin/env ruby

require_relative './parser.rb'

class Main
  def self.run
    parser = Parser.new('Prog.asm')
    while parser.hasMoreCommands?
      parser.advance
      p "CC: "
      p parser.current_command
    end
  end
end
