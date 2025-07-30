`define TB_RUN
`include "branch_logic.v"

`timescale 1ns/1ps

module branch_logic_tb;

    // Inputs
    reg [31:0] data1, data2;
    reg [3:0] op;  // Updated to 4-bit op

    // Output
    wire out;

    // Instantiate the branch_logic module
    branch_logic uut (
        .data1(data1),
        .data2(data2),
        .op(op),
        .out(out)
    );

    // Testbench logic
    initial begin
        $display("Starting branch_logic testbench...");

        // Test Case 1: BEQ (Branch if Equal)
        data1 = 32'h12345678;
        data2 = 32'h12345678;
        op = 4'b1000;  // BEQ
        #10;
        $display("BEQ: data1 = %h, data2 = %h, op = %b, out = %b", data1, data2, op, out);

        // Test Case 2: BEQ (Not Equal)
        data1 = 32'h12345678;
        data2 = 32'h87654321;
        op = 4'b1000;  // BEQ
        #10;
        $display("BEQ (Not Equal): data1 = %h, data2 = %h, op = %b, out = %b", data1, data2, op, out);

        // Test Case 3: BNE (Branch if Not Equal)
        data1 = 32'h12345678;
        data2 = 32'h87654321;
        op = 4'b1001;  // BNE
        #10;
        $display("BNE: data1 = %h, data2 = %h, op = %b, out = %b", data1, data2, op, out);

        // Test Case 4: BNE (Equal)
        data1 = 32'h12345678;
        data2 = 32'h12345678;
        op = 4'b1001;  // BNE
        #10;
        $display("BNE (Equal): data1 = %h, data2 = %h, op = %b, out = %b", data1, data2, op, out);

        // Test Case 5: BLT (Signed Less Than)
        data1 = 32'h80000000;
        data2 = 32'h00000001;
        op = 4'b1100;  // BLT
        #10;
        $display("BLT: data1 = %h, data2 = %h, op = %b, out = %b", data1, data2, op, out);

        // Test Case 6: BGE (Signed Greater Than or Equal)
        data1 = 32'h00000001;
        data2 = 32'h80000000;
        op = 4'b1101;  // BGE
        #10;
        $display("BGE: data1 = %h, data2 = %h, op = %b, out = %b", data1, data2, op, out);

        // Test Case 7: BLTU (Unsigned Less Than)
        data1 = 32'h00000001;
        data2 = 32'hFFFFFFFF;
        op = 4'b1110;  // BLTU
        #10;
        $display("BLTU: data1 = %h, data2 = %h, op = %b, out = %b", data1, data2, op, out);

        // Test Case 8: BGEU (Unsigned Greater Than or Equal)
        data1 = 32'hFFFFFFFF;
        data2 = 32'h00000001;
        op = 4'b1111;  // BGEU
        #10;
        $display("BGEU: data1 = %h, data2 = %h, op = %b, out = %b", data1, data2, op, out);

        // Test Case 9: JAL/JALR (Always Branch)
        data1 = 32'h12345678;
        data2 = 32'h87654321;
        op = 4'b1010;  // JAL_JALR (Unconditional)
        #10;
        $display("JAL/JALR: data1 = %h, data2 = %h, op = %b, out = %b", data1, data2, op, out);

        // Test Case 10: No Branch (op[3] == 0)
        data1 = 32'h00000001;
        data2 = 32'h00000002;
        op = 4'b0000;  // No branch (op[3] == 0)
        #10;
        $display("No Branch: data1 = %h, data2 = %h, op = %b, out = %b", data1, data2, op, out);

        // End simulation
        $display("Testbench completed.");
        $finish;
    end

endmodule
