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

  describe '#compile_class main() of ConvertToBin.jack' do
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
function Main.main 1
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

  describe '#compile_class nextMask() of ConvertToBin.jack' do
  let(:contents) { 
    <<~"EOS"
class Main {
    function int nextMask(int mask) {
      if (mask = 0) {
        return 1;
      }
      else {
        return mask * 2;
      }
    }
}
EOS
  }

    it 'return output VM code' do
      expected_result = <<~"EOS"
function Main.nextMask 0
  push argument 1
  push constant 0
  eq
  if-goto nextMask-IF-0
  push constant 1
  return
  goto nextMask-IF-1
label nextMask-IF-0
  push argument 1
  push constant 2
  call Math.multiply 2
  return
label nextMask-IF-1
      EOS
      engine.compile_class
      expect { engine.to_vm }.to output(expected_result).to_stdout
    end
  end

  describe '#compile_class fillMemory() of ConvertToBin.jack' do
    let(:contents) { 
      <<~"EOS"
class Main {
    function void fillMemory(int startAddress, int length, int value) {
        while (length > 0) {
            do Memory.poke(startAddress, value);
            let length = length - 1;
            let startAddress = startAddress + 1;
        }
        return;
    }
}
EOS
  }

    it 'return output VM code' do
      expected_result = <<~"EOS"
function Main.fillMemory 0
label fillMemory-WHILE-0
  push argument 2
  push constant 0
  gt
  if-goto fillMemory-WHILE-1
  push argument 1
  push argument 3
  call Memory.poke 2
  push argument 2
  push constant 1
  sub
  pop argument 2
  push argument 1
  push constant 1
  add
  pop argument 1
  goto fillMemory-WHILE-0
label fillMemory-WHILE-1
  return
      EOS
      engine.compile_class
      expect { engine.to_vm }.to output(expected_result).to_stdout
    end
  end

  describe '#compile_class convert() of ConvertToBin.jack' do
    let(:contents) { 
      <<~"EOS"
class Main {
    function void convert(int value) {
      var int mask, position;
      var boolean loop;

      let loop = true;
      while (loop) {
          let position = position + 1;
          let mask = Main.nextMask(mask);

          if (~(position > 16)) {

              if (~((value & mask) = 0)) {
                  do Memory.poke(8000 + position, 1);
              }
              else {
                  do Memory.poke(8000 + position, 0);
              }
          }
          else {
              let loop = false;
          }
      }
      return;
    }
}
EOS
  }

    xit 'return output VM code' do
      expected_result = <<~"EOS"
function Main.convert 1
  push constant 1
  neg
  pop local 2

  push constant 0
  gt
  if-goto fillMemory-WHILE-1
  push argument 1
  push argument 3
  call Memory.poke 2
  push argument 2
  push constant 1
  sub
  pop argument 2
  push argument 1
  push constant 1
  add
  pop argument 1
  goto fillMemory-WHILE-0
label fillMemory-WHILE-1
  return
      EOS
      engine.compile_class
      expect { engine.to_vm }.to output(expected_result).to_stdout
    end
  end
end
