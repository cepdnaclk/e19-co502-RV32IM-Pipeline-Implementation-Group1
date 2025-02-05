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
    wire [31:0] DEBUG_DATA;
    wire DEBUG_READ_ACC;
    wire DEBUG_WRITE_ACC;

    // Instantiate the dmem module
    dmem uut (
        .clock(clock),
        .reset(reset),
        .read(read),
        .write(write),
        .address(address),
        .writedata(writedata),
        .readdata(readdata),
        .busywait(busywait),
        .DEBUG_DATA(DEBUG_DATA),
        .DEBUG_READ_ACC(DEBUG_READ_ACC),
        .DEBUG_WRITE_ACC(DEBUG_WRITE_ACC)
    );

    // Generate a clock signal (10ns period -> 100MHz)
    always #5 clock = ~clock;

    initial begin
        // Initialize signals
        clock = 0;
        reset = 0;
        read = 0;
        write = 0;
        address = 0;
        writedata = 0;
        
        // Apply reset
        #10 reset = 1;
        #10 reset = 0;

        // Write to memory at address 0x04
        #10;
        address = 32'h04;
        writedata = 32'hAABBCCDD;
        write = 3'b100; // Write enable
        #10 write = 3'b000; // Disable write
        
        // Read from memory at address 0x04
        #10;
        address = 32'h04;
        read = 4'b1000; // Read enable
        #10 read = 4'b0000; // Disable read

        // Write to memory at address 0x08
        #10;
        address = 32'h08;
        writedata = 32'h11223344;
        write = 3'b100;
        #10 write = 3'b000;

        // Read from memory at address 0x08
        #10;
        address = 32'h08;
        read = 4'b1000;
        #10 read = 4'b0000;

        // End simulation
        #50;
        $finish;
    end

    // Monitor changes in memory access
    initial begin
        $monitor("Time=%0t | Address=0x%h | WriteData=0x%h | ReadData=0x%h | Write=%b | Read=%b | BusyWait=%b", 
                  $time, address, writedata, readdata, write, read, busywait);
    end

endmodule
