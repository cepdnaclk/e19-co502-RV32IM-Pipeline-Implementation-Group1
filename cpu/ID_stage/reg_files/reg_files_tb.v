`include "reg_files.v"

`timescale 1ns/100ps

module reg_files_tb;

    // Inputs
    reg clk, rst, we;
    reg [4:0] waddr, addr1, addr2;
    reg [31:0] wd;

    // Outputs
    wire [31:0] data1, data2;

    // Instantiate the reg_files module
    reg_files uut (
        .clk(clk),
        .rst(rst),
        .addr1(addr1),
        .addr2(addr2),
        .data1(data1),
        .data2(data2),
        .we(we),
        .wd(wd),
        .waddr(waddr)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Testbench logic
    initial begin
        // Open a file for logging
        $dumpfile("tb_reg_files.vcd");
        $dumpvars(0, reg_files_tb);

        // Initialize inputs
        clk = 0;
        rst = 0;
        we = 0;
        waddr = 5'b0;
        addr1 = 5'b0;
        addr2 = 5'b0;
        wd = 32'b0;

        // Test case 1: Reset the register file
        #10;
        rst = 1;
        #10;
        rst = 0;
        #10;

        // Test case 2: Write to register 5
        waddr = 5'b00101; // Register 5
        wd = 32'h12345678; // Data to write
        we = 1; // Enable write
        #10;

        // Test case 3: Read from register 5 and register 10
        addr1 = 5'b00101; // Read from register 5
        addr2 = 5'b01010; // Read from register 10
        we = 0; // Disable write
        #10;

        // Test case 4: Write to register 10 and read from register 5 simultaneously
        waddr = 5'b01010; // Register 10
        wd = 32'hABCDEF12; // Data to write
        we = 1; // Enable write
        addr1 = 5'b00101; // Read from register 5
        addr2 = 5'b01010; // Read from register 10
        #10;

        // Test case 5: Read from register 10 after write
        we = 0; // Disable write
        #10;

        // End simulation
        $finish;
    end

    // Monitor to print inputs and outputs
    initial begin
        $monitor("Time: ", $time, "| clk: %b | rst: %b | we: %b | waddr: %b | addr1: %b | addr2: %b | wd: %h | data1: %h | data2: %h",
                    clk, rst, we, waddr, addr1, addr2, wd, data1, data2);
    end

endmodule