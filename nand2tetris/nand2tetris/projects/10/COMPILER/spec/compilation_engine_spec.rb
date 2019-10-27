RSpec.describe CompilationEngine do
  let(:contents) { 
    <<~"EOS"
class Square {
  field int x, y;
  static int size;

  constructor SquareGame new() {
    var Square square;
    let square = square;
    while (key) {
      let key = -key;
      do moveSquare();
      do square.run();
    }
    return;
  }

  method void disposeA(int num, char str) {
    var int total;
    if (key) {
      let exit = exit;
    } else {
      let exit = exit;
    }
  }
}
EOS
  }
      # do square.run(0, 0, 30);

  # constructor SquareGame new() {
  #   let square = square;
  #   let direction = direction;
  #   return square;
  # }

  # method void disposeA(int num, char str) {
  # }
  let(:string_io) { StringIO.new(contents) }
  let(:tokenizer) { JackTokenizer.new("file_path") }
  let(:engine) { CompilationEngine.new(tokenizer) }

  before do
    allow(File).to receive(:open).and_return(string_io)
  end

  describe 'expect method' do
    describe '#expect_keyword' do
      let(:contents) { "clazz Square {}" }
      
      xit "raise NoExpectedKeywordError" do
        expect { engine.expect_keyword("class") }.to raise_error(CompilationEngine::NoExpectedKeywordError)
      end
    end

    describe '#expect_symbol' do
      let(:contents) { "class Square []" }
      
      xit "raise NoExpectedSymbolError" do
        expect{ engine.expect_symbol("[") }.to raise_error(CompilationEngine::NoExpectedSymbolError)
      end
    end

    describe '#expect_integer_constant' do
      let(:contents) { "class Square []" }
      
      xit "raise NotIntegerConstantError" do
        expect{ engine.expect_integer_constant }.to raise_error(CompilationEngine::NotIntegerConstantError)
      end
    end

    describe '#expect_string_constant' do
      let(:contents) { "class Square []" }
      
      xit "raise NotStringConstantError" do
        expect{ engine.expect_string_constant }.to raise_error(CompilationEngine::NotStringConstantError)
      end
    end

    describe '#expect_identifier' do
      let(:contents) { "class Square []" }
      
      xit "raise NotIdentifierError" do
        expect{ engine.expect_identifier }.to raise_error(CompilationEngine::NotIdentifierError)
      end
    end
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
  <subroutineDec>
    <keyword> constructor </keyword>
    <identifier> SquareGame </identifier>
    <identifier> new </identifier>
    <symbol> ( </symbol>
    <parameterList>
    </parameterList>
    <symbol> ) </symbol>
    <subroutineBody>
      <symbol> { </symbol>
      <varDec>
        <keyword> var </keyword>
        <identifier> Square </identifier>
        <identifier> square </identifier>
        <symbol> ; </symbol>
      </varDec>
      <statements>
        <letStatement>
          <keyword> let </keyword>
          <identifier> square </identifier>
          <symbol> = </symbol>
          <expression>
            <term>
              <identifier> square </identifier>
            </term>
          </expression>
          <symbol> ; </symbol>
        </letStatement>
        <whileStatement>
          <keyword> while </keyword>
          <symbol> ( </symbol>
          <expression>
            <term>
              <identifier> key </identifier>
            </term>
          </expression>
          <symbol> ) </symbol>
          <symbol> { </symbol>
          <statements>
            <letStatement>
              <keyword> let </keyword>
              <identifier> key </identifier>
              <symbol> = </symbol>
              <expression>
                <term>
                  <symbol> - </symbol>
                  <term>
                    <identifier> key </identifier>
                  </term>
                </term>
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
            <doStatement>
              <keyword> do </keyword>
              <identifier> square </identifier>
              <symbol> . </symbol>
              <identifier> run </identifier>
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
      <symbol> } </symbol>
    </subroutineBody>
  </subroutineDec>
  <subroutineDec>
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
        <ifStatement>
          <keyword> if </keyword>
          <symbol> ( </symbol>
          <expression>
            <term>
              <identifier> key </identifier>
            </term>
          </expression>
          <symbol> ) </symbol>
          <symbol> { </symbol>
          <statements>
            <letStatement>
              <keyword> let </keyword>
              <identifier> exit </identifier>
              <symbol> = </symbol>
              <expression>
                <term>
                  <identifier> exit </identifier>
                </term>
              </expression>
              <symbol> ; </symbol>
            </letStatement>
          </statements>
          <symbol> } </symbol>
          <keyword> else </keyword>
          <symbol> { </symbol>
          <statements>
            <letStatement>
              <keyword> let </keyword>
              <identifier> exit </identifier>
              <symbol> = </symbol>
              <expression>
                <term>
                  <identifier> exit </identifier>
                </term>
              </expression>
              <symbol> ; </symbol>
            </letStatement>
          </statements>
          <symbol> } </symbol>
        </ifStatement>
      </statements>
      <symbol> } </symbol>
    </subroutineBody>
  </subroutineDec>
  <symbol> } </symbol>
</class>
      EOS
      expect { engine.compile_class }.to output(expected_result).to_stdout
    end
  end
end
  # <subroutineDec>
  #   <keyword> constructor </keyword>
  #   <identifier> SquareGame </identifier>
  #   <identifier> new </identifier>
  #   <symbol> ( </symbol>
  #   <parameterList>
  #   </parameterList>
  #   <symbol> ) </symbol>
  #   <subroutineBody>
  #     <symbol> { </symbol>
  #     <statements>
  #       <letStatement>
  #         <keyword> let </keyword>
  #         <identifier> square </identifier>
  #         <symbol> = </symbol>
  #         <expression>
  #           <term>
  #             <identifier> square </identifier>
  #           </term>
  #         </expression>
  #         <symbol> ; </symbol>
  #       </letStatement>
  #       <letStatement>
  #         <keyword> let </keyword>
  #         <identifier> direction </identifier>
  #         <symbol> = </symbol>
  #         <expression>
  #           <term>
  #             <identifier> direction </identifier>
  #           </term>
  #         </expression>
  #         <symbol> ; </symbol>
  #       </letStatement>
  #       <returnStatement>
  #         <keyword> return </keyword>
  #         <expression>
  #           <term>
  #             <identifier> square </identifier>
  #           </term>
  #         </expression>
  #         <symbol> ; </symbol>
  #       </returnStatement>
  #     </statements>
  #     <symbol> } </symbol>
  #   </subroutineBody>
  # </subroutineDec>
  # <subroutineDec>
  #   <keyword> method </keyword>
  #   <keyword> void </keyword>
  #   <identifier> disposeA </identifier>
  #   <symbol> ( </symbol>
  #   <parameterList>
  #     <keyword> int </keyword>
  #     <identifier> num </identifier>
  #     <symbol> , </symbol>
  #     <keyword> char </keyword>
  #     <identifier> str </identifier>
  #   </parameterList>
  #   <symbol> ) </symbol>
  #   <subroutineBody>
  #     <symbol> { </symbol>
  #     <varDec>
  #       <keyword> var </keyword>
  #       <keyword> int </keyword>
  #       <identifier> total </identifier>
  #       <symbol> ; </symbol>
  #     </varDec>
  #     <symbol> } </symbol>
  # </subroutineDec>

# method void disposeA(int num, char str) {
#   do Memory.deAlloc(this);
#   return;
# }

# method void dispose() {
#   do Memory.deAlloc(this);
#   return;
# }

            # <doStatement>
            #   <keyword> do </keyword>
            #   <identifier> square </identifier>
            #   <symbol> . </symbol>
            #   <identifier> run </identifier>
            #   <symbol> ( </symbol>
            #   <expressionList>
            #     <expression>
            #       <term>
            #         <integerConstant> 0 </integerConstant>
            #       </term>
            #     </expression>
            #     <symbol> , </symbol>
            #     <expression>
            #       <term>
            #         <integerConstant> 0 </integerConstant>
            #       </term>
            #     </expression>
            #     <symbol> , </symbol>
            #     <expression>
            #       <term>
            #         <integerConstant> 30 </integerConstant>
            #       </term>
            #     </expression>
            #   </expressionList>
            #   <symbol> ) </symbol>
            #   <symbol> ; </symbol>
            # </doStatement>
