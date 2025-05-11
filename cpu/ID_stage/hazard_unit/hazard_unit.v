`timescale 1ns / 100ps

module hazard_unit(
    // Register addresses from ID stage
    input wire [4:0] addr1,      // rs1 address
    input wire [4:0] addr2,      // rs2 address
    
    // Destination registers from later stages
    input wire [4:0] ex_rd,      // Destination register in EX stage
    input wire [4:0] mem_rd,     // Destination register in MEM stage
    
    // Control signals from later stages
    input wire ex_we,            // Register write enable in EX stage
    input wire mem_we,           // Register write enable in MEM stage
    input wire ex_memr,          // Memory read in EX stage (load instruction)
    input wire mem_memr,         // Memory read in MEM stage (not used in this implementation)
    
    // Forwarding control signals
    output reg [1:0] forwarding_data1sel,   // Forwarding select for rs1 (00:ID, 01:EX, 10:MEM)
    output reg [1:0] forwarding_data2sel,   // Forwarding select for rs2 (00:ID, 01:EX, 10:MEM)
    
    // Pipeline control signals
    output reg bubble,           // Insert bubble in pipeline
    output reg stall             // Stall pipeline stages
);

    // Internal signal for load-use hazard detection
    wire load_use_hazard;
    
    // Detect load-use hazard (when a load instruction is followed by an instruction that uses its result)
    assign load_use_hazard = ex_memr && ((addr1 == ex_rd && ex_rd != 0) || (addr2 == ex_rd && ex_rd != 0));

    always @(*) begin
        // Default values (no hazard)
        forwarding_data1sel = 2'b00;
        forwarding_data2sel = 2'b00;
        bubble = 1'b0;
        stall = 1'b0;
        
        // Handle load-use hazard first (highest priority)
        if (load_use_hazard) begin
            // Stall the pipeline and insert a bubble
            stall = 1'b1;
            bubble = 1'b1;
        end
        else begin
            // Data forwarding logic
            
            // Forward from EX stage (highest priority)
            if (ex_we && ex_rd != 0) begin
                // Forward for rs1
                if (addr1 == ex_rd) begin
                    forwarding_data1sel = 2'b01;
                end
                
                // Forward for rs2
                if (addr2 == ex_rd) begin
                    forwarding_data2sel = 2'b01;
                end
            end
            
            // Forward from MEM stage (lower priority)
            if (mem_we && mem_rd != 0) begin
                // Forward for rs1 (if not already forwarded from EX)
                if (addr1 == mem_rd && !(ex_we && addr1 == ex_rd)) begin
                    forwarding_data1sel = 2'b10;
                end
                
                // Forward for rs2 (if not already forwarded from EX)
                if (addr2 == mem_rd && !(ex_we && addr2 == ex_rd)) begin
                    forwarding_data2sel = 2'b10;
                end
            end
        end
    end

endmodule