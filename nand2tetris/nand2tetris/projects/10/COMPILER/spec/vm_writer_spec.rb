RSpec.describe VMWriter do
  let(:w) { VMWriter.new }

  describe 'test method' do
    it 'returns hello vm' do
      expect(VMWriter.hello).to eq("hello")
    end
  end

  # Segment: (CONST、 ARG、LOCAL、 STATIC、THIS、 THAT、POINTER、 TEMP)
  describe '#write_push' do
    it 'write push VM code' do
      expect { w.write_push("ARG", 0) }.to output("push argument 0\n").to_stdout
      expect { w.write_push("CONST", 2) }.to output("push constant 2\n").to_stdout
      expect { w.write_push("POINTER", 0) }.to output("push pointer 0\n").to_stdout
    end
  end

  describe '#write_pop' do
    it "write pop VM code" do
      expect { w.write_pop("ARG", 0) }.to output("pop argument 0\n").to_stdout
      expect { w.write_pop("CONST", 2) }.to output("pop constant 2\n").to_stdout
      expect { w.write_pop("POINTER", 0) }.to output("pop pointer 0\n").to_stdout
    end
  end

  describe '#write_arithmetic' do
    it "write pop VM code" do
      expect { w.write_arithmetic("ADD") }.to output("add\n").to_stdout
      expect { w.write_arithmetic("SUB") }.to output("sub\n").to_stdout
      expect { w.write_arithmetic("NEG") }.to output("neg\n").to_stdout
    end
  end

  describe '#write_label' do
    it "write label VM code" do
      expect { w.write_label("IF_LABEL") }.to output("label IF_LABEL\n").to_stdout
    end
  end

  describe '#write_goto' do
    it "write goto VM code" do
      expect { w.write_goto("WHILE_EXP0") }.to output("goto WHILE_EXP0\n").to_stdout
    end
  end

  describe '#write_if' do
    it "write if VM code" do
      expect { w.write_if("IF_TRUE0") }.to output("if-goto IF_TRUE0\n").to_stdout
    end
  end

  describe '#write_call' do
    it "write call VM code" do
      expect { w.write_call("String.eraseLastChar", 1) }.to output("call String.eraseLastChar 1\n").to_stdout
    end
  end

  describe '#write_function' do
    it "write function VM code" do
      expect { w.write_function("Keyboard.readInt", 2) }.to output("function Keyboard.readInt 2\n").to_stdout
    end
  end

  describe '#write_return' do
    it "write return VM code" do
      expect { w.write_return }.to output("return\n").to_stdout
    end
  end
end
