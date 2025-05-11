`timescale 1ns/100ps

module id_ex_pipeline_reg(
    input clk, rst,
    input reg_write_en_in, data1_alu_sel_in, data2_alu_sel_in,
    input [31:0] pc_in, read_data1_in, read_data2_in, imm_in,
    input [4:0] dest_addr_in, aluop_in,
    input [3:0] branch_jump_in,
    input [2:0] mem_write_in,
    input [3:0] mem_read_in,
    input [1:0] wb_sel_in, data1sel_in, data2sel_in,
    input busywait,
    output reg reg_write_en_out, data1_alu_sel_out, data2_alu_sel_out,
    output reg [31:0] pc_out, read_data1_out, read_data2_out, imm_out,
    output reg [4:0] dest_addr_out, aluop_out,
    output reg [3:0] branch_jump_out,
    output reg [2:0] mem_write_out,
    output reg [3:0] mem_read_out,
    output reg [1:0] wb_sel_out, data1sel_out, data2sel_out
);
    always @(posedge clk) begin
        if (rst) begin
            reg_write_en_out <= #1 0;
            data1_alu_sel_out <= #1 0;
            data2_alu_sel_out <= #1 0;
            pc_out <= #1 0;
            read_data1_out <= #1 0;
            read_data2_out <= #1 0;
            imm_out <= #1 0;
            dest_addr_out <= #1 0;
            aluop_out <= #1 0;
            mem_write_out <= #1 0;
            branch_jump_out <= #1 0;
            mem_read_out <= #1 0;
            wb_sel_out <= #1 0;
            data1sel_out <= #1 0;
            data2sel_out <= #1 0;
        end else begin
            if (!busywait) begin
                reg_write_en_out <= #1 reg_write_en_in;
                data1_alu_sel_out <= #1 data1_alu_sel_in;
                data2_alu_sel_out <= #1 data2_alu_sel_in;
                pc_out <= #1 pc_in;
                read_data1_out <= #1 read_data1_in;
                read_data2_out <= #1 read_data2_in;
                imm_out <= #1 imm_in;
                dest_addr_out <= #1 dest_addr_in;
                aluop_out <= #1 aluop_in;
                mem_write_out <= #1 mem_write_in;
                branch_jump_out <= #1 branch_jump_in;
                mem_read_out <= #1 mem_read_in;
                wb_sel_out <= #1 wb_sel_in;
                data1sel_out <= #1 data1sel_in;
                data2sel_out <= #1 data2sel_in;
            end
        end
    end

endmodule