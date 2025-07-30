`define TB_RUN

`include "alu.v"
`timescale 1ns/100ps

// Define a macro to switch include paths based on a manually set flag

module alu_tb;

    // Inputs
    reg [31:0] DATA1, DATA2;
    reg [4:0] SELECT;

    // Output
    wire [31:0] RESULT;

    // Instantiate the ALU module
    alu uut (
        .DATA1(DATA1),
        .DATA2(DATA2),
        .SELECT(SELECT),
        .RESULT(RESULT)
    );

    // Clock generation (optional)
    reg clk;
    always #5 clk = ~clk; // 10ns clock period

    // Testbench logic
    initial begin
        // Initialize inputs
        clk = 0;
        DATA1 = 0;
        DATA2 = 0;
        SELECT = 0;

        // Wait for global reset
        #10;

        // Test Case 1: FORWARD (DATA1)
        DATA1 = 32'h12345678;
        DATA2 = 32'h00000000;
        SELECT = `FORWARD;
        #10;
        $display("FORWARD: DATA1 = %h, RESULT = %h", DATA1, RESULT);

        // Test Case 2: ADD
        DATA1 = 32'h0000000A;
        DATA2 = 32'h0000000B;
        SELECT = `ADD;
        #10;
        $display("ADD: DATA1 = %h, DATA2 = %h, RESULT = %h", DATA1, DATA2, RESULT);

        // Test Case 3: SUB
        DATA1 = 32'h0000000F;
        DATA2 = 32'h0000000A;
        SELECT = `SUB;
        #10;
        $display("SUB: DATA1 = %h, DATA2 = %h, RESULT = %h", DATA1, DATA2, RESULT);

        // Test Case 4: SLL (Shift Left Logical)
        DATA1 = 32'h00000001;
        DATA2 = 32'h00000004;
        SELECT = `SLL;
        #10;
        $display("SLL: DATA1 = %h, DATA2 = %h, RESULT = %h", DATA1, DATA2, RESULT);

        // Test Case 5: SLT (Set Less Than)
        DATA1 = 32'h0000000A;
        DATA2 = 32'h0000000B;
        SELECT = `SLT;
        #10;
        $display("SLT: DATA1 = %h, DATA2 = %h, RESULT = %h", DATA1, DATA2, RESULT);

        // Test Case 6: SLTU (Set Less Than Unsigned)
        DATA1 = 32'h0000000A;
        DATA2 = 32'h0000000B;
        SELECT = `SLTU;
        #10;
        $display("SLTU: DATA1 = %h, DATA2 = %h, RESULT = %h", DATA1, DATA2, RESULT);

        // Test Case 6: XOR
        DATA1 = 32'h0000FFFF;
        DATA2 = 32'hFFFF0000;
        SELECT = `XOR;
        #10;
        $display("XOR: DATA1 = %h, DATA2 = %h, RESULT = %h", DATA1, DATA2, RESULT);

        // Test Case 7: MUL
        DATA1 = 32'h00000002;
        DATA2 = 32'h00000003;
        SELECT = `MUL;
        #10;
        $display("MUL: DATA1 = %h, DATA2 = %h, RESULT = %h", DATA1, DATA2, RESULT);

        // Test Case 8: DIV
        DATA1 = 32'h0000000A;
        DATA2 = 32'h00000002;
        SELECT = `DIV;
        #10;
        $display("DIV: DATA1 = %h, DATA2 = %h, RESULT = %h", DATA1, DATA2, RESULT);

        // Test Case 9: REM (Remainder)
        DATA1 = 32'h0000000B;
        DATA2 = 32'h00000003;
        SELECT = `REM;
        #10;
        $display("REM: DATA1 = %h, DATA2 = %h, RESULT = %h", DATA1, DATA2, RESULT);

        // Test Case 10: AND
        DATA1 = 32'h0000FFFF;
        DATA2 = 32'hFFFF0000;
        SELECT = `AND;
        #10;
        $display("AND: DATA1 = %h, DATA2 = %h, RESULT = %h", DATA1, DATA2, RESULT);

        // Test Case 11: OR
        DATA1 = 32'h0000FFFF;
        DATA2 = 32'hFFFF0000;
        SELECT = `OR;
        #10;
        $display("OR: DATA1 = %h, DATA2 = %h, RESULT = %h", DATA1, DATA2, RESULT);

        // Test Case 12: SRL (Shift Right Logical)
        DATA1 = 32'h0000000F;
        DATA2 = 32'h00000002;
        SELECT = `SRL;
        #10;
        $display("SRL: DATA1 = %h, DATA2 = %h, RESULT = %h", DATA1, DATA2, RESULT);

        // Test Case 13: SRA (Shift Right Arithmetic)
        DATA1 = 32'h80000000;
        DATA2 = 32'h00000001;
        SELECT = `SRA;
        #10;
        $display("SRA: DATA1 = %h, DATA2 = %h, RESULT = %h", DATA1, DATA2, RESULT);

        // Test Case 14: MULH (Multiply High)
        DATA1 = 32'ha0000002;
        DATA2 = 32'hb0000003;
        SELECT = `MULH;
        #10;
        $display("MULH: DATA1 = %h, DATA2 = %h, RESULT = %h", DATA1, DATA2, RESULT);

        // Test Case 15: MULHSU (Multiply High Signed/Unsigned)
        DATA1 = 32'h80000002;
        DATA2 = 32'h00000003;
        SELECT = `MULHSU;
        #10;
        $display("MULHSU: DATA1 = %h, DATA2 = %h, RESULT = %h", DATA1, DATA2, RESULT);

        // Test Case 16: MULHU (Multiply High Unsigned)
        DATA1 = 32'h80000002;
        DATA2 = 32'h00000003;
        SELECT = `MULHU;
        #10;
        $display("MULHU: DATA1 = %h, DATA2 = %h, RESULT = %h", DATA1, DATA2, RESULT);

        // Test Case 17: DIVU (Divide Unsigned)
        DATA1 = 32'h0000000A;
        DATA2 = 32'h00000002;
        SELECT = `DIVU;
        #10;
        $display("DIVU: DATA1 = %h, DATA2 = %h, RESULT = %h", DATA1, DATA2, RESULT);

        // Test Case 18: REMU (Remainder Unsigned)
        DATA1 = 32'h0000000B;
        DATA2 = 32'h00000003;
        SELECT = `REMU;
        #10;
        $display("REMU: DATA1 = %h, DATA2 = %h, RESULT = %h", DATA1, DATA2, RESULT);

        // End simulation
        $finish;
    end

endmodule