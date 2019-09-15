// This file is part of www.nand2tetris.org
// and the book "The Elements of Computing Systems"
// by Nisan and Schocken, MIT Press.
// File name: projects/04/Mult.asm

// Multiplies R0 and R1 and stores the result in R2.
// (R0, R1, R2 refer to RAM[0], RAM[1], and RAM[2], respectively.)

// Put your code here.
// Computes sum=1+...+100.
  @i // i=1
  M=1
  @sum // sum=0
  M=0
(LOOP)
  @i // if (i-100)=0 goto END
  D=M
  @R1
  D=D-M
  @END
  D;JGT
  @R0 // sum+=i
  D=M
  @sum
  M=D+M
  @i // i++
  M=M+1
  @LOOP // goto LOOP
  0;JMP
(END) // infinite loop
  @sum
  D=M
  @R2
  M=D
  @END
  0;JMP
