RSpec.describe CompilationEngine do
  let(:contents) { 
    <<~"EOS"
class Main {
  static boolean example;    // Added for testing -- there is no static keyword
  field int x, y; 

  function void main() {
    var SquareGame game;
    let game = SquareGame.new();
    do game.run();
    do game.dispose();
    return;
  }

  function void test(int Ax, int Ay) {  // Added to test Jack syntax that is not use in
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

    xit "build tree node" do
      engine.compile_class
      expect(engine.current_node).to eq(
        [
          [
            ["class"],
            [
              ["keyword", "class"],
              ["identifier", "Square"],
              ["symbol", "{"],
              ["symbol", "}"]
            ]
          ]
        ]
      )
    end

    xit 'output only class tokens' do
      expected_result = <<~"EOS"
<class>
  <keyword> class </keyword>
  <identifier> Square </identifier>
  <symbol> { </symbol>
  <symbol> } </symbol>
</class>
      EOS

      engine.compile_class
      expect { engine.to_xml }.to output(expected_result).to_stdout
    end
  end

  describe 'compile_class' do
    xit "build tree node" do
      engine.compile_class
      expect(engine.current_node).to eq(
        [
          [
            "class",
            [
              ["keyword", "class"],
              ["identifier", "Main"],
              ["symbol", "{"],
              [
                "classVarDec",
                [
                  ["keyword", "static"],
                  ["keyword", "boolean"],
                  ["identifier", "test"],
                  ["symbol", ";"]
                ]
              ],
              ["symbol", "}"]
            ]
          ]
        ]
      )
    end
    it 'return current token' do
      expected_result = <<~"EOS"
<class>
  <keyword> class </keyword>
  <identifier> Main CLASS - USED - NONE -  </identifier>
  <symbol> { </symbol>
  <classVarDec>
    <keyword> static </keyword>
    <keyword> boolean </keyword>
    <identifier> example STATIC - DEFINED - STATIC - 0 </identifier>
    <symbol> ; </symbol>
  </classVarDec>
  <classVarDec>
    <keyword> field </keyword>
    <keyword> int </keyword>
    <identifier> x FIELD - DEFINED - FIELD - 0 </identifier>
    <symbol> , </symbol>
    <identifier> y FIELD - DEFINED - FIELD - 1 </identifier>
    <symbol> ; </symbol>
  </classVarDec>
  <subroutineDec>
    <keyword> function </keyword>
    <keyword> void </keyword>
    <identifier> main FUNCTION - USED - NONE -  </identifier>
    <symbol> ( </symbol>
    <parameterList>
    </parameterList>
    <symbol> ) </symbol>
    <subroutineBody>
      <symbol> { </symbol>
      <varDec>
        <keyword> var </keyword>
        <identifier> SquareGame CLASS - USED - NONE -  </identifier>
        <identifier> game VAR - DEFINED - VAR - 0 </identifier>
        <symbol> ; </symbol>
      </varDec>
      <statements>
        <letStatement>
          <keyword> let </keyword>
          <identifier> game CLASS - USED - VAR - 0 </identifier>
          <symbol> = </symbol>
          <expression>
            <term>
              <identifier> SquareGame CLASS - USED - NONE -  </identifier>
              <symbol> . </symbol>
              <identifier> new FUNCTION - USED - NONE -  </identifier>
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
          <identifier> game CLASS - USED - VAR - 0 </identifier>
          <symbol> . </symbol>
          <identifier> run FUNCTION - USED - NONE -  </identifier>
          <symbol> ( </symbol>
          <expressionList>
          </expressionList>
          <symbol> ) </symbol>
          <symbol> ; </symbol>
        </doStatement>
        <doStatement>
          <keyword> do </keyword>
          <identifier> game CLASS - USED - VAR - 0 </identifier>
          <symbol> . </symbol>
          <identifier> dispose FUNCTION - USED - NONE -  </identifier>
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
    <identifier> test FUNCTION - USED - NONE -  </identifier>
    <symbol> ( </symbol>
    <parameterList>
      <keyword> int </keyword>
      <identifier> Ax ARG - DEFINED - ARG - 0 </identifier>
      <symbol> , </symbol>
      <keyword> int </keyword>
      <identifier> Ay ARG - DEFINED - ARG - 1 </identifier>
    </parameterList>
    <symbol> ) </symbol>
    <subroutineBody>
      <symbol> { </symbol>
      <varDec>
        <keyword> var </keyword>
        <keyword> int </keyword>
        <identifier> i VAR - DEFINED - VAR - 0 </identifier>
        <symbol> , </symbol>
        <identifier> j VAR - DEFINED - VAR - 1 </identifier>
        <symbol> ; </symbol>
      </varDec>
      <varDec>
        <keyword> var </keyword>
        <identifier> String CLASS - USED - NONE -  </identifier>
        <identifier> s VAR - DEFINED - VAR - 2 </identifier>
        <symbol> ; </symbol>
      </varDec>
      <varDec>
        <keyword> var </keyword>
        <identifier> Array CLASS - USED - NONE -  </identifier>
        <identifier> a VAR - DEFINED - VAR - 3 </identifier>
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
              <identifier> s CLASS - USED - VAR - 2 </identifier>
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
              <identifier> s CLASS - USED - VAR - 2 </identifier>
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
              <identifier> a CLASS - USED - VAR - 3 </identifier>
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
                  <identifier> a CLASS - USED - VAR - 3 </identifier>
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
              <identifier> i CLASS - USED - VAR - 0 </identifier>
              <symbol> = </symbol>
              <expression>
                <term>
                  <identifier> i CLASS - USED - VAR - 0 </identifier>
                </term>
                <symbol> * </symbol>
                <term>
                  <symbol> ( </symbol>
                  <expression>
                    <term>
                      <symbol> - </symbol>
                      <term>
                        <identifier> j CLASS - USED - VAR - 1 </identifier>
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
              <identifier> j CLASS - USED - VAR - 1 </identifier>
              <symbol> = </symbol>
              <expression>
                <term>
                  <identifier> j CLASS - USED - VAR - 1 </identifier>
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
              <identifier> i CLASS - USED - VAR - 0 </identifier>
              <symbol> = </symbol>
              <expression>
                <term>
                  <identifier> i CLASS - USED - VAR - 0 </identifier>
                </term>
                <symbol> | </symbol>
                <term>
                  <identifier> j CLASS - USED - VAR - 1 </identifier>
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
      engine.compile_class
      expect { engine.to_xml }.to output(expected_result).to_stdout
    end
  end
end
