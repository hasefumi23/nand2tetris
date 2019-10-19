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
    var int total;
    let total = num + str;
    while(key) {
      let key = key;
      do moveSquare(key);
    }
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
      <symbol> { </symbol>
      <statements>
        <doStatement>
          <keyword> do </keyword>
          <identifier> Memory </identifier>
          <symbol> . </symbol>
          <identifier> deAlloc </identifier>
          <symbol> ( </symbol>
          <expressionList>
          </expressionList>
          <symbol> ) </symbol>
          <symbol> ; </symbol>
        </doStatement>
        <returnStatement>
          <keyword> return </keyword>
          <symbol> ; </symbol>
        </returnStatement>
      </statements>
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
      <symbol> { </symbol>
      <varDec>
        <keyword> var </keyword>
        <keyword> int </keyword>
        <identifier> total </identifier>
        <symbol> ; </symbol>
      </varDec>
      <statements>
        <letStatement>
          <keyword> let </keyword>
          <identifier> total </identifier>
          <symbol> = </symbol>
          <expression>
          </expression>
          <symbol> ; </symbol>
        </letStatement>
        <whileStatement>
          <keyword> while </keyword>
          <symbol> ( </symbol>
          <expression>
          </expression>
          <symbol> ) </symbol>
          <symbol> { </symbol>
          <statements>
            <letStatement>
              <keyword> let </keyword>
              <identifier> key </identifier>
              <symbol> = </symbol>
              <expression>
              </expression>
              <symbol> ; </symbol>
            </letStatement>
            <doStatement>
              <keyword> do </keyword>
              <identifier> moveSquare </identifier>
              <symbol> ( </symbol>
              <expressionList>
              </expressionList>
              <symbol> ) </symbol>
              <symbol> ; </symbol>
            </doStatement>
          </statements>
          <symbol> } </symbol>
        </whileStatement>
        <returnStatement>
          <keyword> return </keyword>
          <symbol> ; </symbol>
        </returnStatement>
      </statements>
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

        # <letStatement>
        #   <keyword> let </keyword>
        #   <identifier> total </identifier>
        #   <symbol> = </symbol>
        #   <expression>
        #   </expression>
        #   <symbol> ; </symbol>
        # </letStatement>
