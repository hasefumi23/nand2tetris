#!/usr/bin/env ruby

# VMからHackへ変換する変換器を書くこと
# この変換器は7.2節の「VM仕様（第 1部）」と7.3.1節の「Hackプラットフォームの標準VMマッピング（第1部）」を満 たさなければならない

# VMコマンドは次のフォーマットのいずれかに該当する。
# command（例：add） 
# command arg（例：goto LOOP） 
# command arg1 arg2（例：push local 3）

# push segment index 
# - segment[index]をスタックの上にプッシュする
# pop segment index
# - スタックの一番上のデータをポップし、それをsegment[index]に格納する

# function add(arg1, arg2) {
#   x = arg1
#   y = arg2
#   return x + y
# }
# 
# x = arg1 は以下の2つのVMコマンドで表現される
# push argument 0
# pop local 1
# 
# さらにアセンブリ言語では以下のようになる。。。はず
# @arg1
# D=M
# @x
# M=D+M

# 0–15: 16個の仮想レジスタ、使い方はすぐ後に示す
# 16–255: （VMプログラムのすべてのVM関数における）スタティック変数
# 256–2047: スタック
# 2048–16383: ヒープ（オブジェクトと配列を格納する）
# 16384–24575: メモリマップドI/O
# 24576–32767: 使用しないメモリ空間

require_relative "./parser"
require_relative "./code_writer"

class VM
  def self.run
    file_name = File.basename(ARGV[0])
    output_file = File.new("#{file_name.split(".").first}.asm", "w")
    code_writer = CodeWriter.new(output_file)
    parser = Parser.new(file_name)
    parser.file_contents.size.times do
      parser.advance
      current_command = parser.current_command
      case parser.command_type
      when Parser::C_ARITHMETIC
        code_writer.write_arithmetic(current_command)
      when Parser::C_PUSH, Parser::C_POP
        command, segment, index = current_command.split(" ")
        code_writer.write_push_pop(command, segment, index)
      end
    end
  end
end

VM.run
