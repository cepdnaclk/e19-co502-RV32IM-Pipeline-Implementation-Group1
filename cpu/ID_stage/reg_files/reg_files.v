`timescale 1ns/100ps

module reg_files(clk, rst, addr1, addr2, data1, data2, we, wd, waddr);
    input clk, rst, we;
    input [4:0] waddr, addr1, addr2;
    input [31:0] wd;
    output [31:0] data1, data2;

    reg [31:0] mem[31:0];
    integer i;

    assign #1 data1 = mem[addr1];
    assign #1 data2 = mem[addr2];

    always @(negedge clk) begin
        #1
        if(rst == 1'b1) begin
            for(i = 0; i < 32; i = i + 1) begin
                mem[i] <= 32'b0;
            end
        end
        else if(we == 1'b1) begin
            #2 mem[waddr] <= wd;
        end

        // $display("mem[0] = %d, mem[1] = %d, mem[2] = %d, mem[3] = %d, mem[4] = %d" , mem[0], mem[1], mem[2], mem[3], mem[4]);
    end

endmodule