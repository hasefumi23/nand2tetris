# Compiler

## memo

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
