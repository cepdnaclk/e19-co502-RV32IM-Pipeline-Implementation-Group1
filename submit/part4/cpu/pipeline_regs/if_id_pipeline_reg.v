`timescale 1ns/100ps

module if_id_pipeline_reg(clk, rst, pc_in, pc_out, instr_in, instr_out, busywait);
    input clk, rst;
    input [31:0] pc_in, instr_in;
    input busywait;
    output reg [31:0] pc_out, instr_out;

    always @(posedge clk) begin
        if (rst == 1'b1) begin
            pc_out <= #1 32'd0;
            instr_out <= #1 32'd0;
        end
        else begin
            if (!busywait) begin
                pc_out <= #1 pc_in;
                instr_out <= #1 instr_in;
            end
        end
    end
endmodule