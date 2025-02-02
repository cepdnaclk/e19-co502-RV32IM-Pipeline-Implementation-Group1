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

    always @(posedge clk) begin
        if (rst == 1'b1) begin
            instr <= 32'dx;
        end
        else begin
            #2 instr <= mem[pc[31:2]];
        end
    end
endmodule