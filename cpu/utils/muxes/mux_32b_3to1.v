 
module mux_32b_3to1(
    input [31:0] data1,  // 32-bit input A
    input [31:0] data2,  // 32-bit input B
    input [31:0] data3,  // 32-bit input C
    output [31:0] out,   // 32-bit output
    input [1:0] sel      // 2-bit select signal
);
    // The output is assigned based on the value of sel
    assign #1 out = (sel == 2'b00) ? data1 :
                 (sel == 2'b01) ? data2 : data3;
endmodule