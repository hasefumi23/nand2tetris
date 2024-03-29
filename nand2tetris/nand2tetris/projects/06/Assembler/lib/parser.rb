class Parser
  class AssemblerSyntaxError < StandardError; end

  attr_accessor :file_contents
  attr_reader :current_command, :current_index

  # は@Xxxを意味し、Xxx はシンボルか 10 進数の数値である
  A_COMMAND = "A_COMMAND"
  # はdest=comp;jump を意味する
  C_COMMAND = "C_COMMAND"
  # は擬似コマンドであり、 (Xxx) を意味する。Xxx はシンボル である
  L_COMMAND = "L_COMMAND"

  def self.convert_number_to_binary(num)
    "0#{format("%.15b", num.to_i)}"
  end

  def initialize(file_name)
    @current_index = 0
    # 入力ファイル/ストリームを開きパースを 行う準備をする
    @file_contents = IO.readlines(file_name, chomp: true).map do |row|
      # コメント部分を削除する
      row.gsub(/\/\/.*/, "").strip
    end.compact.reject { |e| e.empty? }
  end

  def reset_commnad_position!
    @current_index = 0
  end

  def hasMoreCommands?
    # 入力にまだコマンドが存在するか？
    @file_contents.size > @current_index
  end

  def advance
    # 入力から次のコマンドを読み、それを 現在のコマンドにする。このルーチンは hasMoreCommands()がtrueの場 合のみ呼ぶようにする。最初は現コマンド は空である
    @current_command = @file_contents[@current_index]
    @current_index += 1
  end

  def a_command?
    commandType == A_COMMAND
  end

  def c_command?
    commandType == C_COMMAND
  end

  def self.l_command?(command)
    command.start_with?('(') && command.end_with?(')')
  end

  def l_command?
    commandType == L_COMMAND
  end

  def commandType
    # A_COMMAND、 C_COMMAND、 L_COMMAND

    # 現コマンドの種類を返す。 
    # A_COMMANDは@Xxxを意味し、Xxx はシンボルか 10 進数の数値である
    if @current_command.start_with? '@'
      return A_COMMAND
    elsif Parser.l_command?(@current_command)
      return L_COMMAND
    else 
      return C_COMMAND
    end
    # C_COMMANDはdest=comp;jump を意味する
    # L_COMMAND は擬似コマンドであり、 (Xxx) を意味する。Xxx はシンボル である
    # ! caseを使っての条件分岐になると思う
  end

  def symbol
    # 現コマンド@Xxx または (Xxx) の Xxx を返す。Xxx はシンボルまたは 10 進数の数値である。このルーチンは commandType() が A_COMMAND ま たはL_COMMANDのときだけ呼ぶようにする
    # FIXME: 現時点では "@xxx" のみ考慮する
    @current_command[1..-1]
  end

  def sym_to_b
    Parser::convert_number_to_binary(symbol)
  end

  def dest
    # destもしくはjumpのどちらかは空であるかもしれない。
    # もしdestが空であれば、「=」は省略される。
    # もしjumpが空であれば、「;」は省略される
    # 現 C 命令の dest ニーモニックを返 す（候補として 8 つの可能性がある）。 このルーチンは commandType() が C_COMMAND のときだけ呼ぶようにする 
    if @current_command.include?("=")
      @current_command.split("=").first
    else
      nil
    end
  end

  def comp
    # 現 C 命令の comp ニーモニックを返 す（候補として 28 個の可能性がある）。 このルーチンは commandType() が C_COMMAND のときだけ呼ぶようにする 
    if dest
      @current_command.split("=")[1]
    elsif jump
      @current_command.split(";")[0]
    else
      raise Parser::AssemblerSyntaxError
    end
  end

  def jump
    # 現 C 命令の jump ニーモニックを返 す（候補として 8 つの可能性がある）。 このルーチンは commandType() が C_COMMAND のときだけ呼ぶようにする 
    if @current_command.include?(";")
      @current_command.split(";")[1]
    else
      nil
    end
  end
end
