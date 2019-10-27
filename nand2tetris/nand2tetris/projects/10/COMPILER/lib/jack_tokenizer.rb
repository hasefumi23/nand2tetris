# frozen_string_literal: true
require 'pry'

class JackTokenizer
  attr_reader :prev

  class CommentError < StandardError; end

  # DEBUG = true
  DEBUG = false

  KEY_WORDS = %w[class constructor function method field static var int char boolean void true false null this let do if else while return]
  SYMBOLS = %w[{ } ( ) [ ] . , ; + - * / & | < > = ~]
  OPERATORS = %w[+ - * / &amp; | &lt; &gt; =]
  UNARY_OPS = %w[- ~]

  # return values of token_type
  KEYWORD = "keyword"
  SYMBOL = "symbol"
  STRING_CONSTANT = "stringConstant"
  INTEGER_CONSTANT = "integerConstant"
  IDENTIFIER = "identifier"

  def initialize(file_path)
    @io = File.open(file_path)
    @line = nil
    @current_line = ''
    @chars = []
    @current_token = nil
    @prev = nil
  end

  def current_token
    if token_type == "stringConstant"
      # stringConstantの場合必ず"(ダブルクオート)で囲んでいるのでそれを取り除く
      @current_token[1..-2]
    elsif token_type == "symbol"
      case @current_token
      when "<" then "&lt;"
      when ">" then "&gt;"
      when "&" then "&amp;"
      else @current_token
      end
    else
      @current_token
    end
  end

  # 入力にまだトークンは存在するか？
  def has_more_tokens?
    p "@io.eof?: #{@io.eof?}, @chars.empty?: #{@chars&.inspect}" if DEBUG
    !@io.eof? || !@chars.nil? || !@chars&.empty?
  end

  def initial_parse
    begin
      @line = @io.gets&.strip
      return nil if @line.nil?

      @line.gsub!(Regexp.new("//.*"), "")
      p "@line: #{@line}" if DEBUG
    end while @line.nil? || @line.empty?

    @line.strip.split("")
  end

  # 入力から次のトークンを取得し、それを現在のトークン（現トークン）とする
  # このルーチンは、hasMoreTokens()がtrueの場合のみ呼び出すことができる
  # また、最初は現トークンは設定されていない
  def advance
    if @chars&.empty?
      @chars = initial_parse
    end

    tokened = tokenize_line
    p "tokened: #{tokened.inspect}" if DEBUG
    # @io.eof? == falseかつ空行が続く場合、NoMethodErrorが発生するのでそれを避けるためにnilを返す
    return nil if tokened.nil?

    unless @current_token.nil?
      @prev = { "token" => @current_token, "token_type" => token_type }
    end
    @current_token = tokened
    @current_token
  end

  def tokenize_line
    # binding.pry
    word = ""
    while true
      p "@chars: #{@chars.inspect}" if DEBUG

      # "test;"のようなIDENTIFIERとSYMBOLの組み合わせを判定する
      if !word.empty? && SYMBOLS.include?(@chars[0])
        return word
      end

      # ファイルの最後に空行が続く場合、@charsがnilになっていてもここに到達する可能性がある
      return nil if @chars.nil?
      char = @chars.shift

      if char == " "
        # 空文字が来た場合、可能な限り取り除く
        while @chars[0] == " "
          char = @chars.shift
        end

        if word.empty?
          next
        end
        # 空白の区切りは一つのトークンの区切りなのでリターンする
        return word
      end

      word += char
      if word.start_with?('"') && !word.end_with?('"')
        # STRING_CONSTANTはここでまとめて処理する
        begin
          char = @chars.shift
          word += char
        end until char == '"'
      end

      if word == "/" && @chars[0] == "*"
        local_word = ""
        local_char = @chars.shift

        # 複数行コメントの終わりまで読み込みを進める
        until local_word.end_with?("*/")
          if @chars.empty?
            @chars = initial_parse
          end
          local_char = @chars.shift
          local_word += local_char
        end

        if @chars.empty?
          # 複数行のコメントの場合@charsが空になる可能性があるので空だったら新しい行を取得する
          @chars = initial_parse
        end
        # whileのループ内にいるのでwordを初期化して再出発
        word = @chars.shift
        next
      end

      if SYMBOLS.include?(char)
        # シンボルは一文字でかつ空白が入るとは限らないので見つけ次第即時リターン
        return char
      end
    end

    word
  end

  # KEYWORD、 SYMBOL、 IDENTIFIER、 INT_CONST、 STRING_CONST
  # 現トークンの種類を返す
  def token_type
    if KEY_WORDS.include?(@current_token)
      KEYWORD
    elsif SYMBOLS.include?(@current_token)
      SYMBOL
    elsif @current_token.start_with?('"') && @current_token.end_with?('"')
      STRING_CONSTANT
    elsif @current_token =~ /^\d+$/
      INTEGER_CONSTANT
    elsif @current_token =~ /^\w+$/
      IDENTIFIER
    else
      raise StandardError.new("Unexpected token error: token = #{@current_token}")
    end
  end

  # 現トークンのキーワードを返す。このルーチンは、tokenType()がKEYWORDの場合のみ呼び出すことができる
  def keyword
    # CLASS
    # METHOD
    # FUNCTION
    # CONSTRUCTOR
    # INT
    # BOOLEAN
    # CHAR、VOID
    # VAR、STATIC
    # FIELD、LET
    # DO、IF、ELSE
    # WHILE
    # RETURN
    # TRUE、FALSE
    # NULL、THIS
    @current_token.upcase
  end

  # 現トークンの文字を返す
  # このルーチンは、tokenType()がSYMBOLの場合のみ呼び出すことができる
  def symbol
    @current_token
  end

  # 現トークンの識別子（identiﬁer）を返す
  # このルーチンは、tokenType()がIDENTIFIERの場合のみ呼び出すことができる
  def identifier
    @current_token
  end

  # 現トークンの整数の値を返す
  # このルーチンは、tokenType()がINT_CONSTの場合のみ呼び出すことができる
  def int_val
    @current_token
  end

  # 現トークンの文字列を返す
  # このルーチンは、tokenType()がSTRING_CONSTの場合のみ呼び出すことができる
  def string_val
    @current_token
  end
end
