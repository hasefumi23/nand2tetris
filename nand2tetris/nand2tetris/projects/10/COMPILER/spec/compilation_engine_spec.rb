RSpec.describe CompilationEngine do
  let(:contents) { 
    <<~"EOS"
class Square {
  field int x, y;
  static int size;

  method void dispose() {
    do Memory.deAlloc(this);
    return;
  }

  method void disposeA(int num, char str) {
    do Memory.deAlloc(this);
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

  describe 'minimal compile_class' do
    let(:contents) { 
    <<~"EOS"
class Square {
}
    EOS
    }
    it 'output only class tokens' do
      expected_result = <<~"EOS"
<class>
  <keyword> class </keyword>
  <identifier> Square </identifier>
  <symbol> { </symbol>
  <symbol> } </symbol>
</class>
      EOS

      expect { engine.compile_class }.to output(expected_result).to_stdout
    end
  end

  describe 'compile_class' do
    it 'return current token' do
      expected_result = <<~"EOS"
<class>
  <keyword> class </keyword>
  <identifier> Square </identifier>
  <symbol> { </symbol>
  <classVarDec>
    <keyword> field </keyword>
    <keyword> int </keyword>
    <identifier> x </identifier>
    <symbol> , </symbol>
    <identifier> y </identifier>
    <symbol> ; </symbol>
  </classVarDec>
  <classVarDec>
    <keyword> static </keyword>
    <keyword> int </keyword>
    <identifier> size </identifier>
    <symbol> ; </symbol>
  </classVarDec>
  <subroutine>
    <keyword> method </keyword>
    <keyword> void </keyword>
    <identifier> dispose </identifier>
    <symbol> ( </symbol>
    <parameterList>
    </parameterList>
    <symbol> ) </symbol>
    <subroutineBody>
    </subroutineBody>
  </subroutine>
  <subroutine>
    <keyword> method </keyword>
    <keyword> void </keyword>
    <identifier> disposeA </identifier>
    <symbol> ( </symbol>
    <parameterList>
      <keyword> int </keyword>
      <identifier> num </identifier>
      <symbol> , </symbol>
      <keyword> char </keyword>
      <identifier> str </identifier>
    </parameterList>
    <symbol> ) </symbol>
    <subroutineBody>
    </subroutineBody>
  </subroutine>
  <symbol> } </symbol>
</class>
      EOS
      expect { engine.compile_class }.to output(expected_result).to_stdout
    end
  end
end

# method void disposeA(int num, char str) {
#   do Memory.deAlloc(this);
#   return;
# }

# method void dispose() {
#   do Memory.deAlloc(this);
#   return;
# }
