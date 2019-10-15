#!/usr/bin/env ruby

require_relative "./jack_tokenizer"

class JackAnalyzer
  def self.run
    file_name = File.expand_path(File.basename(ARGV[0]))
    tokenizer = JackTokenizer.new(file_name)
    while tokenizer.has_more_tokens?
      tokenizer.advance
      token = tokenizer.current_token
      # ["{", "}", ";"].include?(token) ? (puts " #{token}") : (print " #{token}")
      token_type = tokenizer.token_type
      puts("#{token_type}: #{token}")
    end
  end
end

JackAnalyzer.run
