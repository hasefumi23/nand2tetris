#!/usr/bin/env ruby

require_relative "./jack_tokenizer"
require_relative "./compilation_engine"

class JackAnalyzer
  def run
    # file_name = File.expand_path(File.basename(ARGV[0]))
    file_name = File.expand_path(ARGV[0])
    @tokenizer = JackTokenizer.new(file_name)
    engine = CompilationEngine.new(@tokenizer)
    engine.compile_class
    # print_tokens_only
  end

  def print_tokens_only
    puts("<tokens>")
    while @tokenizer.has_more_tokens?
      val_for_judge = @tokenizer.advance
      # ここでnilが返ってくることはファイルの最後に空行が続くことを意味するのでループを抜ける
      break if val_for_judge.nil?
      token = @tokenizer.current_token
      next if token.nil?

      token_type = @tokenizer.token_type
      puts("<#{token_type}> #{token} </#{token_type}>")
    end
    puts("</tokens>")
  end
end

JackAnalyzer.new.run
