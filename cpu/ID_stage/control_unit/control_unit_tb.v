`define TB_RUN

`include "../../utils/encordings.v"
`include "../../ID_stage/control_unit/control_unit.v"
`timescale 1ns/100ps

module control_unit_tb;

    // Inputs
    reg [6:0] opcode;
    reg [2:0] funct3;
    reg [6:0] funct7;
    reg reset;

    // Outputs
    wire reg_write_en, data1_alu_sel, data2_alu_sel;
    wire [4:0] alu_op;
    wire [2:0] mem_write;
    wire [3:0] mem_read;
    wire [2:0] branch_jump;
    wire [3:0] imm_sel;
    wire [1:0] wb_sel;

    // Instantiate the control_unit module
    control_unit uut (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .alu_op(alu_op),
        .reg_write_en(reg_write_en),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .branch_jump(branch_jump),
        .imm_sel(imm_sel),
        .data1_alu_sel(data1_alu_sel),
        .data2_alu_sel(data2_alu_sel),
        .wb_sel(wb_sel),
        .reset(reset)
    );

    initial begin
        // Open a file for logging
        $dumpfile("tb_control_unit.vcd");
        $dumpvars(0, control_unit_tb);

        // Monitor to print inputs and outputs
        $monitor("Time: %d | Opcode: %b | Funct3: %b | Funct7: %b | Reset: %b | ALU_OP: %b | RegWrite: %b | MemWrite: %b | MemRead: %b | BranchJump: %b | ImmSel: %b | Data1Sel: %b | Data2Sel: %b | WBSel: %b",
                 $time, opcode, funct3, funct7, reset, alu_op, reg_write_en, mem_write, mem_read, branch_jump, imm_sel, data1_alu_sel, data2_alu_sel, wb_sel);
    end

    // Testbench logic
    initial begin
        /*#1*/0

        // Initialize inputs
        opcode = 7'b0000000;
        funct3 = 3'b000;
        funct7 = 7'b0000000;
        reset = 0;

        // Test case 1: R-type instruction (ADD)
        /*#1*/0;
        opcode = `OP_R_TYPE;
        funct3 = 3'b000;
        funct7 = 7'b0000000;
        /*#1*/0;

        // Test case 2: I-type instruction (ADDI)
        /*#1*/0;
        opcode = `OP_I_TYPE;
        funct3 = 3'b000;
        funct7 = 7'b0000000;
        /*#1*/0;

        // Test case 3: Load instruction (LW)
        /*#1*/0;
        opcode = `OP_LOAD;
        funct3 = 3'b010;
        funct7 = 7'b0000000;
        /*#1*/0;

        // Test case 4: Store instruction (SW)
        /*#1*/0;
        opcode = `OP_STORE;
        funct3 = 3'b010;
        funct7 = 7'b0000000;
        /*#1*/0;

        // Test case 5: Branch instruction (BEQ)
        /*#1*/0;
        opcode = `OP_BRANCH;
        funct3 = 3'b000;
        funct7 = 7'b0000000;
        /*#1*/0;

        // Test case 6: JAL instruction
        /*#1*/0;
        opcode = `OP_JAL;
        funct3 = 3'b000;
        funct7 = 7'b0000000;
        /*#1*/0;

        // Test case 7: LUI instruction
        /*#1*/0;
        opcode = `OP_LUI;
        funct3 = 3'b000;
        funct7 = 7'b0000000;
        /*#1*/0;

        // Test case 8: AUIPC instruction
        /*#1*/0;
        opcode = `OP_AUIPC;
        funct3 = 3'b000;
        funct7 = 7'b0000000;
        /*#1*/0;

        // Test case 9: Reset condition
        /*#1*/0;
        reset = 1;
        /*#1*/0;
        reset = 0;
        /*#1*/0;

        // End simulation
        $finish;
    end

endmodule