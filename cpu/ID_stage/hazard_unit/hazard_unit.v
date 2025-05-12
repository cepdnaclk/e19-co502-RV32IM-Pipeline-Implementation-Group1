`timescale 1ns / 100ps

module hazard_unit(
    input wire [4:0] addr1,      // rs1 address
    input wire [4:0] addr2,      // rs2 address
    
    input wire [4:0] ex_rd,      // Destination register in EX stage
    input wire [4:0] mem_rd,     // Destination register in MEM stage
    
    input wire ex_we,            // Register write enable in EX stage
    input wire mem_we,           // Register write enable in MEM stage
    input wire ex_memr,          // Memory read in EX stage (load instruction)
    input wire mem_memr,         // Memory read in MEM stage
    
    output reg [1:0] forwarding_data1sel,   // Forwarding select for rs1 (00:ID, 01:EX, 10:MEM)
    output reg [1:0] forwarding_data2sel,   // Forwarding select for rs2 (00:ID, 01:EX, 10:MEM)
    
    output reg bubble,           // Insert bubble in pipeline
    output reg stall             // Stall pipeline stages
);

    // Detect when registers are actually used (non-zero register addresses)
    wire rs1_used = (addr1 != 5'b00000);
    wire rs2_used = (addr2 != 5'b00000);
    
    // Detect load-use hazard (when a load instruction is followed by an instruction that uses its result)
    wire load_use_hazard = ex_memr && (
        (rs1_used && (addr1 == ex_rd)) || 
        (rs2_used && (addr2 == ex_rd))
    );
    
    // Detect data hazards for forwarding
    wire ex_hazard_rs1 = ex_we && rs1_used && (addr1 == ex_rd);
    wire ex_hazard_rs2 = ex_we && rs2_used && (addr2 == ex_rd);
    wire mem_hazard_rs1 = mem_we && rs1_used && (addr1 == mem_rd);
    wire mem_hazard_rs2 = mem_we && rs2_used && (addr2 == mem_rd);

    always @(*) begin
        // Default values (no hazard)
        forwarding_data1sel = 2'b00;  // No forwarding
        forwarding_data2sel = 2'b00;  // No forwarding
        bubble = 1'b0;                // No bubble inserted
        stall = 1'b0;                 // No stall
        
        if (load_use_hazard) begin
            bubble = 1'b1;            // Insert bubble in EX stage
            stall = 1'b1;             // Stall IF/ID stages
            
            // No forwarding during load-use hazard
            forwarding_data1sel = 2'b00;
            forwarding_data2sel = 2'b00;
        end
        else begin
            // Handle data forwarding for rs1
            if (ex_hazard_rs1) begin
                forwarding_data1sel = 2'b01;
            end
            else if (mem_hazard_rs1) begin
                forwarding_data1sel = 2'b10;
            end
            
            // Handle data forwarding for rs2
            if (ex_hazard_rs2) begin
                forwarding_data2sel = 2'b01;
            end
            else if (mem_hazard_rs2) begin
                forwarding_data2sel = 2'b10;
            end
        end
    end

endmodule