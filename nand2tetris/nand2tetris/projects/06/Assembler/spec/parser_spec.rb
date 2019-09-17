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
      expect(parser.symbol).to eq "100"
    end
  end
end
