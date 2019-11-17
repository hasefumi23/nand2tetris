# コードを書くときはArray.jackとArray.vmを参考にすると良さそう
class VMWriter
  def initialize
    
  end

  def self.hello
    "hello"
  end

  def out(str, with_indentation: true)
    print "  " if with_indentation
    puts str
  end

  def write_pop_or_push(pop_or_push, segment, index)
    seg = case segment
    when "ARG" then "argument"
    when "CONST" then "constant"
    when "POINTER" then "pointer"
    when "LOCAL" then "local"
    when "STATIC" then "static"
    when "TEMP" then "temp"
    when "THAT" then "that"
    when "THIS" then "this"
    else raise StandardError.new("Unexpected segment is given: #{segment}")
    end

    out("#{pop_or_push} #{seg} #{index}")
  end

  # pushコマンドを書く
  #
  # Args:
  #   Segment: (CONST、 ARG、LOCAL、 STATIC、THIS、 THAT、POINTER、 TEMP)
  #   Index: （整数）
  def write_push(segment, index)
    write_pop_or_push("push", segment, index)
  end

  # popコマンドを書く
  #
  # Args:
  # Segment: (CONST、 ARG、LOCAL、 STATIC、THIS、 THAT、POINTER、 TEMP)、
  #   Index: （整数）
  def write_pop(segment, index)
    write_pop_or_push("pop", segment, index)
  end

  # 算術コマンドを書く
  #
  # Args:
  #   command (ADD、SUB、 NEG、EQ、GT、LT、 AND、OR、NOT)
  def write_arithmetic(command)
    out(command.downcase)
  end

  # labelコマンドを書く
  #
  # Args:
  #   label（文字列）
  def write_label(label)
    out("label #{label}", with_indentation: false)
  end

  # gotoコマンドを書く
  #
  # Args:
  #   label（文字列）
  def write_goto(label)
    out("goto #{label}")
  end

  # ifコマンドを書く
  #
  # Args:
  #   label（文字列）
  def write_if(label)
    out("if-goto #{label}")
  end

  # callコマンドを書く
  #
  # Args:
  #   name（文字列）
  #   nArgs（整数）
  def write_call(name, n_args)
    out("call #{name} #{n_args}")
  end

  # functionコマンドを書く
  #
  # Args:
  #   name（文字列）
  #   nArgs（整数）: 関数のローカル変数の数
  def write_function(name, n_args)
    out("function #{name} #{n_args}", with_indentation: false)
  end

  # returnコマンドを書く
  def write_return
    out("return")
  end

  # 出力ファイルを閉じる
  def close
  end
end
