`timescale 1ns/100ps

module mem_wb_pipeline_reg(
    input clk, rst,
    input reg_write_in,
    input [31:0] pc_in, mem_data_in, alu_result_in, imm_in,
    input [4:0] dest_addr_in, 
    input [1:0] wb_sel_in,
    input busywait,
    output reg reg_write_out,
    output reg [31:0] pc_out, mem_data_out, alu_result_out, imm_out,
    output reg [4:0] dest_addr_out,
    output reg [1:0] wb_sel_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_write_out <= 1'b0;
            pc_out <= 32'b0;
            mem_data_out <= 32'b0;
            alu_result_out <= 32'b0;
            imm_out <= 32'b0;
            dest_addr_out <= 5'b0;
            wb_sel_out <= 2'b0;
        end else begin
            if (!busywait) begin
            reg_write_out <= reg_write_in;
            pc_out <= pc_in;
            mem_data_out <= mem_data_in;
            alu_result_out <= alu_result_in;
            imm_out <= imm_in;
            dest_addr_out <= dest_addr_in;
            wb_sel_out <= wb_sel_in;  
            end
        end
    end
endmodule