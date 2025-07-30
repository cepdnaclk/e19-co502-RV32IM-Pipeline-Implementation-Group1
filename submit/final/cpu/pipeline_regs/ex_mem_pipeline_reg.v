`timescale 1ns/100ps

module ex_mem_pipeline_reg(
    input clk, rst, reg_write_in,
    input [31:0] pc_in, alu_result_in, read_data2_in,
    input [4:0] dest_addr_in,
    input [2:0] mem_write_in,
    input [3:0] mem_read_in,
    input [1:0] wb_sel_in,
    input busywait,
    output reg reg_write_out,
    output reg [31:0] pc_out, alu_result_out, read_data2_out,
    output reg [4:0] dest_addr_out,
    output reg [2:0] mem_write_out,
    output reg [3:0] mem_read_out,
    output reg [1:0] wb_sel_out
);
    always @(posedge clk) begin
        if (rst) begin
            reg_write_out <= #1 1'b0;
            dest_addr_out <= #1 5'b0;
            pc_out <= #1 32'b0;
            alu_result_out <= #1 32'b0;
            read_data2_out <= #1 32'b0;
            mem_write_out <= #1 3'b0;
            mem_read_out <= #1 4'b0;
            wb_sel_out <= #1 2'b0;
        end
        else begin
            if (!busywait) begin
                reg_write_out <= #1 reg_write_in;
                dest_addr_out <= #1 dest_addr_in;
                pc_out <= #1 pc_in;
                alu_result_out <= #1 alu_result_in;
                read_data2_out <= #1 read_data2_in;
                mem_read_out <= #1 mem_read_in;
                mem_write_out <= #1 mem_write_in;
                wb_sel_out <= #1 wb_sel_in;
            end
        end
    end

endmodule