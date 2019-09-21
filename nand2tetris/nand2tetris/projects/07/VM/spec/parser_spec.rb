RSpec.describe Parser do
  let(:mock_file_contents) { file_contents }
  let(:file_contents) { ["push constant 7", "push constant 8", "add"] }
  let(:mock_file_name) { "mock_file_name" }
  let(:parser) { Parser.new(mock_file_name) }

  before do
    allow(IO).to receive(:readlines).and_return(mock_file_contents)
  end

  describe "#initialize" do
    it "return hello" do
      expect(parser.file_contents).not_to be nil
    end
  end

  describe "#hasMoreCommands?" do
    context "parser has any elements" do
      let(:file_contents) { ["add"] }

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
    let(:file_contents) { ["push constant 7", "push constant 8", "add"] }

    context "after initialize" do
      it "set first command" do
        expect { parser.advance }.to change {
          parser.current_command
        }.from(nil).to("push constant 7")
      end
    end

    context "next command" do
      it "set next command" do
        parser.advance
        expect { parser.advance }.to change {
          parser.current_command
        }.from("push constant 7").to("push constant 8")
      end
    end
  end

  describe "#command_type" do
    before do
      parser.advance
    end

    context "C_ARITHMETIC" do
      let(:file_contents) { %w[add sub neg eq gt lt and or not] }

      %w[add sub neg eq gt lt and or not].size.times do
        it do
          expect(parser.command_type).to eq Parser::C_ARITHMETIC
        end
      end
    end

    context "C_PUSH" do
      let(:file_contents) { ["push constant 7"] }
      it { expect(parser.command_type).to eq Parser::C_PUSH }
    end

    context "C_POP" do
      let(:file_contents) { ["pop constant 7"] }
      it { expect(parser.command_type).to eq Parser::C_POP }
    end

    context "C_LABEL" do
      pending "not implement in chapter 7"
      let(:file_contents) { ["pop constant 7"] }
      it { expect(parser.command_type).to eq Parser::C_POP }
    end
  end

  describe "#arg1" do
    context "command type is C_ARITHMETIC" do
      let(:file_contents) { ["add"] }

      it "return command itself" do
        parser.advance
        expect(parser.arg1).to eq "add"
      end
    end

    context "command type is C_RETURN" do
      let(:file_contents) { ["return"] }

      it "raise Error" do
        parser.advance
        expect { parser.arg1 }.to raise_error StandardError
      end
    end

    context "current command has arguments" do
      let(:file_contents) { ["push constant 7"] }

      it "first argument" do
        parser.advance
        expect(parser.arg1).to eq "constant"
      end
    end
  end

  describe "#arg2" do
    context "it return second argument" do
      
      context "command type is C_PUSH" do
        let(:file_contents) { ["push constant 7"] }

        it {
          parser.advance
          expect(parser.arg2).to eq 7
        }
      end

      context "command type is C_POP" do
        let(:file_contents) { ["pop constant 0"] }

        it {
          parser.advance
          expect(parser.arg2).to eq 0
        }
      end

      context "command type is C_CALL or C_FUNCTION" do
        let(:file_contents) { ["function"] }
        pending 'command type is not completely implemented'
        
        it {
          parser.advance
          expect { parser.arg2 }.to raise_error StandardError
        }
      end
    end
  end
end
