`ifdef TB_RUN
    `include "../../utils/encordings.v"
`else
    `include "./utils/encordings.v"
`endif

`timescale 1ns/100ps

module sign_extender(inst, imm_sel, imm_ext);

input [31:0] inst;
input [3:0] imm_sel;
output reg [31:0] imm_ext;

// Immediate types
wire [19:0] TYPE1; // U-type and J-type upper part
wire [11:0] TYPE3; // I-type
wire [11:0] TYPE5; // S-type
wire [4:0] TYPE6;  // Shamt

assign TYPE1 = inst[31:12]; 
assign TYPE3 = inst[31:20]; 
assign TYPE5 = {inst[31:25], inst[11:7]}; 
assign TYPE6 = inst[24:20]; 

always @(*) begin
    case (imm_sel[2:0])
        // U-type
        `IMM_TYPE1: imm_ext = {TYPE1, {12{1'b0}}};

        // J-type
        `IMM_TYPE2: 
            if (imm_sel[3]) 
                imm_ext = {{11{1'b0}}, TYPE1, 1'b0}; 
            else 
                imm_ext = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};

        // I-type (load and arithmetic)
        `IMM_TYPE3:
            if (imm_sel[3]) 
                imm_ext = {{20{1'b0}}, TYPE3}; 
            else 
                imm_ext = {{20{TYPE3[11]}}, TYPE3};

        // B-type (branch)
        `IMM_TYPE4:
            imm_ext = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};

        // S-type (store)
        `IMM_TYPE5:
            if (imm_sel[3]) 
                imm_ext = {{20{1'b0}}, TYPE5}; 
            else 
                imm_ext = {{20{inst[31]}}, TYPE5}; 

        // Shift immediate (Shamt)
        `IMM_TYPE6: imm_ext = {{27{1'b0}}, TYPE6};

        // Default case to prevent latches
        default: imm_ext = 32'b0;
    endcase
end
endmodule