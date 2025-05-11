`ifdef TB_RUN
    `define MEMFILE "../imem/memfile.mem"
`else
    `define MEMFILE "./IF_stage/imem/memfile.mem"
`endif

`timescale 1ns/100ps

// instruction memmory with memfile
module imem(clk, rst, pc, instr);
    input clk, rst;
    input [31:0] pc;
    output reg [31:0] instr;

    reg [31:0] mem[0:1023];

    initial begin
        $readmemh(`MEMFILE, mem);
    end

    always @(negedge clk) begin
        if (rst == 1'b1) begin
            instr <= 32'd0;
            // mem[0] = 32'h00500093;   // ADDI x1, x0, 5
            // mem[1] = 32'h00A00113;   // ADDI x2, x0, 10
            // mem[2] = 32'h002081B3;   // ADD x3, x1, x2
            // mem[3] = 32'h00302023;   // SW x3, 0(x0)
            // mem[4] = 32'h00002203;   // LW x4, 0(x0)
            // mem[5] = 32'h002202b3;   // ADD x5, x4, x2
        end
        else begin
            instr <= #2 mem[pc[31:2]];
        end
    end
endmodule