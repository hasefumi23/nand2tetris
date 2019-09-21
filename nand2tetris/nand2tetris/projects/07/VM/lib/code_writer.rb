class CodeWriter
  attr_reader :out_file, :stack_point
  # |  RAM[0]  | RAM[256] | RAM[257] | RAM[258] | RAM[259] | RAM[260] |
  # |     266  |      -1  |       0  |       0  |       0  |      -1  |
  # | RAM[261] | RAM[262] | RAM[263] | RAM[264] | RAM[265] |
  # |       0  |      -1  |       0  |       0  |     -91  |

  # 出力ファイル/ストリームを開き、 書き込む準備を行う
  def initialize(out_file)
    @out_file = out_file
    @stack_point = 256 # ~ 2047
    @heap = 2048 # ~ 16383
    @memory_mapped_io = 16384 # ~ 24575
    # 24576–32767: 使用しない

    @jgt_count = 0
    @jeq_count = 0
    @jge_count = 0
    @jlt_count = 0
    @jne_count = 0
    @jle_count = 0
    @jmp_count = 0

    # 初期化時に各レジスタを設定するためのコマンドを書き込む
    @out_file.puts("@#{stack_point}")
    @out_file.puts("D=A")
    @out_file.puts("@SP")
    @out_file.puts("M=D")
  end

  # CodeWriter モジュールに新しい VM ファイルの変換が開始したことを知らせる 
  def set_file_name(file_name)
  end

  # 与えられた算術コマンドをアセンブリコードに変換し、それを書き込む
  def write_arithmetic(command)
    case command
    when "add" then write_add_sub_and_or_command("+")
    when "sub" then write_add_sub_and_or_command("-")
    when "neg" then write_neg_or_not_command("-")
    when "eq" then write_comparison_command("JEQ")
    when "gt" then write_comparison_command("JGT")
    when "lt" then write_comparison_command("JLT")
    when "and" then write_add_sub_and_or_command("&")
    when "or" then write_add_sub_and_or_command("|")
    when "not" then write_neg_or_not_command("!")
    end
  end

  def write_add_sub_and_or_command(operator)
    point_x = @stack_point - 2
    @out_file.puts("@#{point_x}")
    @out_file.puts("D=M")

    point_y = @stack_point -1
    @out_file.puts("@#{point_y}")
    @out_file.puts("D=D#{operator}M")

    @out_file.puts("@#{point_x}")
    @out_file.puts("M=D")

    after_arithmetic_command
  end

  def write_neg_or_not_command(operator)
    point_y = @stack_point -1
    @out_file.puts("@#{point_y}")
    @out_file.puts("M=#{operator}M")
  end

  def write_comparison_command(comparison_mnemonic)
    count_var_name = "@#{comparison_mnemonic.downcase}_count"
    count = eval(count_var_name)

    # @RET_ADDRESS_LT0
    point_x = @stack_point - 2
    @out_file.puts("@#{point_x}")
    @out_file.puts("D=M")

    point_y = @stack_point -1
    @out_file.puts("@#{point_y}")
    @out_file.puts("D=D-M")

    # x と yが等しかったらジャンプ
    @out_file.puts("@TRUE_ADDRESS_#{comparison_mnemonic}#{count}")
    @out_file.puts("D;#{comparison_mnemonic}")

    # falseだったらジャンプせずに処理続行
    @out_file.puts("@#{point_x}")
    @out_file.puts("M=0")
    @out_file.puts("@END_ADDRESS_#{comparison_mnemonic}#{count}")
    @out_file.puts("0;JMP")

    # 論理演算の結果がtrueだった時のジャンプ先のラベル
    @out_file.puts("(TRUE_ADDRESS_#{comparison_mnemonic}#{count})")
    @out_file.puts("@#{point_x}")
    @out_file.puts("M=-1")

    # if文のendに相当するラベル
    @out_file.puts("(END_ADDRESS_#{comparison_mnemonic}#{count})")

    # @jeq_count += 1
    eval("#{count_var_name} += 1")
    after_arithmetic_command
  end

  def write_and_command
  end

  # 算術コマンド実行後にStackPointの値を-1してSPレジスタに設定する
  def after_arithmetic_command
    @stack_point -= 1
    @out_file.puts("@#{stack_point}")
    @out_file.puts("D=A")
    @out_file.puts("@SP")
    @out_file.puts("M=D")
  end

  # 引数: （C_PUSH または C_POP）、 segment（文字列）、 index（整数）
  # 
  # C_PUSH またはC_POPコマンド をアセンブリコードに変換し、それを書き込む
  def write_push_pop(command, segment, index)
    case segment
    when "constant"
      @out_file.puts("@#{index}")
      @out_file.puts("D=A")
      @out_file.puts("@#{stack_point}")
      @out_file.puts("M=D")
      @stack_point += 1
    end
  end

  # 出力ファイルを閉じる
  def close
  end
end
