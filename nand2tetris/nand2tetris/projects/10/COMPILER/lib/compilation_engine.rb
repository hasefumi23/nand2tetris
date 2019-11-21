require 'pry'

require_relative "symbol_table"
require_relative "vm_writer"

class CompilationEngine
  OPERATOR_HASH = {
    "+" => "ADD",
    "-" => "SUB",
    "=" => "EQ",
    "&gt;" => "GT",
    "&lt;" => "LT",
    "&amp;" => "AND",
    "|" => "OR",
    "~" => "NOT",
    "neg" => "NEG",
  }

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
    @sym_table = SymbolTable.new
    @w = VMWriter.new
    @class_name = nil
    @t.advance
    @t.advance
  end

  def out(str)
    return unless ENV.fetch("DEBUG_MODE", false) == "true"
    print "#{' ' * (2 * @indent_level)}"
    puts(str)
  end

  def to_vm
    tree_2_vm(@current_node)
    # pp @sym_table
  end

  def tree_2_vm(tree)
    return if tree&.empty?

    node_name = tree[0][0]
    if node_name == "subroutineDec"
      keywords = tree[0][1]
      # ifやwhileをコンパイルするときに使うlabel
      # はユニークである必要があるために関数名を使うのでインスタンス変数として持つ
      @func_type = keywords[0][1]
      @return_type = keywords[1][1]
      @func_name = keywords[2][1]
      @if_label_count = 0
      @while_label_count = 0
      @sym_table.start_subroutine
      if @func_type == "method"
        @sym_table.define("this", @class_name, "ARG")
      end
    end

    unless ["keyword", "symbol", "identifier", "stringConstant", "integerConstant"].include?(node_name)
      out "<#{node_name}>"
      @indent_level += 1
    end

    case node_name
    when "varDec"
      children = tree[0][1]
      type = children[1][1]
      children.each_with_index { |el, i|
        tag_name = el[0]
        var_name = el[1]
        if i != 0 && i.even?
          sym = @sym_table.define(var_name, type, "VAR")
          format_id_tag(tag_name, var_name, format_sym("VAR", "DEFINED", "VAR", sym.index))
        else
          tree_2_vm([el])
        end
      }
    when "parameterList"
      unless tree[0][1]&.empty?
        children = tree[0][1]
        children.each_with_index { |el, i|
          type = children[i - 1][1]
          tag_name = el[0]
          var_name = el[1]
          if i % 3 == 1
            sym = @sym_table.define(var_name, type, "ARG")
            format_id_tag(tag_name, var_name, format_sym("ARG", "DEFINED", "ARG", sym.index))
          else
            tree_2_vm([el])
          end
        }
      end
    when "classVarDec"
      keywords = tree[0][1]
      static_or_field = keywords[0][1]
      type = keywords[1][1]
      keywords[2..-1].each { |k| 
        tag_name = k[0]
        var_name = k[1]
        if tag_name == "identifier"
          sym = @sym_table.define(var_name, type, static_or_field.upcase)
          format_id_tag(tag_name, var_name, format_sym(static_or_field.upcase, "DEFINED", static_or_field.upcase, sym.index))
        else
          out "<#{tag_name}> #{var_name} </#{tag_name}>"
        end
      }
    when "subroutineDec"
      keywords = tree[0][1]
      func_name = keywords[2][1]
      @func_name = func_name
      parameter_list_ary = keywords[4]
      # 引数を@sym_tableに登録するために出力より先に tree_2_vm に渡しておく
      tree_2_vm([parameter_list_ary]) # parameterList

      keywords[6][1].select { |word| word[0] == "varDec" }.each { |word|
        tree_2_vm([word])
      }

      var_count = @sym_table.var_count("VAR")
      @w.write_function("#{@class_name}.#{func_name}", var_count)
      if @func_type == "constructor"
        field_count = @sym_table.var_count("FIELD")
        @w.write_push("CONST", field_count)
        @w.write_call("Memory.alloc", 1)
        @w.write_pop("POINTER", 0)
      elsif @func_type == "method"
        @w.write_push("ARG", 0)
        @w.write_pop("POINTER", 0)
      end
      tree_2_vm(keywords[6..-1])
    # when "subroutineBody"
    #   if @func_type == "constructor"
    #     field_count = @sym_table.var_count("FIELD")
    #   end
    #   keywords = tree[0][1]
    #   tree_2_vm([keywords[1]])
    when "doStatement"
      keywords = tree[0][1]
      is_function_call = keywords[2][0] == "symbol" && keywords[2][1] == "."
      if is_function_call
        obj_name = keywords[1][1]
        statements = keywords[2]
        func_name = keywords[3][1]
        expression_list_ary = keywords[5]
      else
        func_name = keywords[1][1]
        expression_list_ary = keywords[3]
      end

      tree_2_vm([expression_list_ary])
      tree_2_vm([statements]) unless statements.nil?

      expression_count  = if expression_list_ary[1].empty?
        0
      else
        expression_list_ary[1].count { |ary| ary[0] == "expression" }
      end

      if is_function_call
        clazz_name = @sym_table.type_of(obj_name)
        instance_name = clazz_name.nil? ? obj_name : clazz_name
        # インスタンスメソッドの場合、インスタンスのポインタを渡し、その分の引数が増える
        if !clazz_name.nil? && !%w[int char boolean].include?(obj_name)
          expression_count += 1 
          idx = @sym_table.index_of(obj_name)
          kind = @sym_table.kind_of(obj_name)
          segment = SymbolTable.kind_to_seg(kind)
          @w.write_push(segment, idx)
        end
        @w.write_call("#{instance_name}.#{func_name}", expression_count)
      else
        @w.write_push("POINTER", 0)
        # 同一クラス内のインスタンスメソッドの場合、引数としてthisを渡すので+1する
        @w.write_call("#{@class_name}.#{func_name}", expression_count + 1)
      end
      @w.write_pop("TEMP", 0)
      # tree_2_vm(keywords[6..-1])
    when "expressionList"
      expression_list = tree[0][1]
      expression_list.each_slice(2).map(&:first).each { |expression_ary|
        tree_2_vm([expression_ary])
      }
      # tree_2_vm([expression_list_ary])
    when "expression"
      expression = tree[0][1]
      first_term = expression.slice!(0)
      tree_2_vm([first_term])
      expression.each_slice(2).each do |exp|
        op_ary = exp[0]
        term_ary = exp[1]
        tree_2_vm([term_ary])
        op = op_ary[1]
        if op == "*"
          @w.write_call("Math.multiply", "2")
        elsif op == "/"
          @w.write_call("Math.divide", "2")
        else
          @w.write_arithmetic(OPERATOR_HASH[op])
        end
      end
    when "term"
      terms = tree[0][1]
      first_term_type = terms[0][0]
      first_term_val = terms[0][1]
      second_term_val = terms&.at(1)&.at(1)
      fourth_term_val = terms&.at(3)&.at(1)

      if first_term_type == "identifier" && second_term_val == "."
        # Memory.peek(var)のような関数呼び出し
        expression_list_ary = terms[4]
        tree_2_vm([expression_list_ary])
        obj_name, func_name = first_term_val, terms[2][1]
        expression_count = expression_list_ary[1].count { |l| l[0] == "expression" }
        @w.write_call("#{obj_name}.#{func_name}", expression_count)
      elsif second_term_val == "[" && fourth_term_val == "]"
        var_name = terms[0][1]
        kind = @sym_table.kind_of(var_name)
        segment = SymbolTable.kind_to_seg(kind)
        var_index = @sym_table.index_of(var_name)
        @w.write_push(segment, var_index)
        exp = terms[2]
        tree_2_vm([exp])
        @w.write_arithmetic("ADD")
        @w.write_pop("POINTER", 1) # THATに配列のアドレスを設定
        @w.write_push("THAT", 0)
      elsif first_term_type == "symbol" && first_term_val == "-"
        tree_2_vm([terms[1]])
        @w.write_arithmetic("NEG")
      elsif first_term_type == "symbol" && first_term_val == "~"
        tree_2_vm([terms[1]])
        @w.write_arithmetic(OPERATOR_HASH["~"])
      elsif first_term_type == "keyword" && %w[true false null].include?(first_term_val)
        if first_term_val == "true"
          @w.write_push("CONST", 1)
          @w.write_arithmetic("NEG")
        else
          @w.write_push("CONST", 0)
        end
      elsif first_term_type == "keyword" && first_term_val == "this"
        @w.write_push("POINTER", 0)
      elsif first_term_type == "integerConstant"
        val = terms[0][1]
        @w.write_push("CONST", val)
      elsif first_term_type == "stringConstant"
        str = first_term_val
        @w.write_push("CONST", str.size)
        @w.write_call("String.new", 1)
        str.bytes { |b|
          @w.write_push("CONST", b)
          @w.write_call("String.appendChar", 2)
        }
      elsif first_term_type == "identifier"
        var_name = terms[0][1]
        kind = @sym_table.kind_of(var_name)
        segment = SymbolTable.kind_to_seg(kind)
        var_index = @sym_table.index_of(var_name)
        @w.write_push(segment, var_index)
      elsif first_term_type == "symbol" && first_term_val == "("
        exp = terms[1]
        tree_2_vm([exp])
      end
    when "returnStatement"
      children = tree[0][1]
      if @func_type == "constructor"
        # field_count = @sym_table.var_count("FIELD")
        @w.write_push("POINTER", 0)
      elsif children[1][0] == "expression"
        tree_2_vm([children[1]])
      elsif @return_type == "void"
        # Jackの仕様上サブルーチンの返り値がvoidの場合0を返す
        @w.write_push("CONST", 0)
      end
      @w.write_return
    when "letStatement"
      children = tree[0][1]
      var_name = children[1][1]

      kind = @sym_table.kind_of(var_name)
      segment = SymbolTable.kind_to_seg(kind)
      var_index = @sym_table.index_of(var_name)

      if children[2][1] == "[" && children[4][1] == "]"
        @w.write_push(segment, var_index)
        tree_2_vm([children[3]])
        @w.write_arithmetic("ADD")
        @w.write_pop("POINTER", 1)
        # call Keyboard.readInt 1
        tree_2_vm([children[6]])
        @w.write_pop("THAT", 0)
      else
        exp = children[3]
        tree_2_vm([exp])

        @w.write_pop(segment, var_index)
      end
    when "ifStatement"
      children = tree[0][1]
      var_name = children[1][1]
      exp = children[2]
      tree_2_vm([exp])
      @w.write_arithmetic("NOT")

      base_label_count = @if_label_count
      @if_label_count += 2
      @w.write_if("#{@func_name}-IF-#{base_label_count}")
      statements = children[5]
      tree_2_vm([statements])
      if children[7] != nil && children[7][1] = "else"
        @w.write_goto("#{@func_name}-IF-#{base_label_count + 1}")
        @w.write_label("#{@func_name}-IF-#{base_label_count}")
        # else句がある場合のみelse句の中のstatemntsを評価する
        else_statements = children[9]
        tree_2_vm([else_statements])
        @w.write_label("#{@func_name}-IF-#{base_label_count + 1}")
      else
        @w.write_label("#{@func_name}-IF-#{base_label_count}")
      end
    when "whileStatement"
      children = tree[0][1]
      var_name = children[1][1]
      base_label_count = @if_label_count
      @if_label_count += 2
      @w.write_label("#{@func_name}-WHILE-#{base_label_count}")
      exp = children[2]
      tree_2_vm([exp])
      @w.write_arithmetic("NOT")
      @w.write_if("#{@func_name}-WHILE-#{base_label_count + 1}")
      statements = children[5]
      tree_2_vm([statements])

      @w.write_goto("#{@func_name}-WHILE-#{base_label_count}")
      @w.write_label("#{@func_name}-WHILE-#{base_label_count + 1}")
    when "statements"
      children = tree[0][1]
      children.each { |child|
        tree_2_vm([child])
      }
    when "keyword", "symbol", "identifier", "stringConstant", "integerConstant"
      out_side_tag_name = node_name
      val = tree[0][1]
      if node_name == "identifier"
        sym = @sym_table.sym_of(val)
        kind, type, index = sym&.kind || "NONE", sym&.type, sym&.index
        next_token = tree&.at(1)&.at(1)
        if kind == "NONE"
          if !next_token.nil? && ["(", "["].include?(next_token)
            format_id_tag(out_side_tag_name, val, format_sym("FUNCTION", "USED", kind&.upcase, index))
          else
            format_id_tag(out_side_tag_name, val, format_sym("CLASS", "USED", kind&.upcase, index))
          end
        else
          format_id_tag(out_side_tag_name, val, format_sym("CLASS", "USED", kind&.upcase, index))
        end
      else
        out "<#{out_side_tag_name}> #{val} </#{out_side_tag_name}>"
      end
      tree_2_vm(tree.slice(1..-1))
    else
      tree_2_vm(tree[0][1])
    end

    unless ["keyword", "symbol", "identifier", "stringConstant", "integerConstant"].include?(node_name)
      @indent_level -= 1
      out "</#{node_name}>"
      tree_2_vm(tree[1..-1])
    end
  end

  def to_xml
    # pp @current_node.pop
    tree_2_xml(@current_node)
    # pp @sym_table
  end

  # 識別子のカテゴリ（var、argument、static、field、class、subroutine）
  # 識別子は定義されているか（defined）、それとも、使用されているか（used）
  # 識別子が 4 つの属性（var、argument、static、field）のうちどれに該当するか
  # そして、シンボルテーブルによって、その識別子に割り当てられる実行番号は何か
  def format_sym(category, defined_or_used, kind, index)
    "#{category} - #{defined_or_used} - #{kind} - #{index}"
  end

  def format_id_tag(tag_name, var_name, formatted_sym)
    out "<#{tag_name}> #{var_name} #{formatted_sym} </#{tag_name}>"
  end

  def tree_2_xml(tree)
    return if tree&.empty?

    node_name = tree[0][0]
    if node_name == "subroutineDec"
      @sym_table.start_subroutine
      @sym_table.define("this", @class_name, "ARG")
    end

    unless ["keyword", "symbol", "identifier", "stringConstant", "integerConstant"].include?(node_name)
      out "<#{node_name}>"
      @indent_level += 1
    end

    case node_name
    when "varDec"
      children = tree[0][1]
      type = children[1][1]
      children.each_with_index { |el, i|
        tag_name = el[0]
        var_name = el[1]
        if i != 0 && i.even?
          sym = @sym_table.define(var_name, type, "VAR")
          format_id_tag(tag_name, var_name, format_sym("VAR", "DEFINED", "VAR", sym.index))
        else
          tree_2_xml([el])
        end
      }
    when "parameterList"
      unless tree[0][1]&.empty?
        children = tree[0][1]
        children.each_with_index { |el, i|
          type = children[i - 1][1]
          tag_name = el[0]
          var_name = el[1]
          if i % 3 == 1
            sym = @sym_table.define(var_name, type, "ARG")
            format_id_tag(tag_name, var_name, format_sym("ARG", "DEFINED", "ARG", sym.index))
          else
            tree_2_xml([el])
          end
        }
      end
    when "classVarDec"
      keywords = tree[0][1]
      static_or_field = keywords[0][1]
      type = keywords[1][1]
      keywords.each { |k| 
        tag_name = k[0]
        var_name = k[1]
        if tag_name == "identifier"
          sym = @sym_table.define(var_name, type, static_or_field.upcase)
          format_id_tag(tag_name, var_name, format_sym(static_or_field.upcase, "DEFINED", static_or_field.upcase, sym.index))
        else
          out "<#{tag_name}> #{var_name} </#{tag_name}>"
        end
      }
    when "keyword", "symbol", "identifier", "stringConstant", "integerConstant"
      out_side_tag_name = node_name
      val = tree[0][1]
      if node_name == "identifier"
        sym = @sym_table.sym_of(val)
        kind, type, index = sym&.kind || "NONE", sym&.type, sym&.index
        next_token = tree&.at(1)&.at(1)
        if kind == "NONE"
          if !next_token.nil? && ["(", "["].include?(next_token)
            format_id_tag(out_side_tag_name, val, format_sym("FUNCTION", "USED", kind&.upcase, index))
          else
            format_id_tag(out_side_tag_name, val, format_sym("CLASS", "USED", kind&.upcase, index))
          end
        else
          format_id_tag(out_side_tag_name, val, format_sym("CLASS", "USED", kind&.upcase, index))
        end
      else
        out "<#{out_side_tag_name}> #{val} </#{out_side_tag_name}>"
      end
      tree_2_xml(tree.slice(1..-1))
    else
      tree_2_xml(tree[0][1])
    end

    unless ["keyword", "symbol", "identifier", "stringConstant", "integerConstant"].include?(node_name)
      @indent_level -= 1
      out "</#{node_name}>"
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
    [token_type, token]
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
    _, @class_name = expect_identifier
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
