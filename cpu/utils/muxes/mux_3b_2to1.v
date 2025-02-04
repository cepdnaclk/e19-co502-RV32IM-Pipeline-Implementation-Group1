`timescale 1ns/100ps

module mux_3b_2to1(
    input [2:0] data1,
    input [2:0] data2,
    output [2:0] out,
    input sel
);
    assign /*#1*/ out = (sel == 1'b1) ? data2 : data1;
endmodule