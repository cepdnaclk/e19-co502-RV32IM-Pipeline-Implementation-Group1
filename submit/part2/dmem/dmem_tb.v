`include "dmem.v"
`timescale 1ns/100ps

module dmem_tb;

    // Testbench Signals
    reg clock;
    reg reset;
    reg [3:0] read;
    reg [2:0] write;
    reg [31:0] address;
    reg [31:0] writedata;
    wire [31:0] readdata;
    wire busywait;

    // Instantiate the dmem module
    dmem uut (
        .clock(clock),
        .reset(reset),
        .read(read),
        .write(write),
        .address(address),
        .writedata(writedata),
        .readdata(readdata),
        .busywait(busywait)
    );

    // Clock generation
    always #5 clock = ~clock;

    initial begin
        // Initialization
        clock = 0;
        reset = 0;
        read = 0;
        write = 0;
        address = 0;
        writedata = 0;

        // Reset memory
        #10 reset = 1;
        #10 reset = 0;

        // === STORE WORD ===
        #10;
        address = 32'h10;
        writedata = 32'hAABBCCDD;
        write = 3'b110; // SW (funct3 = 010)
        #10 write = 3'b000;

        // === LOAD WORD ===
        #10;
        address = 32'h10;
        read = 4'b1010; // LW (funct3 = 010)
        #10 read = 4'b0000;

        // === LOAD BYTE (signed) ===
        #10;
        address = 32'h10;
        read = 4'b1000; // LB (funct3 = 000)
        #10 read = 4'b0000;

        // === LOAD BYTE UNSIGNED ===
        #10;
        address = 32'h10;
        read = 4'b1100; // LBU (funct3 = 100)
        #10 read = 4'b0000;

        // === LOAD HALF (signed) ===
        #10;
        address = 32'h10;
        read = 4'b1001; // LH (funct3 = 001)
        #10 read = 4'b0000;

        // === LOAD HALF UNSIGNED ===
        #10;
        address = 32'h10;
        read = 4'b1101; // LHU (funct3 = 101)
        #10 read = 4'b0000;

        // === STORE BYTE ===
        #10;
        address = 32'h20;
        writedata = 32'h0000007F; // Byte value 0x7F
        write = 3'b100; // SB (funct3 = 000)
        #10 write = 3'b000;

        // === LOAD BYTE from 0x20 (signed) ===
        #10;
        address = 32'h20;
        read = 4'b1000; // LB
        #10 read = 4'b0000;

        // === STORE HALF ===
        #10;
        address = 32'h30;
        writedata = 32'h00007FFF; // Halfword 0x7FFF
        write = 3'b101; // SH (funct3 = 001)
        #10 write = 3'b000;

        // === LOAD HALF from 0x30 (signed) ===
        #10;
        address = 32'h30;
        read = 4'b1010; // LH
        #10 read = 4'b0000;

        // === LOAD HALF from 0x30 (unsigned) ===
        #10;
        address = 32'h30;
        read = 4'b1101; // LHU
        #10 read = 4'b0000;

        // End simulation
        #50;
        $finish;
    end

    // Monitor signal activity
    initial begin
        $monitor("T=%0t | Addr=0x%h | WData=0x%h | RData=0x%h | Write=%b | Read=%b | BusyWait=%b", 
                 $time, address, writedata, readdata, write, read, busywait);
    end

endmodule
