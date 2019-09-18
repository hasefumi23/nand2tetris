require_relative './../lib/parser.rb'

RSpec.describe Parser do
  let(:mock_file_contents) { file_contents }
  let(:mock_file_name) { "mock_file_name" }
  let(:parser) { Parser.new(mock_file_name) }

  before do
    allow(IO).to receive(:readlines).and_return(mock_file_contents)
  end

  describe "#initialize" do
    let(:file_contents) { ["@i", "i=1"] }

    it "initialize Parser" do
      expect(parser).not_to be nil
      expect(parser.file_contents.size).to eq 2
    end
  end

  describe "#hasMoreCommands?" do
    context "parser has any elements" do
      let(:file_contents) { ["@i", "i=1"] }

      it "retuns true" do
        expect(parser.hasMoreCommands?).to be true
      end
    end

    context "parser has no elements" do
      let(:file_contents) { [] }

      it "retuns false" do
        expect(parser.hasMoreCommands?).to be false
      end
    end
  end

  describe "#advance" do
    let(:file_contents) { ["@i", "i=1"] }

    context "after initialize" do
      it "set first command" do
        expect { parser.advance }.to change {
          parser.current_command
        }.from(nil).to("@i")
      end
    end

    context "next command" do
      it "set next command" do
        parser.advance
        expect { parser.advance }.to change {
          parser.current_command
        }.from("@i").to("i=1")
      end
    end
  end

  describe "#symbol" do
    let(:file_contents) { ["@100"] }

    it "returns number part" do
      parser.advance
      expect(parser.symbol).to eq "0000000001100100"
    end
  end

  describe "#dest" do
    # コマンドに'='が含まれている場合、destニーモニックは存在する
    context "current command has dest mnemonic" do
      let(:file_contents) { ["D=M"] }
      
      it "returns number part" do
        parser.advance
        expect(parser.dest).to eq "D"
      end
    end

    context "current command don't have dest mnemonic" do
      let(:file_contents) { ["0;JMP"] }

      it "returns nil" do
        parser.advance
        expect(parser.dest).to be nil
      end
    end
  end

  describe "#jump" do
    # コマンドに';'が含まれている場合、jump ニーモニックは存在する
    context "current command has jump mnemonic" do
      let(:file_contents) { ["0;JMP"] }
      
      it "returns number part" do
        parser.advance
        expect(parser.jump).to eq "JMP"
      end
    end

    context "current command don't have jump mnemonic" do
      let(:file_contents) { ["D=M"] }

      it "returns nil" do
        parser.advance
        expect(parser.jump).to be nil
      end
    end
  end

  describe "#comp" do
    # コマンドに';'が含まれている場合、comp ニーモニックは存在する
    context "current command has comp mnemonic with dest mnemonic" do
      let(:file_contents) { ["DM=M+A"] }
      
      it "returns number part" do
        parser.advance
        expect(parser.comp).to eq "M+A"
      end
    end

    context "current command has comp mnemonic with jump mnemonic" do
      let(:file_contents) { ["0;JMP"] }

      it "returns comp mnemonic" do
        parser.advance
        expect(parser.comp).to eq "0"
      end
    end

    context "invalid syntax" do
      let(:file_contents) { ["D"] }

      it "raise Parser::AssemblerSyntaxError" do
        parser.advance
        expect { parser.comp }.to raise_error Parser::AssemblerSyntaxError
      end
    end
  end
end
