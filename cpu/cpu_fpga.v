// Updated CPU_FPGA module with key pipeline stage signal outputs
`include "cpu_v2.v"
`include "./IF_stage/imem/imem.v"
`include "./MA_stage/dmem/dmem.v"

`timescale 1ns/100ps

module cpu_fpga(
    input CLK_GEN,
    input RST,
    output reg CLK,
    output wire [31:0] PC_out,
    output wire [31:0] INST_out,
    
    // IF Stage Outputs
    output wire [31:0] PC_PLUS_4_IF,
    
    // ID Stage Outputs - Control Unit Signals
    output wire WRITE_EN_ID,
    output wire DATA1_ALU_SEL_ID,
    output wire DATA2_ALU_SEL_ID,
    output wire [4:0] ALU_OP_ID,
    output wire [2:0] MEM_WRITE_ID,
    output wire [3:0] MEM_READ_ID,
    output wire [3:0] BRANCH_JUMP_ID,
    output wire [3:0] IMM_SEL_ID,
    output wire [1:0] WB_SEL_ID,
    
    // ID Stage Outputs - Data Signals
    output wire [31:0] INST_ID,
    output wire [31:0] PC_ID,
    output wire [31:0] DATA1_ID,
    output wire [31:0] DATA2_ID,
    output wire [31:0] IMM_ID,
    
    // ID Stage Outputs - Hazard Unit Signals
    output wire HAZARD_STALL,
    output wire HAZARD_BUBBLE,
    output wire [1:0] FORWARDING_DATA1_SEL_ID,
    output wire [1:0] FORWARDING_DATA2_SEL_ID,
    
    // EX Stage Outputs
    output wire [31:0] PC_EX,
    output wire [31:0] ALU_OUT_EX,
    output wire [31:0] ALU_DATA1_EX,
    output wire [31:0] ALU_DATA2_EX,
    output wire [31:0] FORWARDING_DATA1,
    output wire [31:0] FORWARDING_DATA2,
    output wire PC_MUX_SEL_EX,
    output wire [4:0] WADDR_EX,
    
    // MEM Stage Outputs
    output wire [31:0] PC_MA,
    output wire [31:0] ALU_OUT_MA,
    output wire [31:0] DATA2_MA,
    output wire [4:0] WADDR_MA,
    output wire WRITE_EN_MA,
    
    // WB Stage Outputs
    output wire [31:0] PC_WB,
    output wire [31:0] ALU_OUT_WB,
    output wire [31:0] DMEM_DATA_READ_WB,
    output wire [31:0] WRITE_DATA_WB,
    output wire [4:0] WADDR_WB,
    output wire WRITE_EN_WB,
    output wire [1:0] WB_SEL_WB,
    
    // Memory Interface Outputs (for debugging)
    output wire [31:0] DMEM_ADDR,
    output wire [31:0] DMEM_DATA_WRITE,
    output wire [3:0] DMEM_READ,
    output wire [2:0] DMEM_WRITE,
    output wire BUSYWAIT
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
    assign PC_out = PC;
    assign INST_out = INST;

    // Internal wires
    wire [31:0] PC, INST, DMEM_DATA_READ, DMEM_DATA_WRITE_INT, DMEM_ADDR_INT;
    wire [3:0] DMEM_READ_INT;
    wire [2:0] DMEM_WRITE_INT;
    wire BUSYWAIT_INT;
    
    // Assign memory interface outputs
    assign DMEM_ADDR = DMEM_ADDR_INT;
    assign DMEM_DATA_WRITE = DMEM_DATA_WRITE_INT;
    assign DMEM_READ = DMEM_READ_INT;
    assign DMEM_WRITE = DMEM_WRITE_INT;
    assign BUSYWAIT = BUSYWAIT_INT;

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