# frozen_string_literal: true
require 'pry'

class JackTokenizer
  class CommentError < StandardError; end

  attr_accessor :current_token
  DEBUG = false

  KEY_WORDS = %w[class constructor function method field static var int char boolean void true false null this let do if else while return]
  SYMBOLS = %w[{ } ( ) [ ] . , ; + - * / & | < > = ~]

  # 理想は一文字ずつ読み込んで都度判定ロジックを走らせてトークンかコメントかを
  # 判断する処理だが、ロジックが必要以上に複雑になり可読性も落ちるため
  # 妥協して、コメントは可能な限り最初に全部削除する
  # ただし複数行に渡るコメントは未削除
  def initialize(file_name)
    @io = File.open(file_name)
    @line = nil
    @current_line = ''
    @chars = []
    # @current_words = []
    # 単純に空白文字でsplitした文字列
    # @splitted_words = []
    # 空白では区切れない一つ以上のトークンを含んだ文字列
    # ex) (a+b-c)など
    # @current_word = ''
    # 最小のトークン
    @current_token = nil
  end

  # 入力にまだトークンは存在するか？
  # @current_token.nil? == true はまだ一度もadvanceが呼ばれていないことを意味する
  # @next_token.nil? == false は次のトークンが存在することを意味する
  def has_more_tokens?
    true unless @io.eof?
  end

  def initial_parse
    begin
      return nil if @io.eof?
      @line = @io.gets.strip
      @line.gsub!(Regexp.new("//.*"), "")
      p "@line: #{@line}" if DEBUG
    end while @line.nil? || @line.empty?

    @line.strip.split("")
  end

  # 入力から次のトークンを取得し、それを現在のトークン（現トークン）とする
  # このルーチンは、hasMoreTokens()がtrueの場合のみ呼び出すことができる
  # また、最初は現トークンは設定されていない
  def tokenize
    if @chars.empty?
      @chars = initial_parse
    end

    @current_token = tokenize_line
    @current_token
  end

  def tokenize_line
    word = ""
    in_string_constant = false
    tokened = false

    while true
      # "test;"のようなIDENTIFIERとSYMBOLの組み合わせを判定する
      if !word.empty? && SYMBOLS.include?(@chars[0])
        return word
      end

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
        tokened = true
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

  def tokened?(word)
  end

  def advance
    token = nil
    until token || @io.eof?
      token = tokenize
    end
    return token
  end

  def treat_comment_part(word)
    # コメント部分はここで全部弾く
    return true if word == "//"
    if ["/*", "/**"].include?(word)
      @in_comment_part = true
      # raise CommentError.new("Comment: #{word}") 
      return true
    end

    if word == "*/"
      @in_comment_part = false
      # raise CommentError.new("Comment: #{word}") 
      return true
    end
  end

  # KEYWORD、 SYMBOL、 IDENTIFIER、 INT_CONST、 STRING_CONST
  # 現トークンの種類を返す
  def token_type
    if KEY_WORDS.include?(@current_token)
      "KEYWORD"
    elsif SYMBOLS.include?(@current_token)
      "SYMBOL"
    elsif @current_token.start_with?('"') && @current_token.end_with?('"')
      "STRING_CONST"
    elsif @current_token =~ /^\d+$/
      "INT_CONST"
    elsif @current_token =~ /^\w+$/
      "IDENTIFIER"
    else
      raise StandardError.new("Unexpected token error: token = #{@current_token}")
    end
  end

  # 現トークンのキーワードを返す。こ のルーチンは、tokenType()が KEYWORDの場合のみ呼び出すこと ができる
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
    'keword'
  end

  # 現トークンの文字を返す
  # このルーチンは、tokenType()がSYMBOLの場合のみ呼び出すことができる
  def symbol
    'symbol'
  end

  # 現トークンの識別子（identiﬁer）を返す
  # このルーチンは、tokenType()がIDENTIFIERの場合のみ呼び出すことができる
  def identifier
    'identifier'
  end

  # 現トークンの整数の値を返す
  # このルーチンは、tokenType()がINT_CONSTの場合のみ呼び出すことができる
  def int_val
    0
  end

  # 現トークンの文字列を返す
  # このルーチンは、tokenType()がSTRING_CONSTの場合のみ呼び出すことができる
  def string_val
    'string_val'
  end
end
