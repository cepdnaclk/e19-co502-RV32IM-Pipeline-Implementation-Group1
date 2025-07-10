`ifdef TB_RUN
    `define MEMFILE "../imem/memfile.mem"
`else
    // `define MEMFILE "./IF_stage/imem/memfile.mem"
    `define MEMFILE "memfile.mem"
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
            // mem[0]  = 32'h00100093;  // ADDI x1, x0, 1
            // mem[1]  = 32'h00100093;  // (Same as above) Overwrites mem[0] unless intentional
            // mem[2]  = 32'h00000113;  // ADDI x2, x0, 0
            // mem[3]  = 32'h00000293;  // ADDI x5, x0, 0
            // mem[4]  = 32'h00600393;  // ADDI x7, x0, 6
            // mem[5]  = 32'h002081b3;  // ADD x3, x1, x2
            // mem[6]  = 32'h00008113;  // ADDI x2, x1, 0
            // mem[7]  = 32'h00018093;  // ADDI x1, x3, 0
            // mem[8]  = 32'h0032a023;  // SW x3, 0(x5)
            // mem[9]  = 32'h00428293;  // ADDI x5, x5, 4
            // mem[10] = 32'hfff38393;  // ADDI x7, x7, -1
            // mem[11] = 32'h00038463;  // BEQ x7, x0, +8
            // mem[12] = 32'hfe5ff06f;  // JAL x0, -28
            // mem[13] = 32'hffc2a303;  // LW x6, -4(x5)
            // mem[14] = 32'h006300b3;  // ADD x1, x6, x6
            // mem[15] = 32'h0000006f;  // JAL x0, 0 (infinite loop)
        end
        else begin
            instr <= #2 mem[pc[31:2]];
        end
    end

endmodule