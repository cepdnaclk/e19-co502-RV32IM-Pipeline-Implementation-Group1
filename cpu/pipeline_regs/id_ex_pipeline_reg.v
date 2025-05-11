`timescale 1ns/100ps

module id_ex_pipeline_reg(
    input clk, rst,
    input reg_write_en_in, data1_alu_sel_in, data2_alu_sel_in,
    input [31:0] pc_in, read_data1_in, read_data2_in,
    input [4:0] dest_addr_in, aluop_in,
    input [3:0] branch_jump_in,
    input [2:0] mem_write_in,
    input [3:0] mem_read_in,
    input [1:0] wb_sel_in,
    input busywait,
    output reg reg_write_en_out, data1_alu_sel_out, data2_alu_sel_out,
    output reg [31:0] pc_out, read_data1_out, read_data2_out,
    output reg [4:0] dest_addr_out, aluop_out,
    output reg [3:0] branch_jump_out,
    output reg [2:0] mem_write_out,
    output reg [3:0] mem_read_out,
    output reg [1:0] wb_sel_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_write_en_out <= 0;
            data1_alu_sel_out <= 0;
            data2_alu_sel_out <= 0;
            pc_out <= 0;
            read_data1_out <= 0;
            read_data2_out <= 0;
            dest_addr_out <= 0;
            aluop_out <= 0;
            mem_write_out <= 0;
            branch_jump_out <= 0;
            mem_read_out <= 0;
            wb_sel_out <= 0;
        end else begin
            if (!busywait) begin
            reg_write_en_out <= reg_write_en_in;
            data1_alu_sel_out <= data1_alu_sel_in;
            data2_alu_sel_out <= data2_alu_sel_in;
            pc_out <= pc_in;
            read_data1_out <= read_data1_in;
            read_data2_out <= read_data2_in;
            dest_addr_out <= dest_addr_in;
            aluop_out <= aluop_in;
            mem_write_out <= mem_write_in;
            branch_jump_out <= branch_jump_in;
            mem_read_out <= mem_read_in;
            wb_sel_out <= wb_sel_in;
            end
        end
    end

endmodule
