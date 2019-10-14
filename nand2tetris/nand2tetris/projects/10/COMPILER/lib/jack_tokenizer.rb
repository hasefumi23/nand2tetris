# frozen_string_literal: true
require 'pry'

class JackTokenizer
  class CommentError < StandardError; end

  attr_accessor :curren_token

  KEY_WORDS = %w[class constructor function method field static var int char boolean void true false null this let do if else while return]
  SYMBOLS = %w[{ } ( ) [ ] . , ; + - * / & | < > = ~]

  # 理想は一文字ずつ読み込んで都度判定ロジックを走らせてトークンかコメントかを
  # 判断する処理だが、ロジックが必要以上に複雑になり可読性も落ちるため
  # 妥協して、コメントは可能な限り最初に全部削除する
  # ただし複数行に渡るコメントは未削除
  def initialize(file_name)
    @io = File.open(file_name)
    # while line = @io.gets
    #   strings = line.split('')
    #   p strings
    # end
    @line = nil
    @current_line = ''
    @line_pistion = 0
    @current_words = []
    # 単純に空白文字でsplitした文字列
    @current_chars = []
    @splitted_words = []
    # 空白では区切れない一つ以上のトークンを含んだ文字列
    # ex) (a+b-c)など
    @current_word = ''
    # 最小のトークン
    @curren_token = nil
  end

  # 入力にまだトークンは存在するか？
  # @curren_token.nil? == true はまだ一度もadvanceが呼ばれていないことを意味する
  # @next_token.nil? == false は次のトークンが存在することを意味する
  def has_more_tokens?
    true unless @io.eof?
  end

  # 入力から次のトークンを取得し、それを現在のトークン（現トークン）とする
  # このルーチンは、hasMoreTokens()がtrueの場合のみ呼び出すことができる
  # また、最初は現トークンは設定されていない
  def tokenize
    # class Main
    if @splitted_words.empty? && @current_words.empty?
      begin
        return nil if @io.eof?
        @line = @io.gets.strip
        # if @line == "let i = i | j;"
        #   binding.pry
        # end
        next if @line.start_with?("//")
      end while @line.nil? || @line.empty?

      @line.gsub!(Regexp.new("//.*"), "")
      return nil if @line.empty?
      
      # コメントは扱いが厄介なのでsplitで分割できるように空白を差し込む
      @current_words = @line.gsub(Regexp.union(%w[/** /* //]), ' \& ').split
    end

    temp_word = @current_words.shift
    return nil if treat_comment_part(temp_word)
    # /** や /* によるコメント部分だったらスキップする
    return nil if @in_comment_part

    if @splitted_words.empty?
      # コメント部分のスキップ後にKEY_WORDとSYMBOLを分解する
      @splitted_words = temp_word.gsub(Regexp.union(KEY_WORDS), ' \& ')
                  .gsub(Regexp.union(SYMBOLS), ' \& ')
                  .split
    end

    @word = @splitted_words.shift
    if SYMBOLS.any? { |sym| @word.start_with?(sym) }
      @curren_token = @word
      return @curren_token
    end

    if KEY_WORDS.include?(@word)
      @curren_token = @word
      return @curren_token
    end

    @curren_token = @word
    # nil
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
    'token'
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
