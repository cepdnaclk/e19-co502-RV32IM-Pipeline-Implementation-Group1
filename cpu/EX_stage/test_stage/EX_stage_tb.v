`define TB_RUN

`include "../alu/alu.v"
`include "../branch/branch_logic.v"
`include "../../pipeline_regs/ex_mem_pipeline_reg.v"
`include "../../utils/muxes/mux_32b_2to1.v"
`include "../../utils/encordings.v"


`timescale 1ns/100ps

module EX_stage_tb ();
    reg clk, rst, data1alusel_out, data2alusel_out, reg_write_en_out;
    reg [31:0] pc_out, data1_out, data2_out, imm_out;
    reg [4:0] dest_addr_out, aluop_out;
    reg [2:0] branch_jump_out;
    reg [2:0] mem_write_out;
    reg [3:0] mem_read_out;
    reg [1:0] WB_sel_out;

    wire [31:0] data1_mux_out, data2_mux_out, alu_res_out;
    wire branch_logic_out;

    mux_32b_2to1 data1_mux (
        .data1(data1_out),
        .data2(pc_out),
        .sel(data1alusel_out),
        .out(data1_mux_out)
    );

    mux_32b_2to1 data2_mux (
        .data1(data2_out),
        .data2(imm_out),
        .sel(data2alusel_out),
        .out(data2_mux_out)
    );

    alu alu_inst (
        .DATA1(data1_mux_out),
        .DATA2(data2_mux_out),
        .SELECT(aluop_out),
        .RESULT(alu_res_out)
    );

    branch_logic branch_logic_inst (
        .data1(data1_out),
        .data2(data2_out),
        .op(branch_jump_out),
        .out(branch_logic_out)
    );

    ex_mem_pipeline_reg ex_mem_pipeline_reg_inst (
        .clk(clk),
        .rst(rst),
        .reg_write_in(reg_write_en_out),
        .pc_in(pc_out),
        .alu_result_in(alu_res_out),
        .read_data2_in(data2_mux_out),
        .imm_in(imm_out),
        .dest_addr_in(dest_addr_out),
        .mem_read_in(mem_read_out),
        .mem_write_in(mem_write_out),
        .wb_sel_in(WB_sel_out),
        .reg_write_out(),
        .pc_out(),
        .alu_result_out(),
        .read_data2_out(),
        .imm_out(),
        .dest_addr_out(),
        .mem_read_out(),
        .mem_write_out(),
        .wb_sel_out()
    );

    initial begin
        $dumpfile("EX_stage_tb.vcd");
        $dumpvars(0, EX_stage_tb);

        // Initialize all inputs
        clk = 0;
        rst = 1;
        data1alusel_out = 0;
        data2alusel_out = 0;
        reg_write_en_out = 0;
        pc_out = 32'h00000000;
        data1_out = 32'h00000000;
        data2_out = 32'h00000000;
        imm_out = 32'h00000000;
        dest_addr_out = 5'b00000;
        aluop_out = 5'b00000;
        branch_jump_out = 3'b000;
        mem_write_out = 3'b000;
        mem_read_out = 4'b0000;
        WB_sel_out = 2'b00;

        // Release reset after a few clock cycles
        /*#1*/0 rst = 0;

        // Test case 1: Simple ALU operation (ADD)
        /*#1*/0;
        data1_out = 32'h00000001;
        data2_out = 32'h00000002;
        aluop_out = `ADD; // Assuming 5'b00000 is the opcode for ADD
        /*#1*/0;
        $display("Test case 1: ALU ADD operation");
        $display("data1_out = %h, data2_out = %h, alu_res_out = %h", data1_mux_out, data2_out, alu_res_out);

        // Test case 2: ALU operation with immediate (SUB)
        /*#1*/0;
        data1_out = 32'h00000005;
        imm_out = 32'h00000002;
        data2alusel_out = 1; // Select immediate
        aluop_out = `SUB; // Assuming 5'b00001 is the opcode for SUB
        /*#1*/0;
        $display("Test case 2: ALU SUB operation with immediate");
        $display("data1_out = %h, imm_out = %h, alu_res_out = %h", data1_out, imm_out, alu_res_out);

        // Test case 3: Branch logic (BEQ)
        /*#1*/0;
        data1_out = 32'h00000003;
        data2_out = 32'h00000003;
        branch_jump_out = `BEQ; // Assuming 3'b001 is the opcode for BEQ
        /*#1*/0;
        $display("Test case 3: Branch logic BEQ");
        $display("data1_out = %h, data2_out = %h, branch_logic_out = %b", data1_out, data2_out, branch_logic_out);

        // Test case 4: Branch logic (BNE)
        /*#1*/0;
        data1_out = 32'h00000004;
        data2_out = 32'h00000005;
        branch_jump_out = `BNE; // Assuming 3'b010 is the opcode for BNE
        /*#1*/0;
        $display("Test case 4: Branch logic BNE");
        $display("data1_out = %h, data2_out = %h, branch_logic_out = %b", data1_out, data2_out, branch_logic_out);

        // End simulation
        /*#1*/0 $finish;
    end

    // Clock generation
    always #5 clk = ~clk;

endmodule