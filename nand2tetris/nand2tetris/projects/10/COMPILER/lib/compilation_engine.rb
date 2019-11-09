require 'pry'

class CompilationEngine
  attr_reader :tree_stack, :current_node

  class NoExpectedKeywordError < StandardError; end
  class NoExpectedSymbolError < StandardError; end
  class NotIntegerConstantError < StandardError; end
  class NotStringConstantError < StandardError; end
  class NotIdentifierError < StandardError; end
  class NoExpectationError < StandardError; end

  DEBUG_MODE = false

  # 与えられた入力と出力に対して新しいコンパイルエンジンを
  # 生成する。次に呼ぶルーチンはcompileClass()でなければならない
  def initialize(tokenizer)
    @t = tokenizer
    @indent_level = 0
    @tree_stack = []
    @current_node = nil
    @t.advance
    @t.advance
  end

  def out(str)
    print "#{' ' * (2 * @indent_level)}"
    puts(str)
  end

  def to_xml
    # pp @current_node.pop
    tree_2_xml(@current_node)
  end

  def tree_2_xml(tree)
    return if tree&.empty?

    # pp tree
    case tree[0][0]
    when "keyword", "symbol", "identifier", "stringConstant", "integerConstant"
      tag_name = tree[0][0]
      val = tree[0][1]
      out "<#{tag_name}> #{val} </#{tag_name}>"
      tree_2_xml(tree.slice(1..-1))
    else
      out "<#{tree[0][0]}>"
      @indent_level += 1
      tree_2_xml(tree[0][1])

      @indent_level -= 1
      out "</#{tree[0][0]}>"
      tree_2_xml(tree[1..-1])
    end
  end

  def debug
    if DEBUG_MODE
      pp @tree_stack
      pp @current_node
    end
  end

  def new_node(node_name)
    if @current_node.nil?
      @tree_stack << []
    else
      @tree_stack << @current_node
    end
    @current_node = []
    debug
  end

  def close_node(node_name)
    if @current_node.nil?
      raise StandardError.new("このエラーは通常発生し得ない")
    else
      prev_node = @tree_stack.pop
      prev_node << [node_name, @current_node]
      @current_node = prev_node
    end
    debug
  end

  def simple_out_token(with_advance: true)
    @t.advance if with_advance
    token_type = @t.current_token_type
    token = @t.current_token
    # out("<#{token_type}> #{token} </#{token_type}>")
    @current_node << [token_type, token]
  end

  def expect_keyword(keywords, with_advance: true)
    unless keywords.include?(@t.current_token) &&
      @t.current_token_type == JackTokenizer::KEYWORD
      # raise NoExpectedKeywordError.new("Expected keywords are: #{keywords}. But actual #{build_error_message}")
    end

    simple_out_token(with_advance: with_advance)
  end

  def expect_symbol(symbols, with_advance: true)
    unless symbols.include?(@t.current_token) &&
      @t.current_token_type == JackTokenizer::SYMBOL
      # raise NoExpectedSymbolError.new("Expected symbols are: #{symbols}. But actual #{build_error_message}")
    end

    simple_out_token(with_advance: with_advance)
  end

  def expect_integer_constant(with_advance: true)
    unless @t.current_token_type == JackTokenizer::INTEGER_CONSTANT
      # raise NotIntegerConstantError.new("Expected INTEGER_CONSTANT but #{build_error_message}")
    end

    simple_out_token(with_advance: with_advance)
  end

  def expect_string_constant(with_advance: true)
    unless @t.current_token_type == JackTokenizer::STRING_CONSTANT
      # raise NotStringConstantError.new("Expected STRING_CONSTANT but #{build_error_message}")
    end

    simple_out_token(with_advance: with_advance)
  end

  def expect_identifier(with_advance: true)
    unless @t.current_token_type == JackTokenizer::IDENTIFIER
      # raise NotIdentifierError.new("Expected IDENTIFIER but #{build_error_message}")
    end

    simple_out_token(with_advance: with_advance)
  end

  def expect_type(with_advance: true)
    unless %w[int char boolean].include?(@t.current_token) ||
      @t.current_token_type == JackTokenizer::IDENTIFIER
      # raise NoExpectationError.new("Expected type, but actual #{build_error_message}")
    end

    simple_out_token(with_advance: with_advance)
  end

  def build_error_message
    "#{@t.current_token}, token_type is #{@t.current_token_type}"
  end

  def type_syntax?
    %w[int char boolean].include?(@t.current_token) ||
      @t.current_token_type == JackTokenizer::IDENTIFIER
  end

  # クラスをコンパイルする
  # 最初は token_type などのチェックは殆ど無しでいこう
  # バグの調査のためのデバッグ出力のみする感じで
  def compile_class
    # out("<class>")
    new_node("class")
    @indent_level += 1

    expect_keyword(["class"], with_advance: false)
    expect_identifier
    expect_symbol(["{"])

    @t.advance
    while %w[static field].include?(@t.current_token)
      compile_class_var_dec
    end

    while %w[constructor function method].include?(@t.current_token)
      compile_subroutine
    end

    expect_symbol(["}"])

    @indent_level -= 1
    close_node("class")
    # out("</class>")
  end

  # スタティック宣言またはフィールド宣言をコンパイルする
  # (’static’ | ’field’) type varName (’,’ varName)* ’;’
  def compile_class_var_dec
    new_node("classVarDec")
    @indent_level += 1

    expect_keyword(%w[static field], with_advance: false)
    expect_type
    # token::varName
    expect_identifier

    @t.advance
    while @t.current_token == ","
      expect_symbol([","], with_advance: false)
      # token::varName
      expect_identifier
      @t.advance
    end

    expect_symbol([";"], with_advance: false)

    @indent_level -= 1
    close_node("classVarDec")
    @t.advance
  end

  def compile_parameter_list
    @indent_level += 1

    expect_type(with_advance: false)

    # token::varName
    expect_identifier

    @t.advance
    while @t.current_token == ","
      expect_symbol([","], with_advance: false)
      expect_type
      # token::varName
      expect_identifier
      @t.advance
    end

    @indent_level -= 1
  end

  def compile_var_dec
    new_node("varDec")
    @indent_level += 1
    expect_keyword(["var"], with_advance: false)
    expect_type
    # token::varName
    expect_identifier

    @t.advance
    while @t.current_token == ","
      expect_symbol([","], with_advance: false)
      # token::varName
      expect_identifier
      @t.advance
    end

    expect_symbol([";"], with_advance: false)
    @indent_level -= 1
    close_node("varDec")
  end

  # メソッド、ファンクション、コンストラクタをコンパイルする
  def compile_subroutine
    new_node("subroutineDec")
    @indent_level += 1
    expect_keyword(%w[constructor function method], with_advance: false)
    simple_out_token
    expect_identifier
    expect_symbol(["("])

    @t.advance
    new_node("parameterList")
    if type_syntax?
      compile_parameter_list
    end
    close_node("parameterList")

    expect_symbol([")"], with_advance: false)
    @t.advance
    compile_subroutine_body

    @indent_level -= 1
    close_node("subroutineDec")
    @t.advance
  end

  def compile_subroutine_body
    new_node("subroutineBody")
    @indent_level += 1

    expect_symbol(["{"], with_advance: false)

    @t.advance
    while @t.current_token == "var"
      compile_var_dec
      @t.advance
    end

    compile_statements

    expect_symbol(["}"], with_advance: false)

    @indent_level -= 1
    close_node("subroutineBody")
  end

  # 一連の文をコンパイルする。波カッコ"{}"は含まない
  def compile_statements
    new_node("statements")
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
    close_node("statements")
  end

  # do 文をコンパイルする
  def compile_do
    new_node("doStatement")
    @indent_level += 1

    expect_keyword("do", with_advance: false)
    out_subroutine_call
    expect_symbol(";")
    @indent_level -= 1
    close_node("doStatement")
  end

  def out_subroutine_call(with_advance: true)
    if with_advance
      # token::(subroutineName | className | varName)
      expect_identifier
    else
      expect_identifier(with_advance: with_advance)
    end

    @t.advance
    if @t.current_token == "."
      expect_symbol(".", with_advance: false)
      # token:subroutineName
      expect_identifier
      @t.advance
    end

    expect_symbol("(", with_advance: false)
    @t.advance
    compile_expression_list
    expect_symbol(")", with_advance: false)
  end

  # let 文をコンパイルする
  def compile_let
    new_node("letStatement")
    @indent_level += 1

    expect_keyword(["let"], with_advance: false)

    # token::varName
    expect_identifier

    @t.advance
    if @t.current_token == "["
      expect_symbol(["["], with_advance: false)
      @t.advance
      compile_expression
      expect_symbol(["]"], with_advance: false)
      @t.advance
    end

    expect_symbol(["="], with_advance: false)
    @t.advance
    compile_expression
    expect_symbol([";"], with_advance: false)

    @indent_level -= 1
    close_node("letStatement")
  end

  # while 文をコンパイルする
  def compile_while
    new_node("whileStatement")
    @indent_level += 1
    expect_keyword(["while"], with_advance: false)

    expect_symbol(["("])

    @t.advance
    compile_expression

    expect_symbol([")"], with_advance: false)
    expect_symbol(["{"])

    @t.advance
    compile_statements

    expect_symbol(["}"], with_advance: false)
    @indent_level -= 1
    close_node("whileStatement")
  end

  # return 文をコンパイルする
  def compile_return
    new_node("returnStatement")
    @indent_level += 1
    expect_keyword(["return"], with_advance: false)

    @t.advance
    unless @t.current_token == ";"
      compile_expression
    end

    expect_symbol([";"], with_advance: false)
    @indent_level -= 1
    close_node("returnStatement")
  end

  # if 文をコンパイルする
  def compile_if
    new_node("ifStatement")
    @indent_level += 1
    expect_keyword(["if"], with_advance: false)
    expect_symbol(["("])
    @t.advance
    compile_expression
    expect_symbol([")"], with_advance: false)
    expect_symbol(["{"])
    @t.advance
    compile_statements
    expect_symbol(["}"], with_advance: false)

    @t.advance
    if @t.current_token == "else"
      expect_keyword(["else"], with_advance: false)

      expect_symbol(["{"])
      @t.advance
      compile_statements
      expect_symbol(["}"], with_advance: false)
      @t.advance
    end
    @indent_level -= 1
    close_node("ifStatement")
  end

  # 式をコンパイルする
  def compile_expression
    new_node("expression")
    @indent_level += 1

    compile_term

    @t.advance
    while JackTokenizer::OPERATORS.include?(@t.current_token)
      expect_symbol(JackTokenizer::OPERATORS, with_advance: false)
      @t.advance
      compile_term
      @t.advance
    end

    @indent_level -= 1
    close_node("expression")
  end

  # termをコンパイルする。このルーチンは、やや複雑であり、
  # 構文解析のルールには複数の選択肢が存在し、現トークンだけからは決定できない場合がある
  # 具体的に言うと、もし現トークンが識別子であれば、このルーチンは、それが変数、配列宣言、
  # サブルーチン呼び出しのいずれかを識別しなければならない
  # そのためには、ひとつ先のトークンを読み込み、
  # そのトークンが“[”か“(”か“.”のどれに該当するかを調べれば、現トークンの種類を決定することができる
  # 他のトークンの場合は現トークンに含まないので、先読みを行う必要はない
  def compile_term
    new_node("term")
    @indent_level += 1

    if @t.current_token_type == JackTokenizer::IDENTIFIER
      if @t.next_token == "["
        expect_identifier(with_advance: false)
        expect_symbol(["["])
        @t.advance
        compile_expression
        expect_symbol(["]"], with_advance: false)
      elsif ["(", "."].include?(@t.next_token)
        out_subroutine_call(with_advance: false)
      else
        simple_out_token(with_advance: false)
      end
    elsif JackTokenizer::UNARY_OPS.include?(@t.current_token)
      simple_out_token(with_advance: false)
      @t.advance
      compile_term
    elsif @t.current_token == "("
      simple_out_token(with_advance: false)
      @t.advance
      compile_expression
      expect_symbol([")"], with_advance: false)
    else
      simple_out_token(with_advance: false)
    end

    @indent_level -= 1
    close_node("term")
  end

  # コンマで分離された式のリスト（空の可能性もある）をコンパイルする
  def compile_expression_list
    new_node("expressionList")
    @indent_level += 1

    unless @t.current_token == ")"
      compile_expression
      while @t.current_token == ","
        expect_symbol(",", with_advance: false)
        @t.advance
        compile_expression
      end
    end

    @indent_level -= 1
    close_node("expressionList")
  end
end
