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
  attr_reader :code_writer

  def run
    file_or_dir_name = File.basename(ARGV[0])
    # 出力対象のファイル名は渡されたファイル名 or ディレクトリ名から決定される
    output_file = File.new("#{file_or_dir_name.split(".").first}.asm", "w")
    @code_writer = CodeWriter.new(output_file)

    if FileTest::directory?(file_or_dir_name)
      parse_whole_files_in_dir(file_or_dir_name)
    else
      # 渡された引数がファイルの場合、そのファイルのみをパース対象とする
      parser = Parser.new(file_or_dir_name)
      @code_writer.set_file_name(file_or_dir_name)
      parse!(parser)
    end
  end

  def parse_whole_files_in_dir(dir_name)
    # 渡された引数がディレクトリの場合、そのディレクトリ内のすべてのファイルをパース対象とする
    entries = Dir::entries(dir_name).select do |e|
      file_path = "#{dir_name}/#{e}"
      File::ftype(file_path) == "file" && File.extname(file_path) == ".vm"
    end
    # Sys.vm が含まれている場合、その中にブートストラップ用のコマンドが書かれていると仮定して最初にパースする
    if entries.include?("Sys.vm")
      sys_vm_path = "#{dir_name}/Sys.vm"
      parser = Parser.new(sys_vm_path)
      @code_writer.set_file_name(sys_vm_path)
      parse!(parser)
      entries.delete("Sys.vm")
    end

    entries.each do |file_name|
      parser = Parser.new("#{dir_name}/#{file_name}")
      @code_writer.set_file_name(file_name)
      parse!(parser)
    end
  end

  def parse!(parser)
    parser.file_contents.size.times do
      parser.advance
      current_command = parser.current_command
      command, segment, index = current_command.split(" ")

      case parser.command_type
      when Parser::C_ARITHMETIC
        @code_writer.write_arithmetic(current_command)
      when Parser::C_PUSH, Parser::C_POP
        command, segment, index = current_command.split(" ")
        @code_writer.write_push_pop(command, segment, index)
      when Parser::C_LABEL
        @code_writer.write_label(segment)
      when Parser::C_IF
        @code_writer.write_if(segment)
      when Parser::C_GOTO
        @code_writer.write_goto(segment)
      when Parser::C_FUNCTION
        @code_writer.write_function(segment, index)
      when Parser::C_RETURN
        @code_writer.write_return
      when Parser::C_CALL
        @code_writer.write_call(segment, index)
      else raise StandardError.new("Can't parse!")
      end
    end
  end
end

VM.new.run
