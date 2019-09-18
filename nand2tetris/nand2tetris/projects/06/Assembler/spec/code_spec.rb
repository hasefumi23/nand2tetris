require_relative './../lib/code.rb'

RSpec.describe Code do
  describe "dest" do
    context "normal case" do
      it { expect(Code.dest(nil)).to eq "000" }
      it { expect(Code.dest("M")).to eq "001" }
      it { expect(Code.dest("D")).to eq "010" }
      it { expect(Code.dest("MD")).to eq "011" }
      it { expect(Code.dest("A")).to eq "100" }
      it { expect(Code.dest("AM")).to eq "101" }
      it { expect(Code.dest("AD")).to eq "110" }
      it { expect(Code.dest("AMD")).to eq "111" }
      it { expect { Code.dest("INVALID") }.to raise_error Code::CodeSyntaxError }
    end
  end

  describe "comp" do
    context "A is specified in mnemonic" do
      it { expect(Code.comp("0")).to eq "0101010" }
      it { expect(Code.comp("1")).to eq "0111111" }
      it { expect(Code.comp("-1")).to eq "0111010" }
      it { expect(Code.comp("D")).to eq "0001100" }
      it { expect(Code.comp("A")).to eq "0110000" }
      it { expect(Code.comp("!D")).to eq "0001101" }
      it { expect(Code.comp("!A")).to eq "0110001" }
      it { expect(Code.comp("-D")).to eq "0001111" }
      it { expect(Code.comp("-A")).to eq "0110011" }
      it { expect(Code.comp("D+1")).to eq "0011111" }
      it { expect(Code.comp("A+1")).to eq "0110111" }
      it { expect(Code.comp("D-1")).to eq "0001110" }
      it { expect(Code.comp("A-1")).to eq "0110010" }
      it { expect(Code.comp("D+A")).to eq "0000010" }
      it { expect(Code.comp("D-A")).to eq "0010011" }
      it { expect(Code.comp("A-D")).to eq "0000111" }
      it { expect(Code.comp("D&A")).to eq "0000000" }
      it { expect(Code.comp("D|A")).to eq "0010101" }
      it { expect { Code.comp(nil) }.to raise_error Code::CodeSyntaxError }
      it { expect { Code.comp("invalid") }.to raise_error Code::CodeSyntaxError }
    end

    context "M is specified in mnemonic" do
      it { expect(Code.comp("M")).to eq "1110000" }
      it { expect(Code.comp("!M")).to eq "1110001" }
      it { expect(Code.comp("-M")).to eq "1110011" }
      it { expect(Code.comp("M+1")).to eq "1110111" }
      it { expect(Code.comp("M-1")).to eq "1110010" }
      it { expect(Code.comp("D+M")).to eq "1000010" }
      it { expect(Code.comp("D-M")).to eq "1010011" }
      it { expect(Code.comp("M-D")).to eq "1000111" }
      it { expect(Code.comp("D&M")).to eq "1000000" }
      it { expect(Code.comp("D|M")).to eq "1010101" }
      it { expect { Code.comp(nil) }.to raise_error Code::CodeSyntaxError }
      it { expect { Code.comp("invalid") }.to raise_error Code::CodeSyntaxError }
    end
  end

  describe "jump" do
    context "normal case" do
      it { expect(Code.jump(nil)).to eq "000" }
      it { expect(Code.jump("JGT")).to eq "001" }
      it { expect(Code.jump("JEQ")).to eq "010" }
      it { expect(Code.jump("JGE")).to eq "011" }
      it { expect(Code.jump("JLT")).to eq "100" }
      it { expect(Code.jump("JNE")).to eq "101" }
      it { expect(Code.jump("JLE")).to eq "110" }
      it { expect(Code.jump("JMP")).to eq "111" }
      it { expect { Code.jump("INVALID") }.to raise_error Code::CodeSyntaxError }
    end
  end
end
