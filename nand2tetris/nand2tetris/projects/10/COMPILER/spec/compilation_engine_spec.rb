RSpec.describe CompilationEngine do
  let(:contents) { 
    <<~"EOS"
// This file is part of www.nand2tetris.org
// and the book "The Elements of Computing Systems"
// by Nisan and Schocken, MIT Press.
// File name: projects/10/Square/Main.jack

// (derived from projects/09/Square/Main.jack, with testing additions)

/** Initializes a new Square Dance game and starts running it. */
class Main {
    static boolean test;    // Added for testing -- there is no static keyword
                            // in the Square files.
    function void main() {
      var SquareGame game;
      let game = SquareGame.new();
      do game.run();
      do game.dispose();
      return;
    }

    function void test() {  // Added to test Jack syntax that is not use in
        var int i, j;       // the Square files.
        var String s;
        var Array a;
        if (false) {
            let s = "string constant";
            let s = null;
            let a[1] = a[2];
        }
        else {              // There is no else keyword in the Square files.
            let i = i * (-j);
            let j = j / (-2);   // note: unary negate constant 2
            let i = i | j;
        }
        return;
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
  <identifier> Main </identifier>
  <symbol> { </symbol>
  <classVarDec>
    <keyword> static </keyword>
    <keyword> boolean </keyword>
    <identifier> test </identifier>
    <symbol> ; </symbol>
  </classVarDec>
  <subroutineDec>
    <keyword> function </keyword>
    <keyword> void </keyword>
    <identifier> main </identifier>
    <symbol> ( </symbol>
    <parameterList>
    </parameterList>
    <symbol> ) </symbol>
    <subroutineBody>
      <symbol> { </symbol>
      <varDec>
        <keyword> var </keyword>
        <identifier> SquareGame </identifier>
        <identifier> game </identifier>
        <symbol> ; </symbol>
      </varDec>
      <statements>
        <letStatement>
          <keyword> let </keyword>
          <identifier> game </identifier>
          <symbol> = </symbol>
          <expression>
            <term>
              <identifier> SquareGame </identifier>
              <symbol> . </symbol>
              <identifier> new </identifier>
              <symbol> ( </symbol>
              <expressionList>
              </expressionList>
              <symbol> ) </symbol>
            </term>
          </expression>
          <symbol> ; </symbol>
        </letStatement>
        <doStatement>
          <keyword> do </keyword>
          <identifier> game </identifier>
          <symbol> . </symbol>
          <identifier> run </identifier>
          <symbol> ( </symbol>
          <expressionList>
          </expressionList>
          <symbol> ) </symbol>
          <symbol> ; </symbol>
        </doStatement>
        <doStatement>
          <keyword> do </keyword>
          <identifier> game </identifier>
          <symbol> . </symbol>
          <identifier> dispose </identifier>
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
      <symbol> } </symbol>
    </subroutineBody>
  </subroutineDec>
  <subroutineDec>
    <keyword> function </keyword>
    <keyword> void </keyword>
    <identifier> test </identifier>
    <symbol> ( </symbol>
    <parameterList>
    </parameterList>
    <symbol> ) </symbol>
    <subroutineBody>
      <symbol> { </symbol>
      <varDec>
        <keyword> var </keyword>
        <keyword> int </keyword>
        <identifier> i </identifier>
        <symbol> , </symbol>
        <identifier> j </identifier>
        <symbol> ; </symbol>
      </varDec>
      <varDec>
        <keyword> var </keyword>
        <identifier> String </identifier>
        <identifier> s </identifier>
        <symbol> ; </symbol>
      </varDec>
      <varDec>
        <keyword> var </keyword>
        <identifier> Array </identifier>
        <identifier> a </identifier>
        <symbol> ; </symbol>
      </varDec>
      <statements>
        <ifStatement>
          <keyword> if </keyword>
          <symbol> ( </symbol>
          <expression>
            <term>
              <keyword> false </keyword>
            </term>
          </expression>
          <symbol> ) </symbol>
          <symbol> { </symbol>
          <statements>
            <letStatement>
              <keyword> let </keyword>
              <identifier> s </identifier>
              <symbol> = </symbol>
              <expression>
                <term>
                  <stringConstant> string constant </stringConstant>
                </term>
              </expression>
              <symbol> ; </symbol>
            </letStatement>
            <letStatement>
              <keyword> let </keyword>
              <identifier> s </identifier>
              <symbol> = </symbol>
              <expression>
                <term>
                  <keyword> null </keyword>
                </term>
              </expression>
              <symbol> ; </symbol>
            </letStatement>
            <letStatement>
              <keyword> let </keyword>
              <identifier> a </identifier>
              <symbol> [ </symbol>
              <expression>
                <term>
                  <integerConstant> 1 </integerConstant>
                </term>
              </expression>
              <symbol> ] </symbol>
              <symbol> = </symbol>
              <expression>
                <term>
                  <identifier> a </identifier>
                  <symbol> [ </symbol>
                  <expression>
                    <term>
                      <integerConstant> 2 </integerConstant>
                    </term>
                  </expression>
                  <symbol> ] </symbol>
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
              <identifier> i </identifier>
              <symbol> = </symbol>
              <expression>
                <term>
                  <identifier> i </identifier>
                </term>
                <symbol> * </symbol>
                <term>
                  <symbol> ( </symbol>
                  <expression>
                    <term>
                      <symbol> - </symbol>
                      <term>
                        <identifier> j </identifier>
                      </term>
                    </term>
                  </expression>
                  <symbol> ) </symbol>
                </term>
              </expression>
              <symbol> ; </symbol>
            </letStatement>
            <letStatement>
              <keyword> let </keyword>
              <identifier> j </identifier>
              <symbol> = </symbol>
              <expression>
                <term>
                  <identifier> j </identifier>
                </term>
                <symbol> / </symbol>
                <term>
                  <symbol> ( </symbol>
                  <expression>
                    <term>
                      <symbol> - </symbol>
                      <term>
                        <integerConstant> 2 </integerConstant>
                      </term>
                    </term>
                  </expression>
                  <symbol> ) </symbol>
                </term>
              </expression>
              <symbol> ; </symbol>
            </letStatement>
            <letStatement>
              <keyword> let </keyword>
              <identifier> i </identifier>
              <symbol> = </symbol>
              <expression>
                <term>
                  <identifier> i </identifier>
                </term>
                <symbol> | </symbol>
                <term>
                  <identifier> j </identifier>
                </term>
              </expression>
              <symbol> ; </symbol>
            </letStatement>
          </statements>
          <symbol> } </symbol>
        </ifStatement>
        <returnStatement>
          <keyword> return </keyword>
          <symbol> ; </symbol>
        </returnStatement>
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
