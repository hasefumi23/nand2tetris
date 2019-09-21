class Parser
  attr_accessor :file_contents
  attr_reader :current_command, :current_index

  C_ARITHMETIC = "C_ARITHMETIC"
  C_PUSH = "C_PUSH"
  C_POP = "C_POP"
  C_LABEL = "C_LABEL"
  C_GOTO = "C_GOTO"
  C_IF = "C_IF"
  C_FUNCTION = "C_FUNCTION"
  C_RETURN = "C_RETURN"
  C_CALL = "C_CALL"

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

  # 入力から次のコマンドを読み、それを現コマンドとする
  # hasMore Commands() が true の場合のみ、本ルーチンを呼ぶようにする
  # 最初は現コマンドは空である 
  def advance
    @current_command = file_contents[@current_index]
    @current_index += 1
  end

  # 現 VM コマンドの種類を返す
  # 算術コマンドはすべて C_ARITHMETIC が返される
  def command_type
    # C_ARITHMETIC、 C_PUSH、 C_POP、 C_LABEL、 C_GOTO、C_IF、 C_FUNCTION、 C_RETURN、 C_CALL
    commands = @current_command.split(" ")

    if %w[add sub neg eq gt lt and or not].include?(commands.first)
      C_ARITHMETIC
    elsif commands.first == "push"
      C_PUSH
    elsif commands.first == "pop"
      C_POP
    elsif commands.first == "return"
      C_RETURN
    end
  end

  # 現コマンドの最初の引数が返される
  # C_ARITHMETIC の場合、コマンド自体（add、subなど）が返される
  # 現コマンドが C_RETURN の場合、本ルーチンは呼ばないようにする
  def arg1
    commands = @current_command.split(" ")

    case command_type
    when C_ARITHMETIC then commands.first
    when C_RETURN then raise StandardError.new("Can't call arg1 when command type is C_RETURN")
    else commands[1]
    end
  end

  # 現コマンドの 2 番目の引数が返される
  # 現コマンドが C_PUSH、 C_POP、C_FUNCTION、 C_CALL の場合のみ本ルーチン を呼ぶようにする
  def arg2
    if [C_PUSH, C_POP, C_FUNCTION, C_CALL].include?(command_type)
      @current_command.split(" ")[2].to_i
    else
      raise StandardError.new("Can't call arg2 when command type is not correct")
    end
  end
end
