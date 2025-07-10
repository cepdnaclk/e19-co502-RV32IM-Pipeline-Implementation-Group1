// Updated CPU_FPGA module with additional debug outputs
`include "cpu_v2.v"
`include "./IF_stage/imem/imem.v"
`include "./MA_stage/dmem/dmem.v"

`timescale 1ns/100ps

module cpu_fpga(
    input CLK_GEN,
    input RST,
    output reg CLK,
    output wire PC_out,
    output wire INST_out,
    
    // 6 more useful single-bit debug outputs (total 8)
    output wire CPU_ACTIVE,     // CPU is actively executing (not stalled)
    output wire REG_WRITE,      // Register file write operation
    output wire MEM_ACCESS,     // Any memory operation (read or write)
    output wire BRANCH_TAKEN,   // Branch or jump instruction executed
    output wire ALU_ZERO,       // ALU result is zero (important for branches)
    output wire HAZARD_DETECTED // Pipeline hazard detected
);

    reg [31:0] SET_Count;

    // Clock generation
    always @(posedge CLK_GEN) begin
        if (SET_Count == 100000000) begin  
            CLK <= ~CLK;  
            SET_Count <= 32'h0; 
        end else begin
            SET_Count <= SET_Count + 1;
        end
    end

    // Basic outputs
    assign PC_out = |PC;
    assign INST_out = |INST;

    // Internal wires for CPU connections
    wire [31:0] PC, INST, DMEM_DATA_READ, DMEM_DATA_WRITE_INT, DMEM_ADDR_INT;
    wire [3:0] DMEM_READ_INT;
    wire [2:0] DMEM_WRITE_INT;
    wire BUSYWAIT_INT;
    
    // Internal debug signals (previously exposed as outputs)
    // IF Stage Signals
    wire [31:0] PC_PLUS_4_IF;
    
    // ID Stage Signals - Control Unit
    wire WRITE_EN_ID;
    wire DATA1_ALU_SEL_ID;
    wire DATA2_ALU_SEL_ID;
    wire [4:0] ALU_OP_ID;
    wire [2:0] MEM_WRITE_ID;
    wire [3:0] MEM_READ_ID;
    wire [3:0] BRANCH_JUMP_ID;
    wire [3:0] IMM_SEL_ID;
    wire [1:0] WB_SEL_ID;
    
    // ID Stage Signals - Data
    wire [31:0] INST_ID;
    wire [31:0] PC_ID;
    wire [31:0] DATA1_ID;
    wire [31:0] DATA2_ID;
    wire [31:0] IMM_ID;
    
    // ID Stage Signals - Hazard Unit
    wire HAZARD_STALL;
    wire HAZARD_BUBBLE;
    wire [1:0] FORWARDING_DATA1_SEL_ID;
    wire [1:0] FORWARDING_DATA2_SEL_ID;
    
    // EX Stage Signals
    wire [31:0] PC_EX;
    wire [31:0] ALU_OUT_EX;
    wire [31:0] ALU_DATA1_EX;
    wire [31:0] ALU_DATA2_EX;
    wire [31:0] FORWARDING_DATA1;
    wire [31:0] FORWARDING_DATA2;
    wire PC_MUX_SEL_EX;
    wire [4:0] WADDR_EX;
    
    // MEM Stage Signals
    wire [31:0] PC_MA;
    wire [31:0] ALU_OUT_MA;
    wire [31:0] DATA2_MA;
    wire [4:0] WADDR_MA;
    wire WRITE_EN_MA;
    
    // WB Stage Signals
    wire [31:0] PC_WB;
    wire [31:0] ALU_OUT_WB;
    wire [31:0] DMEM_DATA_READ_WB;
    wire [31:0] WRITE_DATA_WB;
    wire [4:0] WADDR_WB;
    wire WRITE_EN_WB;
    wire [1:0] WB_SEL_WB;
    
    // Memory Interface Signals (for internal use)
    wire [31:0] DMEM_ADDR;
    wire [31:0] DMEM_DATA_WRITE;
    wire [3:0] DMEM_READ;
    wire [2:0] DMEM_WRITE;
    wire BUSYWAIT;
    
    // Assign memory interface signals
    assign DMEM_ADDR = DMEM_ADDR_INT;
    assign DMEM_DATA_WRITE = DMEM_DATA_WRITE_INT;
    assign DMEM_READ = DMEM_READ_INT;
    assign DMEM_WRITE = DMEM_WRITE_INT;
    assign BUSYWAIT = BUSYWAIT_INT;

    // single-bit debug output assignments
    assign CPU_ACTIVE = ~(HAZARD_STALL | BUSYWAIT_INT);  // CPU actively executing (not stalled/waiting)
    assign REG_WRITE = WRITE_EN_WB;                      // Register file write enable
    assign MEM_ACCESS = |MEM_READ_ID | |MEM_WRITE_ID;    // Any memory operation happening
    assign BRANCH_TAKEN = PC_MUX_SEL_EX;                 // Branch/jump instruction taken
    assign ALU_ZERO = ~|ALU_OUT_EX;                      // ALU output is zero (critical for conditional branches)
    assign HAZARD_DETECTED = HAZARD_STALL | HAZARD_BUBBLE; // Any pipeline hazard detected

    // Instantiate the CPU module
    cpu cpu_inst(
        .INST_IF(INST),
        .CLK(CLK),
        .RST(RST),
        .DMEM_DATA_READ_MA(DMEM_DATA_READ),
        .PC_IF(PC),
        .DMEM_ADDR_MA(DMEM_ADDR_INT),
        .DMEM_DATA_WRITE_MA(DMEM_DATA_WRITE_INT),
        .DMEM_READ_MA(DMEM_READ_INT),
        .DMEM_WRITE_MA(DMEM_WRITE_INT),
        .BUSYWAIT_IN(BUSYWAIT_INT),
        .BUSYWAIT_OUT(),
        
        // IF Stage Connections
        .PC_PLUS_4_IF_OUT(PC_PLUS_4_IF),
        
        // ID Stage Connections - Control Unit
        .WRITE_EN_ID_OUT(WRITE_EN_ID),
        .DATA1_ALU_SEL_ID_OUT(DATA1_ALU_SEL_ID),
        .DATA2_ALU_SEL_ID_OUT(DATA2_ALU_SEL_ID),
        .ALU_OP_ID_OUT(ALU_OP_ID),
        .MEM_WRITE_ID_OUT(MEM_WRITE_ID),
        .MEM_READ_ID_OUT(MEM_READ_ID),
        .BRANCH_JUMP_ID_OUT(BRANCH_JUMP_ID),
        .IMM_SEL_ID_OUT(IMM_SEL_ID),
        .WB_SEL_ID_OUT(WB_SEL_ID),
        
        // ID Stage Connections - Data
        .INST_ID_OUT(INST_ID),
        .PC_ID_OUT(PC_ID),
        .DATA1_ID_OUT(DATA1_ID),
        .DATA2_ID_OUT(DATA2_ID),
        .IMM_ID_OUT(IMM_ID),
        
        // ID Stage Connections - Hazard Unit
        .HAZARD_STALL_OUT(HAZARD_STALL),
        .HAZARD_BUBBLE_OUT(HAZARD_BUBBLE),
        .FORWARDING_DATA1_SEL_ID_OUT(FORWARDING_DATA1_SEL_ID),
        .FORWARDING_DATA2_SEL_ID_OUT(FORWARDING_DATA2_SEL_ID),
        
        // EX Stage Connections
        .PC_EX_OUT(PC_EX),
        .ALU_OUT_EX_OUT(ALU_OUT_EX),
        .ALU_DATA1_EX_OUT(ALU_DATA1_EX),
        .ALU_DATA2_EX_OUT(ALU_DATA2_EX),
        .FORWARDING_DATA1_OUT(FORWARDING_DATA1),
        .FORWARDING_DATA2_OUT(FORWARDING_DATA2),
        .PC_MUX_SEL_EX_OUT(PC_MUX_SEL_EX),
        .WADDR_EX_OUT(WADDR_EX),
        
        // MEM Stage Connections
        .PC_MA_OUT(PC_MA),
        .ALU_OUT_MA_OUT(ALU_OUT_MA),
        .DATA2_MA_OUT(DATA2_MA),
        .WADDR_MA_OUT(WADDR_MA),
        .WRITE_EN_MA_OUT(WRITE_EN_MA),
        
        // WB Stage Connections
        .PC_WB_OUT(PC_WB),
        .ALU_OUT_WB_OUT(ALU_OUT_WB),
        .DMEM_DATA_READ_WB_OUT(DMEM_DATA_READ_WB),
        .WRITE_DATA_WB_OUT(WRITE_DATA_WB),
        .WADDR_WB_OUT(WADDR_WB),
        .WRITE_EN_WB_OUT(WRITE_EN_WB),
        .WB_SEL_WB_OUT(WB_SEL_WB)
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