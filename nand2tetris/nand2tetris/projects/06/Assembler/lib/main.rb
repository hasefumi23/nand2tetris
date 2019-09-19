#!/usr/bin/env ruby

require 'pry'

require_relative './parser.rb'
require_relative './code.rb'
require_relative './symbol_table.rb'

class Main
  def self.run
    raise "アセンブル対象のファイル名を一つだけ指定してください" if ARGV.size != 1

    file_name = File.basename(ARGV[0])
    sym_table = SymbolTable.new
    parser = Parser.new(file_name)

    # 1回目はラベルとアドレスの対応付のための処理のみ実行する
    command_position = 0
    parser.file_contents.size.times do
      parser.advance

      if parser.l_command?
        sym_table.add_entry(parser.current_command[1..-2], command_position)
      else
        command_position += 1
      end
    end

    parser.file_contents = parser.file_contents.reject { |c| Parser::l_command?(c) }
    parser.reset_commnad_position!

    # 2回目は変換処理を実行する
    memory_address = 16
    File.open("#{file_name.split(".").first}.hack", "w") do |f|
      parser.file_contents.size.times do |command_position|
        parser.advance

        begin
          if parser.a_command?
            if parser.symbol.start_with?(/\d/)
              f.puts parser.sym_to_b
            else
              if address = sym_table.address_by_symbol(parser.symbol)
                f.puts Parser::convert_number_to_binary(address)
              else
                sym_table.add_entry(parser.symbol, memory_address)
                f.puts Parser::convert_number_to_binary(memory_address)
                memory_address += 1
              end
            end
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
