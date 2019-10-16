#!/usr/bin/env ruby

require_relative "./jack_tokenizer"

class JackAnalyzer
  def self.run
    # file_name = File.expand_path(File.basename(ARGV[0]))
    file_name = File.expand_path(ARGV[0])
    tokenizer = JackTokenizer.new(file_name)
    puts("<tokens>")
    while tokenizer.has_more_tokens?
      val_for_judge = tokenizer.advance
      # ここでnilが返ってくることはファイルの最後に空行が続くことを意味する
      break if val_for_judge.nil?
      token = tokenizer.current_token
      next if token.nil?

      token = if tokenizer.token_type == "stringConstant"
        # stringConstantの場合必ず"(ダブルクオート)で囲んでいるのでそれを取り除く
        token[1..-2]
      elsif tokenizer.token_type == "symbol"
        case token
        when "<" then "&lt;"
        when ">" then "&gt;"
        when "&" then "&amp;"
        else token
        end
      else
        token
      end
      token_type = tokenizer.token_type
      # インデントは別途出力する
      puts("<#{token_type}> #{token} </#{token_type}>")
    end
    puts("</tokens>")
  end
end

JackAnalyzer.run
