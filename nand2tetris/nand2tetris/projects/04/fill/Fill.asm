// This file is part of www.nand2tetris.org
// and the book "The Elements of Computing Systems"
// by Nisan and Schocken, MIT Press.
// File name: projects/04/Fill.asm

// Runs an infinite loop that listens to the keyboard input.
// When a key is pressed (any key), the program blackens the screen,
// i.e. writes "black" in every pixel;
// the screen should remain fully black as long as the key is pressed. 
// When no key is pressed, the program clears the screen, i.e. writes
// "white" in every pixel;
// the screen should remain fully clear as long as no key is pressed.

// スクリーンの変数を設定
@16384
D=A
@SCREEN
M=D
(LOOP_KEY)
  // キーボードの変数を設定
  @KBD
  D=M
  @pressed
  M=D

  @pressed
  D=M

  @ELSE_KEY
  D;JNE

  // 0 = white / 1 = black
  @color
  M=0
  @DISP_SCREEN // スクリーンに表示する処理へジャンプ
  0;JMP
(ELSE_KEY)
  @color
  M=-1
  @DISP_SCREEN // スクリーンに表示する処理へジャンプ
  0;JMP
(DISP_SCREEN)
  @SCREEN
  D=A
  @screen
  M=D

  @i
  M=0
(LOOP_ROW)
  @i
  D=M
  @256
  D=D-A
  @END_ROW
  D;JGT
  @i // i++
  M=M+1
  @j
  M=0

  (LOOP_COL)
    @j
    D=M
    @32
    // @5
    D=D-A
    @END_COL // if (j > 32)
    D;JGT

    // 指定された色を表示する
    @color
    D=M
    @screen // 現在のスクリーンのアドレスの位置を指定
    A=M
    M=-1
    M=D

    // スクリーンの次のピクセルを指定する
    @1
    D=A
    @screen
    M=M+D

    @j // j++
    M=M+1

    @LOOP_COL
    0;JMP
  (END_COL)
    @LOOP_ROW
    0;JMP
(END_ROW)
(END_KEY)

@LOOP_KEY
0;JMP
