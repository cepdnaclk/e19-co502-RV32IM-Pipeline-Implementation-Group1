`timescale 1ns/100ps

// ALU
`define ADD 5'b00000
`define SUB 5'b10000
`define SLL 5'b00001
`define SLT 5'b00010
`define SLTU 5'b00011
`define XOR 5'b00100
`define SRL 5'b00101
`define SRA 5'b10001
`define OR 5'b00110
`define AND 5'b00111

`define MUL 5'b01000
`define MULH 5'b01001
`define MULHSU 5'b01010
`define MULHU 5'b01011
`define DIV 5'b01100
`define DIVU 5'b01101
`define REM 5'b01110
`define REMU 5'b01111

`define FORWARD 5'b11xxx


// Immediate Types
`define IMM_TYPE1 3'b000
`define IMM_TYPE2 3'b001
`define IMM_TYPE3 3'b010
`define IMM_TYPE4 3'b011
`define IMM_TYPE5 3'b100
`define IMM_TYPE6 3'b101

// Branch Types
`define BEQ 3'b000
`define BNE 3'b001
`define BLT 3'b100
`define BGE 3'b101
`define BLTU 3'b110
`define BGEU 3'b111
`define JAL_JALR 3'b010

// RV32I Base Integer Instructions Opcodes
`define OP_R_TYPE   7'b0110011
`define OP_I_TYPE   7'b0010011
`define OP_LOAD     7'b0000011
`define OP_STORE    7'b0100011
`define OP_BRANCH   7'b1100011
`define OP_JAL      7'b1101111
`define OP_JALR     7'b1100111
`define OP_LUI      7'b0110111
`define OP_AUIPC    7'b0010111
`define OP_SYSTEM   7'b1110011

