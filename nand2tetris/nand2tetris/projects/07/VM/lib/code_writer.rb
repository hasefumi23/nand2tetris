class CodeWriter
  attr_reader :out_file, :stack_point

  # 出力ファイル/ストリームを開き、 書き込む準備を行う
  def initialize(out_file)
    @out_file = out_file
    @stack_point = 256 # ~ 2047
    @heap = 2048 # ~ 16383
    @memory_mapped_io = 16384 # ~ 24575
    # 24576–32767: 使用しない

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
    when "add"
      point_x = @stack_point - 2
      @out_file.puts("@#{point_x}")
      @out_file.puts("D=M")

      point_y = @stack_point -1
      @out_file.puts("@#{point_y}")
      @out_file.puts("D=M+D")

      @out_file.puts("@#{point_x}")
      @out_file.puts("M=D")

      @stack_point -= 1
      @out_file.puts("@#{stack_point}")
      @out_file.puts("D=A")
      @out_file.puts("@SP")
      @out_file.puts("M=D")
    end
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
