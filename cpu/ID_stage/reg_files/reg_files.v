`timescale 1ns/100ps

module reg_files(clk, rst, addr1, addr2, data1, data2, we, wd, waddr);
    input clk, rst, we;
    input [4:0] waddr, addr1, addr2;
    input [31:0] wd;
    output [31:0] data1, data2;

    reg [31:0] mem[31:0];

    assign #1 data1 = mem[addr1];
    assign #1 data2 = mem[addr2];

    always @(negedge clk) begin
        if(rst == 1'b1) begin
            #2
            mem[0] <= 32'b0;
            mem[1] <= 32'b0;
            mem[2] <= 32'b0;
            mem[3] <= 32'b0;
            mem[4] <= 32'b0;
            mem[5] <= 32'b0;
            mem[6] <= 32'b0;
            mem[7] <= 32'b0;
            mem[8] <= 32'b0;
            mem[9] <= 32'b0;
            mem[10] <= 32'b0;
            mem[11] <= 32'b0;
            mem[12] <= 32'b0;
            mem[13] <= 32'b0;
            mem[14] <= 32'b0;
            mem[15] <= 32'b0;
            mem[16] <= 32'b0;
            mem[17] <= 32'b0;
            mem[18] <= 32'b0;
            mem[19] <= 32'b0;
            mem[20] <= 32'b0;
            mem[21] <= 32'b0;
            mem[22] <= 32'b0;
            mem[23] <= 32'b0;
            mem[24] <= 32'b0;
            mem[25] <= 32'b0;
            mem[26] <= 32'b0;
            mem[27] <= 32'b0;
            mem[28] <= 32'b0;
            mem[29] <= 32'b0;
            mem[30] <= 32'b0;
            mem[31] <= 32'b0;
        end
        else if(we == 1'b1 && waddr != 5'd0) begin
            #2 mem[waddr] <= wd;
        end

        // $display("mem[0] = %d, mem[1] = %d, mem[2] = %d, mem[3] = %d, mem[4] = %d" , mem[0], mem[1], mem[2], mem[3], mem[4]);
    end

endmodule