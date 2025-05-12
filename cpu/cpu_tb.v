`include "cpu.v"
`include "./IF_stage/imem/imem.v"
`include "./MA_stage/dmem/dmem.v"

`timescale 1ns/100ps

module cpu_tb(
    input wire CLK
);

    // Inputs
    // reg CLK;
    reg RST;

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

    // Clock generation
    // always #5 CLK = ~CLK;

    // Testbench logic
    initial begin
        // Open a file for logging
        $dumpfile("cpu_tb.vcd");
        $dumpvars(0, cpu_tb);

        // Initialize inputs
        CLK = 0;
        RST = 1; // Assert reset

        // Wait for global reset
        #15;
        RST = 0; // Deassert reset

        // Run the simulation for a few clock cycles
        #700;

        // End simulation
        $finish;
    end

    // // Monitor to print inputs and outputs
    // initial begin
    //     $monitor($time, " | CLK: %b | RST: %b | PC: %h | INST: %h | DMEM_ADDR: %h | DMEM_DATA_WRITE: %h | DMEM_DATA_READ: %h | DMEM_READ: %b | DMEM_WRITE: %b | BUSYWAIT: %b",
    //              CLK, RST, PC, INST, DMEM_ADDR, DMEM_DATA_WRITE, DMEM_DATA_READ, DMEM_READ, DMEM_WRITE, BUSYWAIT);
    // end

    // Monitor to print inputs and outputs
    // initial begin
    //     $monitor($time, " | CLK: %b | RST: %b | PC: %h | INST: %h",  CLK, RST, PC, INST);
    // end

endmodule