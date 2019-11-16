RSpec.describe CompilationEngine do
  let(:contents) { 
    <<~"EOS"
class Main {
  function void main() {
    do Output.printInt(1 + (2 * 3));
    return;
  }
}
EOS
  }

  let(:string_io) { StringIO.new(contents) }
  let(:tokenizer) { JackTokenizer.new("file_path") }
  let(:engine) { CompilationEngine.new(tokenizer) }

  before do
    allow(File).to receive(:open).and_return(string_io)
  end

  describe '#compile_class' do
    it 'return output VM code' do
      expected_result = <<~"EOS"
function Main.main 0
push constant 1
push constant 2
push constant 3
call Math.multiply 2
add
call Output.printInt 1
return
      EOS
      engine.compile_class
      expect { engine.to_vm }.to output(expected_result).to_stdout
    end
  end
end
