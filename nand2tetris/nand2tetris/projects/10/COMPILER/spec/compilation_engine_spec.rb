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

  describe '#compile_class of Seven.jack' do
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

  describe '#compile_class of ConvertToBin.jack' do
  let(:contents) { 
    <<~"EOS"
class Main {
  /**
    * Initializes RAM[8001]..RAM[8016] to -1,
    * and converts the value in RAM[8000] to binary.
    */
  function void main() {
      var int value;
      do Main.fillMemory(8001, 16, -1); // sets RAM[8001]..RAM[8016] to -1
      let value = Memory.peek(8000);    // reads a value from RAM[8000]
      do Main.convert(value);           // performs the conversion
      return;
  }
}
EOS
  }

    it 'return output VM code' do
      expected_result = <<~"EOS"
function Main.main 0
push constant 8001
push constant 16
push constant 1
neg
call Main.fillMemory 3
push constant 8000
call Memory.peek 1
pop local 0
push local 0
call Main.convert 1
return
      EOS
      engine.compile_class
      expect { engine.to_vm }.to output(expected_result).to_stdout
    end
  end
end
