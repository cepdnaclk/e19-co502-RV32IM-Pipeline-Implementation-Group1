`timescale 1ns/100ps

module dmem(
	clock,
    reset,
    read,
    write,
    address,
    writedata,
    readdata,
	busywait,
	DEBUG_DATA,
	DEBUG_READ_ACC,
	DEBUG_WRITE_ACC
);

input				clock;
input           	reset;
input[3:0]      	read;
input[2:0]        	write;
input[31:0]      	address;
input[31:0]     	writedata;
output reg [31:0]	readdata;
output reg      	busywait;
output [31:0] 		DEBUG_DATA;
output DEBUG_READ_ACC, DEBUG_WRITE_ACC;

assign DEBUG_DATA = memory_array[0];
assign DEBUG_READ_ACC = readaccess;
assign DEBUG_WRITE_ACC = writeaccess;

reg readaccess, writeaccess;
reg [7:0] memory_array [255:0];

integer i;

// Read & Write Operations
always @(negedge clock)
begin
    if (reset)
    begin
        for (i=0; i<256; i=i+1)
            memory_array[i] = 8'b0;

        busywait = 0;
        readaccess = 0;
        writeaccess = 0;
    end
    else
    begin
        readaccess = (read[3] && !write[2]) ? 1'b1 : 1'b0;
        writeaccess = (!read[3] && write[2]) ? 1'b1 : 1'b0;

        // if (readaccess || writeaccess)
        //     busywait = 1;
        // else
        //     busywait = 0;

        if (readaccess)
        begin
            readdata[7:0]   = memory_array[{address[31:2],2'b00}];
            readdata[15:8]  = memory_array[{address[31:2],2'b01}];
            readdata[23:16] = memory_array[{address[31:2],2'b10}];
            readdata[31:24] = memory_array[{address[31:2],2'b11}];
        end
        if (writeaccess)
        begin
            memory_array[{address[31:2],2'b00}] = writedata[7:0];
            memory_array[{address[31:2],2'b01}] = writedata[15:8];
            memory_array[{address[31:2],2'b10}] = writedata[23:16];
            memory_array[{address[31:2],2'b11}] = writedata[31:24];
        end
    end
end

endmodule
