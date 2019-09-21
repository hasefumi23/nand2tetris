require "pp"

RSpec.describe Parser do
  let(:file_contents) { "" }
  let(:string_io) { StringIO.new(file_contents) }
  let(:code_writer) { CodeWriter.new(string_io) }

  before do
    allow(File).to receive(:open).and_yield(string_io)
  end

  describe "#initialize" do
    it "initialize" do
      out = %w[@256 D=A @SP M=D]
      expect(code_writer.out_file.string).to eq("#{out.join("\n")}\n")
    end
  end

  describe "set_file_name" do
    pending 'reason'
  end

  describe "write_arithmetic" do
    it {
      code_writer.write_push_pop("push", "constant", 7)
      code_writer.write_push_pop("push", "constant", 8)
      code_writer.write_arithmetic("add")
      out = %w[@256 D=M @257 D=M+D @256 M=D @257 D=A @SP M=D]
      expect(code_writer.out_file.string).to include("#{out.join("\n")}")
    }
  end

  describe "#write_push_pop" do

    context "push constant" do
      it "output assemble command" do
        out = %w[@7 D=A @256 M=D]
        code_writer.write_push_pop("push", "constant", 7)
        expect(code_writer.out_file.string).to include("#{out.join("\n")}")
      end

      it "increment @stack_point of code_writer" do
        expect {
          code_writer.write_push_pop("push", "constant", 7)
        }.to change {
          code_writer.stack_point
        }.by(1)
      end 
    end
  end

  describe "close" do
  end
end
