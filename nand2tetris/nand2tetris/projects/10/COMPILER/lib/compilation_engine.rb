require 'pry'

class CompilationEngine
  class NoExpectedKeywordError < StandardError; end
  class NoExpectedSymbolError < StandardError; end
  class NotIntegerConstantError < StandardError; end
  class NotStringConstantError < StandardError; end
  class NotIdentifierError < StandardError; end
  class NoExpectationError < StandardError; end

  # 与えられた入力と出力に対して新しいコンパイルエンジンを
  # 生成する。次に呼ぶルーチンはcompileClass()でなければならない
  def initialize(tokenizer)
    @t = tokenizer
    @indent_level = 0
    @t.advance
  end

  def out(str)
    print "#{' ' * (2 * @indent_level)}"
    puts(str)
  end

  def simple_out_token
    out("<#{@t.token_type}> #{@t.current_token} </#{@t.token_type}>")
  end

  def expect_keyword(*keywords)
    unless keywords.include?(@t.current_token) &&
      @t.token_type == JackTokenizer::KEYWORD
      # raise NoExpectedKeywordError.new("Expected keywords are: #{keywords}. But actual #{build_error_message}")
    end

    simple_out_token
  end

  def expect_symbol(*symbols)
    unless symbols.include?(@t.current_token) &&
      @t.token_type == JackTokenizer::SYMBOL
      # raise NoExpectedSymbolError.new("Expected symbols are: #{symbols}. But actual #{build_error_message}")
    end

    simple_out_token
  end

  def expect_integer_constant
    unless @t.token_type == JackTokenizer::INTEGER_CONSTANT
      # raise NotIntegerConstantError.new("Expected INTEGER_CONSTANT but #{build_error_message}")
    end

    simple_out_token
  end

  def expect_string_constant
    unless @t.token_type == JackTokenizer::STRING_CONSTANT
      # raise NotStringConstantError.new("Expected STRING_CONSTANT but #{build_error_message}")
    end

    simple_out_token
  end

  def expect_identifier
    unless @t.token_type == JackTokenizer::IDENTIFIER
      # raise NotIdentifierError.new("Expected IDENTIFIER but #{build_error_message}")
    end

    simple_out_token
  end

  def expect_type
    unless %w[int char boolean].include?(@t.current_token) ||
      @t.token_type == JackTokenizer::IDENTIFIER
      # raise NoExpectationError.new("Expected type, but actual #{build_error_message}")
    end

    simple_out_token
  end

  def build_error_message
    "#{@t.current_token}, token_type is #{@t.token_type}"
  end

  def type_syntax?
    %w[int char boolean].include?(@t.current_token) ||
      @t.token_type == JackTokenizer::IDENTIFIER
  end

  # クラスをコンパイルする
  # 最初は token_type などのチェックは殆ど無しでいこう
  # バグの調査のためのデバッグ出力のみする感じで
  def compile_class
    out("<class>")
    @indent_level += 1

    expect_keyword("class")
    @t.advance
    expect_identifier
    @t.advance
    expect_symbol("{")

    @t.advance
    while %w[static field].include?(@t.current_token)
      compile_class_var_dec
    end

    while %w[constructor function method].include?(@t.current_token)
      compile_subroutine
    end

    @t.advance
    expect_symbol("}")

    @indent_level -= 1
    out("</class>")
  end

  # スタティック宣言またはフィールド宣言をコンパイルする
  # (’static’ | ’field’) type varName (’,’ varName)* ’;’
  def compile_class_var_dec
    out("<classVarDec>")
    @indent_level += 1

    expect_keyword(*%w[static field])

    @t.advance
    expect_type

    @t.advance
    # token::varName
    expect_identifier

    @t.advance
    while @t.current_token == ","
      expect_symbol(",")
      @t.advance
      # token::varName
      expect_identifier
      @t.advance
    end

    expect_symbol(";")

    @indent_level -= 1
    out("</classVarDec>")
    @t.advance
  end

  def compile_parameter_list
    @indent_level += 1

    expect_type

    @t.advance
    # token::varName
    expect_identifier

    @t.advance
    while @t.current_token == ","
      expect_symbol(",")
      @t.advance
      expect_type
      @t.advance
      # token::varName
      expect_identifier
      @t.advance
    end

    @indent_level -= 1
  end

  def compile_var_dec
    out("<varDec>")
    @indent_level += 1

    expect_keyword("var")

    @t.advance
    expect_type

    @t.advance
    # token::varName
    expect_identifier

    @t.advance
    while @t.current_token == ","
      expect_symbol(",")
      @t.advance
      # token::varName
      expect_identifier
      @t.advance
    end

    expect_symbol(";")
    @indent_level -= 1
    out("</varDec>")
  end

  # メソッド、ファンクション、コンストラクタをコンパイルする
  def compile_subroutine
    out("<subroutineDec>")
    @indent_level += 1
    expect_keyword(*%w[constructor function method])

    @t.advance
    simple_out_token

    @t.advance
    expect_identifier

    @t.advance
    expect_symbol("(")

    @t.advance
    out("<parameterList>")
    if type_syntax?
      compile_parameter_list
    end
    out("</parameterList>")

    expect_symbol(")")

    @t.advance
    compile_subroutine_body

    @indent_level -= 1
    out("</subroutineDec>")
    @t.advance
  end

  def compile_subroutine_body
    out("<subroutineBody>")
    @indent_level += 1

    expect_symbol("{")

    @t.advance
    while @t.current_token == "var"
      compile_var_dec
      @t.advance
    end

    compile_statements

    # @t.advance
    expect_symbol("}")

    @indent_level -= 1
    out("</subroutineBody>")
  end

  # 一連の文をコンパイルする。波カッコ"{}"は含まない
  # FIXME: from here
  def compile_statements
    out("<statements>")
    @indent_level += 1

    while %w[let if while do return].include?(@t.current_token)
      case @t.current_token
      when "let"
        compile_let
        @t.advance
      when "if"
        compile_if
      when "while"
        compile_while
        @t.advance
      when "do" 
        compile_do
        @t.advance
      when "return"
        compile_return
        @t.advance
      end
    end

    @indent_level -= 1
    out("</statements>")
  end

  # do 文をコンパイルする
  def compile_do
    out("<doStatement>")
    @indent_level += 1
    # subroutineCallが面倒すぎるので一旦skip
    @indent_level -= 1
    out("</doStatement>")
  end

  # let 文をコンパイルする
  def compile_let
    out("<letStatement>")
    @indent_level += 1

    expect_keyword("let")

    # token::varName
    @t.advance
    expect_identifier

    @t.advance
    if @t.current_token == "["
      expect_symbol("[")
      @t.advance
      compile_expression
      expect_symbol("]")
      @t.advance
    end

    expect_symbol("=")

    @t.advance
    compile_expression

    expect_symbol(";")

    @indent_level -= 1
    out("</letStatement>")
  end

  # while 文をコンパイルする
  def compile_while
    out("<whileStatement>")
    @indent_level += 1
    expect_keyword("while")

    @t.advance
    expect_symbol("(")

    @t.advance
    compile_expression

    expect_symbol(")")

    @t.advance
    expect_symbol("{")

    @t.advance
    compile_statements

    # @t.advance
    expect_symbol("}")
    @indent_level -= 1
    out("</whileStatement>")
  end

  # return 文をコンパイルする
  def compile_return
    out("<returnStatement>")
    @indent_level += 1
    expect_keyword("return")

    @t.advance
    unless @t.current_token == ";"
      compile_expression
    end

    expect_symbol(";")
    @indent_level -= 1
    out("</returnStatement>")
  end

  # if 文をコンパイルする
  def compile_if
    out("<ifStatement>")
    @indent_level += 1
    expect_keyword("if")
    @t.advance
    expect_symbol("(")
    @t.advance
    compile_expression
    expect_symbol(")")
    @t.advance
    expect_symbol("{")
    @t.advance
    compile_statements
    expect_symbol("}")

    @t.advance
    if @t.current_token == "else"
      expect_keyword("else")

      @t.advance
      expect_symbol("{")
      @t.advance
      compile_statements
      @t.advance
      expect_symbol("{")
      @t.advance
    end
    @indent_level -= 1
    out("</ifStatement>")
  end

  # 式をコンパイルする
  def compile_expression
    out("<expression>")
    @indent_level += 1

    # @t.advance
    compile_term

    @t.advance
    while JackTokenizer::OPERATORS.include?(@t.current_token)
      compile_term
      @t.advance
    end

    @indent_level -= 1
    out("</expression>")
  end

  # termをコンパイルする。このルーチンは、やや複雑であり、
  # 構文解析のルールには複数の選択肢が存在し、現トークンだけからは決定できない場合がある
  # 具体的に言うと、もし現トークンが識別子であれば、このルーチンは、それが変数、配列宣言、
  # サブルーチン呼び出しのいずれかを識別しなければならない
  # そのためには、ひとつ先のトークンを読み込み、
  # そのトークンが“[”か“(”か“.”のどれに該当するかを調べれば、現トークンの種類を決定することができる
  # 他のトークンの場合は現トークンに含まないので、先読みを行う必要はない
  def compile_term
    out("<term>")
    @indent_level += 1
    simple_out_token
    @indent_level -= 1
    out("</term>")
  end

  # コンマで分離された式のリスト（空の可能性もある）をコンパイルする
  def compile_expression_list
  end
end
