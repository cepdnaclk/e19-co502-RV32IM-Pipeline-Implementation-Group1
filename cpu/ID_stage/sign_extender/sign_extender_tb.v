`define TB_RUN
`include "sign_extender.v"

`timescale 1ns/100ps

module sign_extender_tb;

    // Inputs
    reg [31:0] inst;
    reg [3:0] imm_sel;

    // Outputs
    wire [31:0] imm_ext;

    // Instantiate the sign_extender module
    sign_extender uut (
        .inst(inst),
        .imm_sel(imm_sel),
        .imm_ext(imm_ext)
    );

    // Testbench logic
    initial begin
        // Open a file for logging
        $dumpfile("tb_sign_extender.vcd");
        $dumpvars(0, sign_extender_tb);

        $monitor("Time: %d | IMM_SEL: %b | IMM_EXT: %h", $time, imm_sel, imm_ext);

        // Test case 1: IMM_TYPE1 (U-type immediate)
        inst = 32'hFFFFF123; // Example U-type instruction
        imm_sel = `IMM_TYPE1;
        /*#1*/0;
        $display($time, "IMM_TYPE1: inst = %h, imm_ext = %h", inst, imm_ext);

        // Test case 2: IMM_TYPE2 (J-type immediate, signed)
        inst = 32'hF1234567; // Example J-type instruction
        imm_sel = `IMM_TYPE2;
        /*#1*/0;
        $display($time, "IMM_TYPE2 (signed): inst = %h, imm_ext = %h", inst, imm_ext);

        // Test case 3: IMM_TYPE2 (J-type immediate, unsigned)
        inst = 32'hF1234567; // Example J-type instruction
        imm_sel = {1'b1, `IMM_TYPE2}; // Set imm_sel[3] = 1 for unsigned
        /*#1*/0;
        $display($time, "IMM_TYPE2 (unsigned): inst = %h, imm_ext = %h", inst, imm_ext);

        // Test case 4: IMM_TYPE3 (I-type immediate, signed)
        inst = 32'hF1234567; // Example I-type instruction
        imm_sel = `IMM_TYPE3;
        /*#1*/0;
        $display($time, "IMM_TYPE3 (signed): inst = %h, imm_ext = %h", inst, imm_ext);

        // Test case 5: IMM_TYPE3 (I-type immediate, unsigned)
        inst = 32'hF1234567; // Example I-type instruction
        imm_sel = {1'b1, `IMM_TYPE3}; // Set imm_sel[3] = 1 for unsigned
        /*#1*/0;
        $display($time, "IMM_TYPE3 (unsigned): inst = %h, imm_ext = %h", inst, imm_ext);

        // Test case 6: IMM_TYPE4 (B-type immediate, signed)
        inst = 32'hF1234567; // Example B-type instruction
        imm_sel = `IMM_TYPE4;
        /*#1*/0;
        $display($time, "IMM_TYPE4 (signed): inst = %h, imm_ext = %h", inst, imm_ext);

        // Test case 7: IMM_TYPE4 (B-type immediate, unsigned)
        inst = 32'hF1234567; // Example B-type instruction
        imm_sel = {1'b1, `IMM_TYPE4}; // Set imm_sel[3] = 1 for unsigned
        /*#1*/0;
        $display($time, "IMM_TYPE4 (unsigned): inst = %h, imm_ext = %h", inst, imm_ext);

        // Test case 8: IMM_TYPE5 (S-type immediate, signed)
        inst = 32'hF1234567; // Example S-type instruction
        imm_sel = `IMM_TYPE5;
        /*#1*/0;
        $display($time, "IMM_TYPE5 (signed): inst = %h, imm_ext = %h", inst, imm_ext);

        // Test case 9: IMM_TYPE5 (S-type immediate, unsigned)
        inst = 32'hF1234567; // Example S-type instruction
        imm_sel = {1'b1, `IMM_TYPE5}; // Set imm_sel[3] = 1 for unsigned
        /*#1*/0;
        $display($time, "IMM_TYPE5 (unsigned): inst = %h, imm_ext = %h", inst, imm_ext);

        // Test case 10: IMM_TYPE6 (CSR-type immediate)
        inst = 32'hF1234567; // Example CSR-type instruction
        imm_sel = `IMM_TYPE6;
        /*#1*/0;
        $display($time, "IMM_TYPE6: inst = %h, imm_ext = %h", inst, imm_ext);

        // End simulation
        $finish;
    end

endmodule