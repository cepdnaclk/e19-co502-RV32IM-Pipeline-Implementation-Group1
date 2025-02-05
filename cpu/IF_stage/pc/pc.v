`timescale 1ns/100ps

module pc(clk, rst, pc_in, pc_out, busywait);
    input clk, rst;
    input [31:0] pc_in;
    input busywait;
    output reg [31:0] pc_out;

    always @(posedge clk) begin
        #1
        if (rst == 1'b1) begin
            pc_out <= 32'h0;
        end
        else begin
            if (!busywait) begin
                #1 pc_out <= pc_in;
            end
        end
    end
endmodule