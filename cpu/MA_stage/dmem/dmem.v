`timescale 1ns/100ps

module dmem(
	input wire clock,
    input wire reset,   
    input wire [3:0] read, // funct3 field for load
    input wire [2:0] write, // funct3 field for store
    input wire [31:0] address, // address to read/write
    input wire [31:0] writedata, // data to write
    output reg [31:0] readdata, // data to read
    output reg busywait // busywait signal
);

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

            // busywait = (readaccess || writeaccess) ? 1'b1 : 1'b0;

            if (readaccess) begin
                #2;
                case (read[2:0]) // funct3 field for load
                    3'b000: begin // LB
                        readdata = {{24{memory_array[address][7]}}, memory_array[address]};
                    end
                    3'b001: begin // LH
                        readdata = {{16{memory_array[address+1][7]}}, memory_array[address+1], memory_array[address]};
                    end
                    3'b010: begin // LW
                        readdata = {memory_array[address+3], memory_array[address+2], memory_array[address+1], memory_array[address]};
                    end
                    3'b100: begin // LBU
                        readdata = {24'b0, memory_array[address]};
                    end
                    3'b101: begin // LHU
                        readdata = {16'b0, memory_array[address+1], memory_array[address]};
                    end
                    default: begin
                        readdata = 32'b0; // invalid funct3
                    end
                endcase
            end


            if (writeaccess) begin
                #2;
                case (write[1:0]) // funct3 field for store
                    2'b00: begin // SB
                        memory_array[address] = writedata[7:0];
                    end
                    2'b01: begin // SH
                        memory_array[address]   = writedata[7:0];
                        memory_array[address+1] = writedata[15:8];
                    end
                    2'b10: begin // SW
                        memory_array[address]   = writedata[7:0];
                        memory_array[address+1] = writedata[15:8];
                        memory_array[address+2] = writedata[23:16];
                        memory_array[address+3] = writedata[31:24];
                    end
                    default: ;
                endcase
            end
        end
    end

endmodule
