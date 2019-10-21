# Compiler

## Order of implementation

- トークナイザ、パーサの順で実装する

### Tokenizer

```java
if (x < 153)
  {let city="Paris";}
```

```xml
<tokens>
<keyword> if </keyword>
<symbol> ( </symbol>
<identifier> x </identifier>
<symbol> &lt; </symbol>
<integerConstant> 153 </integerConstant>
<symbol> ) </symbol>
<symbol> { </symbol>
<keyword> let </keyword>
<identifier> city </identifier>
<symbol> = </symbol>
<stringConstant> Paris </stringConstant>
<symbol> ; </symbol>
<symbol> } </symbol> </tokens>
```

#### Test

- トークナイザのテスト

  - SquareDance と ArrayTest のふたつのプログラムをトークン化する
    - 「式を含まない SquareDance」についてはテストする必要はない
  - ソースファイルの Xxx.jack に対して、あなたの実装したトークナイザは XxxT.xml という名前のファイルを出力するようにする
    - すべてのテストプログラムをトークン化し、本書が提供する TextComparer というツールを用いて、比較用の.xml ファイルと比較する
  - トークナイザが生成する出力ファイルは比較用のファイルと同じ名前になるため、比較用ファイルを別ディレクトリに移動しておくとよいだろう

- パーサのテスト
  - CompilationEngine に本書が提供するテストプログラムを適用し、出力ファイルを生成する。TextComparer を使って、その出力ファイルと本書の比較用ファイルを比較する。
  - 解析器が生成する出力ファイルは比較用のファイルと同じ名前になるため、比較用ファイルを別ディレクトリに移動しておくとよいだろう。
  - XML のインデント（字下げ）は可読性のためだけに用いる。Web ブラウザと本書の TextComparer は空白文字を無視する。

#### Command memo

```bash
./lib/jack_analyzer.rb ../Square/Main.jack > MainT.xml | cl
./lib/jack_analyzer.rb ./../Square/Square.jack > SquareT.xml
./lib/jack_analyzer.rb ./../Square/SquareGame.jack > SquareGameT.xml
diff ./SquareGameT.xml ../Square/SquareGameT.xml
```

## 各説明のページ

Jack 言語の文法: 270p

## XML の出力についての仕様

### 終端記号（terminal）

xxx という種類の終端記号である言語要素に出くわすたびに、構文解析器は次の
マークアップを出力する。
`<xxx> terminal </xxx>`
ここで xxx は Jack 言語の 5 つの字句要素――keyword、symbol、
integerConstant、stringConstant、identifier――のいずれかに該当する。

### 非終端記号（non-terminal）

xxx という種類の非終端記号である言語要素に出くわすたびに、構文解析器は次の
擬似コードを使って、マークアップを出力する。

```xml
<xxx>を出力
xxx 要素のボディ部への再帰呼び出し
</xxx>を出力
```

ここで xxx は次に示す非終端記号のいずれかに該当する。

- class、classVarDec、subroutineDec、parameterList、subroutineBody、varDec
- statements、whileStatement、ifStatement、returnStatement、letStatement、doStatement
- expression、term、expressionList

### プログラム構造

```bash
class ’class’ className ’{’ classVarDec*
subroutineDec* ’}’
classVarDec (’static’ | ’field’) type varName (’,’
varName)* ’;’
type ’int’ | ’char’ | ’boolean’ | className
subroutineDec (’constructor’ | ’function’ | ’method’)
(’void’ | type) subroutineName ’(’
parameterList ’)’
subroutineBody
parameterList ((type varName) (’,’ type varName)*)?
subroutineBody ’{’ varDec* statements ’}’
varDec ’var’ type varName (’,’ varName)* ’;’
className identifier
subroutineName identifier
varName identifier
234 10 章 コンパイラ#1：構文解析
文
statements statement*
statement letStatement | ifStatement |
whileStatement | doStatement |
returnStatement
letStatement ’let’ varName (’[’ expression ’]’)? ’=’
expression ’;’
ifStatement ’if’ ’(’ expression ’)’ ’{’ statements
’}’
(’else’ ’{’ statements
’}’)?
whileStatement ’while’ ’(’ expression ’)’
’{’ statements ’}’
doStatement ’do’ subroutineCall ’;’
returnStatement ’return’ expression? ’;’
式
expression term (op term)*
term integerConstant | stringConstant |
keywordConstant | varName | varName
’[’ expression ’]’ | subroutineCall |
’(’ expression ’)’ | unaryOp term
subroutineCall subroutineName ’(’ expressionList ’)’ |
(className | varName) ’.’
subroutineName
’(’ expressionList ’)’
expressionList (expression (’,’ expression)* )?
op ’+’ | ’-’ | ’*’ | ’/’ | ’&’ | ’|’ |
’<’ | ’>’ | ’=’
unaryOp ’-’ | ’~’
KeywordConstant ’true’ | ’false’ | ’null’ | ’this’
```
