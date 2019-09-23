# RAM[0] SP スタックポインタ：スタックの最上位の次を指す。 
# RAM[1]     LCL  現在のVM関数におけるlocalセグメントの ベースアドレスを指す。 
# RAM[2]     ARG  現在のVM関数におけるargumentセグメントの ベースアドレスを指す。 
# RAM[3]     THIS 現在の（ヒープ内における）thisセグメントの ベースアドレスを指す。 
# RAM[4]     THAT 現在の（ヒープ内における）thatセグメントの ベースアドレスを指す。 
# RAM[5–12]       tempセグメントの値を保持する。 
# RAM[13–15]      汎用的なレジスタとしてVM実装で用いることができる。

# RAM[0]: 259
# RAM[1]: 300
# RAM[2]: 400
# RAM[3]: 3000
# RAM[4]: 3010

class CodeWriter
  attr_reader :out_file, :stack_point
  # |  RAM[0]  | RAM[256] | RAM[257] | RAM[258] | RAM[259] | RAM[260] |
  # |     266  |      -1  |       0  |       0  |       0  |      -1  |
  # | RAM[261] | RAM[262] | RAM[263] | RAM[264] | RAM[265] |
  # |       0  |      -1  |       0  |       0  |     -91  |

  START_OF_TEMP_ADDRESS = 5

  # 出力ファイル/ストリームを開き、 書き込む準備を行う
  def initialize(out_file)
    @out_file = out_file
    @file_name = out_file.path
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
  end

  # CodeWriter モジュールに新しい VM ファイルの変換が開始したことを知らせる 
  def set_file_name(file_name)
  end

  # 与えられた算術コマンドをアセンブリコードに変換し、それを書き込む
  def write_arithmetic(command)
    @out_file.puts("// START: #{command}")

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

    @out_file.puts("// END: #{command}")
  end

  def write_add_sub_and_or_command(operator)
    # オペレータの右辺の値を取り出してDレジスタにセット
    pop_from_stack_to_d_register("M")

    # オペレータの左辺の値を取り出してDレジスタにセット
    pop_from_stack_to_d_register("M#{operator}D")

    # 計算結果をもともと左辺が格納されていたアドレスに格納する
    put_value_on_stack_of("D")

    # 最後にSPの値をインクリメントする
    increment_sp_address
  end

  def write_neg_or_not_command(operator)
    # 計算対象の値を取り出して計算結果を格納する
    @out_file.puts("@SP")
    @out_file.puts("M=M-1")
    @out_file.puts("A=M")
    @out_file.puts("M=#{operator}M")

    # 最後にSPの値をインクリメントする
    increment_sp_address
  end

  def write_comparison_command(comparison_mnemonic)
    count_var_name = "@#{comparison_mnemonic.downcase}_count"
    count = eval(count_var_name)

    # オペレータの右辺の値を取り出してDレジスタにセット
    pop_from_stack_to_d_register("M")

    # オペレータの左辺の値を取り出してDレジスタにセット
    # D レジスタには (左辺 - 右辺) の計算結果を格納する
    pop_from_stack_to_d_register("M-D")

    # 左辺と右辺が等しかったらジャンプ
    @out_file.puts("@TRUE_ADDRESS_#{comparison_mnemonic}#{count}")
    @out_file.puts("D;#{comparison_mnemonic}")

    # falseだったらジャンプせずに処理続行
    # 計算結果をもともと左辺が格納されていたアドレスに格納する
    # PUSH
    put_value_on_stack_of("0")
    @out_file.puts("@END_ADDRESS_#{comparison_mnemonic}#{count}")
    @out_file.puts("0;JMP")

    # 論理演算の結果がtrueだった時のジャンプ先のラベル
    @out_file.puts("(TRUE_ADDRESS_#{comparison_mnemonic}#{count})")
    # 計算結果をもともと左辺が格納されていたアドレスに格納する
    put_value_on_stack_of("-1")

    # if文のendに相当するラベル
    @out_file.puts("(END_ADDRESS_#{comparison_mnemonic}#{count})")

    # 最後にSPの値をインクリメントする
    increment_sp_address

    eval("#{count_var_name} += 1")
  end

  def write_and_command
  end

  # 引数: （C_PUSH または C_POP）、 segment（文字列）、 index（整数）
  # 
  # C_PUSH またはC_POPコマンド をアセンブリコードに変換し、それを書き込む
  def write_push_pop(command, segment, index)
    @out_file.puts("// START: write_push_pop")
    @out_file.puts("// #{command}, #{segment}, #{index}")

    case command
    when "push" then write_push_command(segment, index)
    when "pop" then write_pop_command(segment,index)
    end

    @out_file.puts("// END: write_push_pop")
  end

  def write_pop_command(segment, index)
    seg_label = segment_label(segment, index)
    @out_file.puts("// write_push_pop: pop #{seg_label}")
    # スタックからPOPする
    pop_from_stack_to_d_register("M")
    # @13はPOPした値の一時退避用のアドレス
    @out_file.puts("@13")
    @out_file.puts("M=D")

    @out_file.puts("@#{index}")
    @out_file.puts("D=A")
    @out_file.puts("@#{seg_label}")

    # POP先の絶対アドレスをDに格納する
    expression = case segment
    # segment == temp の場合のラベルが存在しないのでアドレスを直接指定するスタイル
    when "temp" then "D=D+A"
    when "pointer", "static" then "D=A"
    else "D=D+M"
    end
    @out_file.puts(expression)

    # @14はPOP先のアドレスの一時退避用のアドレス
    @out_file.puts("@14")
    @out_file.puts("M=D")
    @out_file.puts("@13")
    @out_file.puts("D=M")
    @out_file.puts("@14")
    @out_file.puts("A=M")
    @out_file.puts("M=D")
  end

  def write_push_command(segment, index)
    case segment
    when "local" ,"argument" ,"this" ,"that", "temp", "pointer", "static"
      seg_label = segment_label(segment, index)
      @out_file.puts("@#{index}")
      @out_file.puts("D=A")
      @out_file.puts("@#{seg_label}")

      expression = case segment
      when "temp" then "D=A+D"
      when "pointer" then "D=A"
      when "static" then "D=A"
      else "D=M+D"
      end
      @out_file.puts(expression)

      # PUSH対象のアドレスから値を取り出す
      @out_file.puts("A=D")
      @out_file.puts("D=M")

      # SPが指すアドレスに値を格納
      put_value_on_stack_of("D")

      # 最後にSPの値をインクリメントする
      increment_sp_address
    when "constant"
      # Dレジスタに定数をセット
      @out_file.puts("@#{index}")
      @out_file.puts("D=A")

      # SPが指すアドレスに値を格納
      put_value_on_stack_of("D")

      # 最後にSPの値をインクリメントする
      increment_sp_address
    end
  end

  # 現在のSPが指すアドレスに register で指定された値を格納する
  def put_value_on_stack_of(register)
    @out_file.puts("@SP")
    @out_file.puts("A=M")
    @out_file.puts("M=#{register}")
  end

  # SPの値をインクリメントする
  # PUSH 操作を行った後に呼ばれる
  def increment_sp_address
    @out_file.puts("@SP")
    @out_file.puts("M=M+1")
  end

  # expressionには D, D-1, D+M などの文字列が渡されることを期待している
  def pop_from_stack_to_d_register(expression)
    @out_file.puts("@SP")
    @out_file.puts("M=M-1")
    @out_file.puts("A=M")
    @out_file.puts("D=#{expression}")
  end

  def write_init
    @out_file.puts("Sys.init")
    raise NotImplementedError.new("write_init")
  end

  def write_label(label)
    # lebel コマンドを行うアセンブリコードを書く
    @out_file.puts("(#{label})")
  end

  def write_if(label)
    pop_from_stack_to_d_register("M")
    @out_file.puts("@#{label}")
    @out_file.puts("D;JGT")
  end

  def write_goto(label)
    @out_file.puts("@#{label}")
    @out_file.puts("0;JMP")
  end

  def write_call(function_name, num_args)
    # Not implemented
  end

  def write_return
    frame_address = 13
    return_address = 14
    # FRAME = LCL # FRAMEは一時変数
    @out_file.puts("@LCL")
    @out_file.puts("D=M")
    @out_file.puts("@#{frame_address}")
    @out_file.puts("M=D")

    # RET = *(FRAME-5) # なんのための-5なのかをはっきりさせる
    #                  # 一時変数に保存されている
    #                  # リターンアドレスを取得する
    @out_file.puts("@#{frame_address}")
    @out_file.puts("D=M")
    @out_file.puts("@5")
    @out_file.puts("D=D-A")
    @out_file.puts("A=D")
    @out_file.puts("D=M")
    @out_file.puts("@#{return_address}")
    @out_file.puts("M=D")
    # *ARG = pop() # 関数の呼び出し側のために、
    #              # 関数の戻り値を別の場所へ移す
    pop_from_stack_to_d_register("M")
    @out_file.puts("@ARG")
    @out_file.puts("A=M") # TODO:
    @out_file.puts("M=D")
    # SP = ARG+1 # 呼び出し側のSPを戻す
    @out_file.puts("@ARG")
    @out_file.puts("D=M")
    @out_file.puts("@SP")
    @out_file.puts("M=D+1")
    %w[THAT THIS ARG LCL].each.with_index(1) do |sym, i|
      # THAT = *(FRAME-1) # 呼び出し側のTHATを戻す
      # THIS = *(FRAME-2) # 呼び出し側のTHISを戻す
      # ARG = *(FRAME-3)
      # LCL = *(FRAME-4)
      @out_file.puts("@#{frame_address}")
      @out_file.puts("D=M")
      @out_file.puts("@#{i}")
      @out_file.puts("D=D-A")
      @out_file.puts("A=D")
      @out_file.puts("D=M")
      @out_file.puts("@#{sym}")
      @out_file.puts("M=D")
    end

    # goto RET
    @out_file.puts("@#{return_address}")
    @out_file.puts("A=M")
    @out_file.puts("0;JMP")
  end

  def write_function(function_name, nums_local)
    @out_file.puts("// START write_function: #{function_name}, #{nums_local}")

    @out_file.puts("(#{function_name})")
    nums_local.to_i.times do |num|
      # 現在のLCLのアドレス+numのアドレスを0で初期化
      @out_file.puts("@LCL")
      @out_file.puts("D=M")
      @out_file.puts("@#{num}")
      @out_file.puts("A=D+A")
      @out_file.puts("M=0")
    end

    @out_file.puts("// END write_function")
  end

  # 対象とすべきラベル群
  def segment_label(segment, index)
    # LCLの相対アドレスをAレジスタに設定してそこにDレジスタに登録した値を設定する
    case segment
    when "local" then "LCL"
    when "argument" then "ARG"
    when "this" then "THIS"
    when "that" then "THAT"
    when "temp" then START_OF_TEMP_ADDRESS
    when "pointer"
      case index
      when "0" then "THIS"
      when "1" then "THAT"
      end
    when "static"
      "#{@file_name.split(".").first}.#{index}"
    end
  end

  # 出力ファイルを閉じる
  def close
  end
end
