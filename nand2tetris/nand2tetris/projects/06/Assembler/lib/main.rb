#!/usr/bin/env ruby

require_relative './parser.rb'
require_relative './code.rb'

class Main
  def self.run
    raise "アセンブル対象のファイル名を一つだけ指定してください" if ARGV.size != 1

    file_name = File.basename(ARGV[0])
    parser = Parser.new(file_name)
    File.open("#{file_name.split(".").first}.hack", "w") do |f|
      while parser.hasMoreCommands?
        parser.advance

        begin
          if parser.a_command?
            f.puts parser.symbol
          elsif parser.c_command?
            comp = Code.comp(parser.comp)
            dest = Code.dest(parser.dest)
            jump = Code.jump(parser.jump)

            command = "111#{comp}#{dest}#{jump}"
            f.puts command
          end
        rescue => exception
          puts exception.inspect
          puts parser.inspect
          raise exception
        ensure
        end
      end
    end
  end
end

Main.run
