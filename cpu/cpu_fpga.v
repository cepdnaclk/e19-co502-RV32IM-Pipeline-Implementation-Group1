`include "cpu.v"
`include "./IF_stage/imem/imem.v"
`include "./MA_stage/dmem/dmem.v"

`timescale 1ns/100ps

module cpu_fpga(
    input CLK_GEN,
    input RST,
    output reg CLK
);
    reg [31:0] SET_Count;

    always @(posedge CLK_GEN) begin
        if (SET_Count == 100000000) begin  
            CLK <= ~CLK;  
            SET_Count <= 32'h0; 
        end else begin
            SET_Count <= SET_Count + 1;
        end
    end

    // Outputs
    wire [31:0] PC, INST, DMEM_DATA_READ, DMEM_DATA_WRITE, DMEM_ADDR;
    wire [3:0] DMEM_READ;
    wire [2:0] DMEM_WRITE;
    wire BUSYWAIT;

    // Instantiate the CPU module
    cpu cpu_inst(
        .INST_IF(INST),
        .CLK(CLK),
        .RST(RST),
        .DMEM_DATA_READ_MA(DMEM_DATA_READ),
        .PC_IF(PC),
        .DMEM_ADDR_MA(DMEM_ADDR),
        .DMEM_DATA_WRITE_MA(DMEM_DATA_WRITE),
        .DMEM_READ_MA(DMEM_READ),
        .DMEM_WRITE_MA(DMEM_WRITE),
        .BUSYWAIT_IN(BUSYWAIT),
        .BUSYWAIT_OUT()
    );

    // Instantiate the instruction memory module
    imem imem_inst(
        .clk(CLK),
        .rst(RST),
        .pc(PC),
        .instr(INST)
    );

    // Instantiate the data memory module
    dmem dmem_inst(
        .clock(CLK),
        .reset(RST),
        .read(DMEM_READ),
        .write(DMEM_WRITE),
        .address(DMEM_ADDR),
        .writedata(DMEM_DATA_WRITE),
        .readdata(DMEM_DATA_READ),
        .busywait(BUSYWAIT)
    );

endmodule