`timescale 1ns/100ps

module mux_32b_2to1(
    input [31:0] data1,
    input [31:0] data2,
    input sel,
    output [31:0] out
);
    assign /*#1*/ out = (sel == 1'b1) ? data2 : data1;
endmodule