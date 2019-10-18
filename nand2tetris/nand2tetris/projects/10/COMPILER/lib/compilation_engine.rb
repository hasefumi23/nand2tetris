require "pp"

# class Token
#   attr_reader :token, :
# end

class CompilationEngine
  # 与えられた入力と出力に対して新しいコンパイルエンジンを
  # 生成する。次に呼ぶルーチンはcompileClass()でなければならない
  def initialize(tokenizer)
    # JackTokenizer
    @t = tokenizer
    @indent_level = 0
  end

  def out(str)
    print "#{' ' * (2 * @indent_level)}"
    puts(str)
  end

  def simple_out_token
    out("<#{@t.token_type}> #{@t.current_token} </#{@t.token_type}>")
  end

  def out_type_token
    token = @t.current_token
    token_type = @t.token_type
    unless (["int", "char", "boolean"].include?(token) && token_type == "keyword") || @t.token_type == "identifier"
      raise StandardError.new("Illegal type token: token => #{token}, token_type => #{token_type}")
    end
    simple_out_token
  end

  # クラスをコンパイルする
  # 最初は token_type などのチェックは殆ど無しでいこう
  # バグの調査のためのデバッグ出力のみする感じで
  def compile_class
    @t.advance
    token = @t.current_token
    out("<class>")
    @indent_level += 1
    simple_out_token

    @t.advance
    simple_out_token

    @t.advance
    simple_out_token

    @t.advance
    token = @t.current_token
    if ["static", "field"].include?(token)
      compile_class_var_dec
      # compile_class_var_dec内部でadvanceが呼ばれているのでtokneを入れ直す
      token = @t.current_token
    end

    if ["constructor", "function", "method"].include?(token)
      compile_subroutine
      # compile_class_var_dec内部でadvanceが呼ばれているのでtokneを入れ直す
      token = @t.current_token
    end

    # @t.advance
    simple_out_token

    @indent_level -= 1
    out("</class>")
    # ’class’ className ’{’ classVarDec* subroutineDec* ’}’
  end

  # スタティック宣言またはフィールド宣言をコンパイルする
  # (’static’ | ’field’) type varName (’,’ varName)* ’;’
  def compile_class_var_dec
    token = @t.current_token
    return unless ["static", "field"].include?(token)

    out("<classVarDec>")
    @indent_level += 1

    # (’static’ | ’field’)
    simple_out_token

    # type
    @t.advance
    out_type_token

    # varName
    @t.advance
    simple_out_token

    @t.advance
    token = @t.current_token
    if token == ","
      simple_out_token
      begin 
        # (’,’ varName)* ’;’
        @t.advance
        token = @t.current_token
        simple_out_token
      end until token == ";"
    else
      simple_out_token
    end

    @indent_level -= 1
    out("</classVarDec>")

    @t.advance
    compile_class_var_dec
  end

  def out_parameter_list
    out("<parameterList>")
    @indent_level += 1
    @t.advance
    token = @t.current_token
    unless token == ")"
      # (type varName)
      out_type_token
      @t.advance
      simple_out_token

      @t.advance

      while @t.current_token == ","
        simple_out_token
        @t.advance
        simple_out_token
        @t.advance
        simple_out_token
        @t.advance
      end
    end

    # ’)’
    @indent_level -= 1
    out("</parameterList>")
    simple_out_token
  end

  def out_subroutine_body
    out("<subroutineBody>")

    token = @t.current_token
    until token == "}"
      @t.advance
      token = @t.current_token
    end 
    out("</subroutineBody>")
    @indent_level -= 1
  end

  # メソッド、ファンクション、コンストラクタをコンパイルする
  def compile_subroutine
    token = @t.current_token
    return unless ["constructor", "function", "method"].include?(token)

    out("<subroutine>")
    @indent_level += 1

    # (’constructor’ | ’function’ | ’method’)
    simple_out_token
    # (’void’ | type) subroutineName ’(’
    3.times {
      @t.advance
      simple_out_token
    }

    out_parameter_list
    out_subroutine_body
    out("</subroutine>")

    @t.advance
    compile_subroutine
  end

  # パラメータのリスト（空の可能性もある）をコンパイルする。カッコ"()"は含まない
  def compile_parameter_list

  end

  # var 宣言をコンパイルする
  def compile_var_dec

  end

  # 一連の文をコンパイルする。波カッコ"{}"は含まない
  def compile_statements

  end

  # do 文をコンパイルする
  def compile_do

  end

  # let 文をコンパイルする
  def compile_let
    
  end

  # while 文をコンパイルする
  def compile_while

  end

  # return 文をコンパイルする
  def compile_return
    
  end

  # if 文をコンパイルする
  def compile_if

  end

  # 式をコンパイルする
  def compile_expression

  end

  # termをコンパイルする。このルーチンは、やや複雑であり、
  # 構文解析のルールには複数の選択肢が存在し、現トークンだけからは決定できない場合がある
  # 具体的に言うと、もし現トークンが識別子であれば、このルーチンは、それが変数、配列宣言、
  # サブルーチン呼び出しのいずれかを識別しなければならない
  # そのためには、ひとつ先のトークンを読み込み、
  # そのトークンが“[”か“(”か“.”のどれに該当するかを調べれば、現トークンの種類を決定することができる
  # 他のトークンの場合は現トークンに含まないので、先読みを行う必要はない
  def compile_expression
    # やや複雑なので最初の段階では実装する必要はない
  end

  # コンマで分離された式のリスト（空の可能性もある）をコンパイルする
  def compile_expression_list
    
  end
end
