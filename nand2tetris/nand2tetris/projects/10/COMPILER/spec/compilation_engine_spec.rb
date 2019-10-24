RSpec.describe CompilationEngine do
  let(:contents) { 
    <<~"EOS"
class Square {
  field int x, y;
  static int size;
}
EOS
  }

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
      
      it "raise NoExpectedKeywordError" do
        expect { engine.expect_keyword("class") }.to raise_error(CompilationEngine::NoExpectedKeywordError)
      end
    end

    describe '#expect_symbol' do
      let(:contents) { "class Square []" }
      
      it "raise NoExpectedSymbolError" do
        expect{ engine.expect_symbol("[") }.to raise_error(CompilationEngine::NoExpectedSymbolError)
      end
    end

    describe '#expect_integer_constant' do
      let(:contents) { "class Square []" }
      
      it "raise NotIntegerConstantError" do
        expect{ engine.expect_integer_constant }.to raise_error(CompilationEngine::NotIntegerConstantError)
      end
    end

    describe '#expect_string_constant' do
      let(:contents) { "class Square []" }
      
      it "raise NotStringConstantError" do
        expect{ engine.expect_string_constant }.to raise_error(CompilationEngine::NotStringConstantError)
      end
    end

    describe '#expect_identifier' do
      let(:contents) { "class Square []" }
      
      it "raise NotIdentifierError" do
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

        # <letStatement>
        #   <keyword> let </keyword>
        #   <identifier> total </identifier>
        #   <symbol> = </symbol>
        #   <expression>
        #   </expression>
        #   <symbol> ; </symbol>
        # </letStatement>
