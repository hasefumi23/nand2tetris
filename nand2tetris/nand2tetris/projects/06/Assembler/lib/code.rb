class Code
  class CodeSyntaxError < StandardError; end

  class << self
    def dest(mnemonic)
      # dest ニーモニックのバイナリコードを返す
      case mnemonic
      when nil then "000"
      when "M" then "001"
      when "D" then "010"
      when "MD" then "011"
      when "A" then "100"
      when "AM" then "101"
      when "AD" then "110"
      when "AMD" then "111"
      else raise CodeSyntaxError.new("Passed mnemonic is #{mnemonic.inspect}")
      end
    end

    def comp(mnemonic)
      # comp ニーモニックのバイナリコードを返す
      case mnemonic
      when "0" then "0101010"
      when "1" then "0111111"
      when "-1" then "0111010"
      when "D" then "0001100"
      when "A" then "0110000"
      when "!D" then "0001101"
      when "!A" then "0110001"
      when "-D" then "0001111"
      when "-A" then "0110011"
      when "D+1" then "0011111"
      when "A+1" then "0110111"
      when "D-1" then "0001110"
      when "A-1" then "0110010"
      when "D+A" then "0000010"
      when "D-A" then "0010011"
      when "A-D" then "0000111"
      when "D&A" then "0000000"
      when "D|A" then "0010101"
      when "M" then "1110000"
      when "!M" then "1110001"
      when "-M" then "1110011"
      when "M+1" then "1110111"
      when "M-1" then "1110010"
      when "D+M" then "1000010"
      when "D-M" then "1010011"
      when "M-D" then "1000111"
      when "D&M" then "1000000"
      when "D|M" then "1010101"
      else raise CodeSyntaxError.new("Passed mnemonic is #{mnemonic.inspect}")
      end
    end

    def jump(mnemonic)
      #  jump ニーモニックのバイナリコードを返す
      case mnemonic
      when nil then "000"
      when "JGT" then "001"
      when "JEQ" then "010"
      when "JGE" then "011"
      when "JLT" then "100"
      when "JNE" then "101"
      when "JLE" then "110"
      when "JMP" then "111"
      else raise CodeSyntaxError.new("Passed mnemonic is #{mnemonic.inspect}")
      end
    end
  end
end
