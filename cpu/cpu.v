`include "IF_stage/pc/pc.v"
`include "utils/muxes/mux_32b_2to1.v"
`include "utils/adders/adder_32b_4.v"
`include "pipeline_regs/if_id_pipeline_reg.v"
`include "pipeline_regs/id_ex_pipeline_reg.v"
`include "pipeline_regs/ex_mem_pipeline_reg.v"	
`include "pipeline_regs/mem_wb_pipeline_reg.v"
`include "ID_stage/reg_files/reg_files.v"
`include "ID_stage/sign_extender/sign_extender.v"
`include "ID_stage/control_unit/control_unit.v"
`include "EX_stage/alu/alu.v"
`include "EX_stage/branch/branch_logic.v"
`include "utils/muxes/mux_32b_4to1.v"

`timescale 1ns/100ps

module cpu(
    input [31:0] INST_IF,
    input CLK,
    input RST,
    input [31:0] DMEM_DATA_READ_MA,
    input BUSYWAIT_IN,
    output [31:0] PC_IF,
    output [31:0] DMEM_ADDR_MA,
    output [31:0] DMEM_DATA_WRITE_MA,
    output [3:0] DMEM_READ_MA,
    output [2:0] DMEM_WRITE_MA,
    output BUSYWAIT_OUT
);
    wire BUSYWAIT;
    assign BUSYWAIT = BUSYWAIT_IN;

    // Wires
    //IF
    wire [31:0] PC_INT_IF, PC_PLUS_4_IF;

    //ID
    wire [31:0] INST_ID, PC_ID, DATA1_ID, DATA2_ID, IMM_ID;
    wire [3:0] IMM_SEL_ID;
    wire [4:0] ALU_OP_ID;
    wire [2:0] MEM_WRITE_ID;
    wire [3:0] MEM_READ_ID;
    wire [3:0] BRANCH_JUMP_ID;
    wire [1:0] WB_SEL_ID;
    wire DATA1_ALU_SEL_ID, DATA2_ALU_SEL_ID, WRITE_EN_ID;

    //EX
    wire PC_MUX_SEL_EX;
    wire [31:0] NEXT_PC_EX, PC_EX, DATA1_EX, DATA2_EX, IMM_EX, ALU_OUT_EX, ALU_DATA1_EX, ALU_DATA2_EX;
    wire [3:0] IMM_SEL_EX;
    wire [4:0] ALU_OP_EX, WADDR_EX;
    wire [2:0] MEM_WRITE_EX;
    wire [3:0] BRANCH_JUMP_EX;
    wire [3:0] MEM_READ_EX;
    wire [1:0] WB_SEL_EX;
    wire DATA1_ALU_SEL_EX, DATA2_ALU_SEL_EX, WRITE_EN_EX;

    //MEM
    wire [31:0] PC_MA, ALU_OUT_MA, IMM_MA, DATA2_MA, PC_PLUS_4_MA;
    wire [4:0] WADDR_MA;
    wire [1:0] WB_SEL_MA;
    wire WRITE_EN_MA;
    wire [2:0] MEM_WRITE_MA;
    wire [3:0] MEM_READ_MA;

    //WB
    wire [31:0] WRITE_DATA_WB;
    wire [31:0] PC_WB, ALU_OUT_WB, DMEM_DATA_READ_WB, IMM_WB;
    wire [1:0] WB_SEL_WB;
    wire [4:0] WADDR_WB;
    wire WRITE_EN_WB;

    ////////////////////////////////////////////////////////////////////////
    // Stage 1: Instruction Fetch (IF) 


    // PC mux
    mux_32b_2to1 pc_mux(
        .data1(PC_PLUS_4_IF),
        .data2(NEXT_PC_EX),
        .out(PC_INT_IF),
        .sel(PC_MUX_SEL_EX)
    );

    // PC
    pc pc_inst(
        .clk(CLK),
        .rst(RST),
        .pc_in(PC_INT_IF),
        .pc_out(PC_IF),
        .busywait(BUSYWAIT)
    );

    // PC + 4
    adder_32b_4 pc_plus_4(
        .data(PC_IF),
        .out(PC_PLUS_4_IF)
    );

    // IF/ID pipeline register
    if_id_pipeline_reg if_id_pipeline_reg_inst(
        .clk(CLK),
        .rst(RST),
        .pc_in(PC_IF),
        .pc_out(PC_ID),
        .instr_in(INST_IF),
        .instr_out(INST_ID),
        .busywait(BUSYWAIT)
    );

    // always @(posedge CLK) begin
    //     $display("[IF] PC: %h, Instruction: %h", PC_IF, INST_IF);
    // end

    ////////////////////////////////////////////////////////////////////////
    // Stage 2: Instruction Decode (ID)

    // Register File
    reg_files reg_files_inst(
        .clk(CLK),
        .rst(RST),
        .addr1(INST_ID[19:15]),
        .addr2(INST_ID[24:20]),
        .data1(DATA1_ID),
        .data2(DATA2_ID),
        .we(WRITE_EN_WB),
        .wd(WRITE_DATA_WB),
        .waddr(WADDR_WB)
    );

    // Sign Extender
    sign_extender sign_extender_inst(
        .inst(INST_ID),
        .imm_sel(IMM_SEL_ID),
        .imm_ext(IMM_ID)
    );


    // Control Unit
    control_unit control_unit_inst(
        .opcode(INST_ID[6:0]),
        .funct3(INST_ID[14:12]),
        .funct7(INST_ID[31:25]),
        .reg_write_en(WRITE_EN_ID),
        .data1_alu_sel(DATA1_ALU_SEL_ID),
        .data2_alu_sel(DATA2_ALU_SEL_ID),
        .alu_op(ALU_OP_ID),
        .mem_write(MEM_WRITE_ID),
        .mem_read(MEM_READ_ID),
        .branch_jump(BRANCH_JUMP_ID),
        .imm_sel(IMM_SEL_ID),
        .wb_sel(WB_SEL_ID),
        .reset(RST)
    );

    // always @(posedge CLK) begin
    //     $display("[ID] PC: %h, RS1: %h, RS2: %h, IMM: %h, ALU_OP: %b", PC_ID, DATA1_ID, DATA2_ID, IMM_ID, ALU_OP_ID);
    // end

    // IF/ID pipeline register
    id_ex_pipeline_reg id_ex_pipeline_reg_inst(
        .clk(CLK),
        .rst(RST),
        .reg_write_en_in(WRITE_EN_ID),
        .reg_write_en_out(WRITE_EN_EX),
        .data1_alu_sel_in(DATA1_ALU_SEL_ID),
        .data1_alu_sel_out(DATA1_ALU_SEL_EX),
        .data2_alu_sel_in(DATA2_ALU_SEL_ID),
        .data2_alu_sel_out(DATA2_ALU_SEL_EX),
        .pc_in(PC_ID),
        .pc_out(PC_EX),
        .read_data1_in(DATA1_ID),
        .read_data1_out(DATA1_EX),
        .read_data2_in(DATA2_ID),
        .read_data2_out(DATA2_EX),
        .imm_in(IMM_ID),
        .imm_out(IMM_EX),
        .dest_addr_in(INST_ID[11:7]),
        .dest_addr_out(WADDR_EX),
        .aluop_in(ALU_OP_ID),
        .aluop_out(ALU_OP_EX),
        .mem_write_in(MEM_WRITE_ID),
        .mem_write_out(MEM_WRITE_EX),
        .mem_read_in(MEM_READ_ID),
        .mem_read_out(MEM_READ_EX),
        .branch_jump_in(BRANCH_JUMP_ID),
        .branch_jump_out(BRANCH_JUMP_EX),
        .wb_sel_in(WB_SEL_ID),
        .wb_sel_out(WB_SEL_EX),
        .busywait(BUSYWAIT)
    );


    ////////////////////////////////////////////////////////////////////////
    // Stage 3: Execute (EX)

    // ALU DATA1 mux
    mux_32b_2to1 alu_mux_1(
        .data1(DATA1_EX),
        .data2(PC_EX),
        .out(ALU_DATA1_EX),
        .sel(DATA1_ALU_SEL_EX)
    );

    // ALU DATA2 mux
    mux_32b_2to1 alu_mux_2(
        .data1(DATA2_EX),
        .data2(IMM_EX),
        .out(ALU_DATA2_EX),
        .sel(DATA2_ALU_SEL_EX)
    );

    // ALU
    alu alu_inst(
        .DATA1(ALU_DATA1_EX),
        .DATA2(ALU_DATA2_EX),
        .SELECT(ALU_OP_EX),
        .RESULT(ALU_OUT_EX)
    );

    // Branch/Jump Logic
    branch_logic branch_logic_inst(
        .data1(DATA1_EX),
        .data2(DATA2_EX),
        .op(BRANCH_JUMP_EX),
        .out(PC_MUX_SEL_EX)
    );

    // EX/MA pipeline register
    ex_mem_pipeline_reg ex_mem_pipeline_reg_inst(
        .clk(CLK),
        .rst(RST),
        .reg_write_in(WRITE_EN_EX),
        .reg_write_out(WRITE_EN_MA),
        .pc_in(PC_EX),
        .pc_out(PC_MA),
        .alu_result_in(ALU_OUT_EX),
        .alu_result_out(ALU_OUT_MA),
        .read_data2_in(DATA2_EX),
        .read_data2_out(DATA2_MA),
        .imm_in(IMM_EX),
        .imm_out(IMM_MA),
        .dest_addr_in(WADDR_EX),
        .dest_addr_out(WADDR_MA),
        .mem_write_in(MEM_WRITE_EX),
        .mem_write_out(MEM_WRITE_MA),
        .mem_read_in(MEM_READ_EX),
        .mem_read_out(MEM_READ_MA),
        .wb_sel_in(WB_SEL_EX),
        .wb_sel_out(WB_SEL_MA),
        .busywait(BUSYWAIT)
    );


    ////////////////////////////////////////////////////////////////////////
    // Stage 4: Memory Access (MEM)

    // PC plus 4
    adder_32b_4 pc_plus_4_ma(
        .data(PC_MA),
        .out(PC_PLUS_4_MA)
    );

    // Memeory Access
    assign DMEM_ADDR_MA = ALU_OUT_MA;
    assign DMEM_DATA_WRITE_MA = DATA2_MA;
    assign DMEM_READ_MA = MEM_READ_MA;
    assign DMEM_WRITE_MA = MEM_WRITE_MA;


    // MA/WB pipeline register
    mem_wb_pipeline_reg mem_wb_pipeline_reg_inst(
        .clk(CLK),
        .rst(RST),
        .reg_write_in(WRITE_EN_MA),
        .reg_write_out(WRITE_EN_WB),
        .pc_in(PC_MA),
        .pc_out(PC_WB),
        .mem_data_in(DMEM_DATA_READ_MA),
        .mem_data_out(DMEM_DATA_READ_WB),
        .alu_result_in(ALU_OUT_MA),
        .alu_result_out(ALU_OUT_WB),
        .imm_in(IMM_MA),
        .imm_out(IMM_WB),
        .dest_addr_in(WADDR_MA),
        .dest_addr_out(WADDR_WB),
        .wb_sel_in(WB_SEL_MA),
        .wb_sel_out(WB_SEL_WB),
        .busywait(BUSYWAIT)
    );

    ////////////////////////////////////////////////////////////////////////
    // Stage 5: Write Back (WB)

    // WB mux
    mux_32b_4to1 wb_mux(
        .data1(DMEM_DATA_READ_WB),
        .data2(ALU_OUT_WB),
        .data3(IMM_WB),
        .data4(PC_WB),
        .out(WRITE_DATA_WB),
        .sel(WB_SEL_WB)
    );

endmodule