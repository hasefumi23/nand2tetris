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
  pop temp 0
  push constant 0
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
  pop temp 0
  push constant 8000
  call Memory.peek 1
  pop local 0
  push local 0
  call Main.convert 1
  pop temp 0
  push constant 0
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
  push argument 0
  push constant 0
  eq
  not
  if-goto nextMask-IF-0
  push constant 1
  return
  goto nextMask-IF-1
label nextMask-IF-0
  push argument 0
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
  push argument 1
  push constant 0
  gt
  not
  if-goto fillMemory-WHILE-1
  push argument 0
  push argument 2
  call Memory.poke 2
  pop temp 0
  push argument 1
  push constant 1
  sub
  pop argument 1
  push argument 0
  push constant 1
  add
  pop argument 0
  goto fillMemory-WHILE-0
label fillMemory-WHILE-1
  push constant 0
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

    it 'return output VM code' do
      expected_result = <<~"EOS"
function Main.convert 3
  push constant 1
  neg
  pop local 2
label convert-WHILE-0
  push local 2
  not
  if-goto convert-WHILE-1
  push local 1
  push constant 1
  add
  pop local 1
  push local 0
  call Main.nextMask 1
  pop local 0
  push local 1
  push constant 16
  gt
  not
  not
  if-goto convert-IF-2
  push argument 0
  push local 0
  and
  push constant 0
  eq
  not
  not
  if-goto convert-IF-4
  push constant 8000
  push local 1
  add
  push constant 1
  call Memory.poke 2
  pop temp 0
  goto convert-IF-5
label convert-IF-4
  push constant 8000
  push local 1
  add
  push constant 0
  call Memory.poke 2
  pop temp 0
label convert-IF-5
  goto convert-IF-3
label convert-IF-2
  push constant 0
  pop local 2
label convert-IF-3
  goto convert-WHILE-0
label convert-WHILE-1
  push constant 0
  return
      EOS
      engine.compile_class
      expect { engine.to_vm }.to output(expected_result).to_stdout
    end
  end

  describe '#compile_class constructor of Square of Square.jack' do
    let(:contents) { 
      <<~"EOS"
class Square {
  field int x, y;
  field int size;
  /** Constructs a new square with a given location and size. */
  constructor Square new(int Ax, int Ay, int Asize) {
    let x = Ax;
    let y = Ay;
    let size = Asize;
    do draw();
    return this;
  }
}
EOS
  }

    it 'return output VM code' do
      expected_result = <<~"EOS"
function Square.new 0
  push constant 3
  call Memory.alloc 1
  pop pointer 0
  push argument 0
  pop this 0
  push argument 1
  pop this 1
  push argument 2
  pop this 2
  push pointer 0
  call Square.draw 1
  pop temp 0
  push pointer 0
  return
      EOS
      engine.compile_class
      expect { engine.to_vm }.to output(expected_result).to_stdout
    end
  end

  describe '#compile_class main() of Average.jack' do
    let(:contents) { 
      <<~"EOS"
class Main {
   function void main() {
     var Array a; 
     var int length;
     var int i, sum;

     let length = Keyboard.readInt("How many numbers? ");
     let a = Array.new(length); // constructs the array
     
     let i = 0;
     while (i < length) {
        let a[i] = Keyboard.readInt("Enter a number: ");
        let sum = sum + a[i];
        let i = i + 1;
     }
     
     do Output.printString("The average is ");
     do Output.printInt(sum / length);
     return;
   }
}
EOS
  }

    it 'return output VM code' do
      expected_result = <<~"EOS"
function Main.main 4
  push constant 18
  call String.new 1
  push constant 72
  call String.appendChar 2
  push constant 111
  call String.appendChar 2
  push constant 119
  call String.appendChar 2
  push constant 32
  call String.appendChar 2
  push constant 109
  call String.appendChar 2
  push constant 97
  call String.appendChar 2
  push constant 110
  call String.appendChar 2
  push constant 121
  call String.appendChar 2
  push constant 32
  call String.appendChar 2
  push constant 110
  call String.appendChar 2
  push constant 117
  call String.appendChar 2
  push constant 109
  call String.appendChar 2
  push constant 98
  call String.appendChar 2
  push constant 101
  call String.appendChar 2
  push constant 114
  call String.appendChar 2
  push constant 115
  call String.appendChar 2
  push constant 63
  call String.appendChar 2
  push constant 32
  call String.appendChar 2
  call Keyboard.readInt 1
  pop local 1
  push local 1
  call Array.new 1
  pop local 0
  push constant 0
  pop local 2
label main-WHILE-0
  push local 2
  push local 1
  lt
  not
  if-goto main-WHILE-1
  push local 0
  push local 2
  add
  pop pointer 1
  push constant 16
  call String.new 1
  push constant 69
  call String.appendChar 2
  push constant 110
  call String.appendChar 2
  push constant 116
  call String.appendChar 2
  push constant 101
  call String.appendChar 2
  push constant 114
  call String.appendChar 2
  push constant 32
  call String.appendChar 2
  push constant 97
  call String.appendChar 2
  push constant 32
  call String.appendChar 2
  push constant 110
  call String.appendChar 2
  push constant 117
  call String.appendChar 2
  push constant 109
  call String.appendChar 2
  push constant 98
  call String.appendChar 2
  push constant 101
  call String.appendChar 2
  push constant 114
  call String.appendChar 2
  push constant 58
  call String.appendChar 2
  push constant 32
  call String.appendChar 2
  call Keyboard.readInt 1
  pop that 0
  push local 3
  push local 0
  push local 2
  add
  pop pointer 1
  push that 0
  add
  pop local 3
  push local 2
  push constant 1
  add
  pop local 2
  goto main-WHILE-0
label main-WHILE-1
  push constant 15
  call String.new 1
  push constant 84
  call String.appendChar 2
  push constant 104
  call String.appendChar 2
  push constant 101
  call String.appendChar 2
  push constant 32
  call String.appendChar 2
  push constant 97
  call String.appendChar 2
  push constant 118
  call String.appendChar 2
  push constant 101
  call String.appendChar 2
  push constant 114
  call String.appendChar 2
  push constant 97
  call String.appendChar 2
  push constant 103
  call String.appendChar 2
  push constant 101
  call String.appendChar 2
  push constant 32
  call String.appendChar 2
  push constant 105
  call String.appendChar 2
  push constant 115
  call String.appendChar 2
  push constant 32
  call String.appendChar 2
  call Output.printString 1
  pop temp 0
  push local 3
  push local 1
  call Math.divide 2
  call Output.printInt 1
  pop temp 0
  push constant 0
  return
      EOS
      engine.compile_class
      expect { engine.to_vm }.to output(expected_result).to_stdout
    end
  end
end
