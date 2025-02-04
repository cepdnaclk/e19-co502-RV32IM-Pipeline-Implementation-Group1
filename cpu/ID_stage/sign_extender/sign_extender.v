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

wire [19:0] TYPE1, TYPE2;
wire [11:0] TYPE3, TYPE4, TYPE5;
wire [4:0] TYPE6;

// TODO: Check the combinations
assign TYPE1 = inst[31:12];
assign TYPE2 = inst[31:12];
assign TYPE3 = inst[31:20]; 
assign TYPE5 = {inst[31:25], inst[11:7]};
assign TYPE6 = inst[29:25]; 

always @(*) begin
    #2
    case (imm_sel[2:0])
        // TYPE 1 
        `IMM_TYPE1:
                imm_ext = {TYPE1, {12{1'b0}}};
        // TYPE 2 
        `IMM_TYPE2:
            if (imm_sel[3] == 1'b1) 
                imm_ext = {{11{1'b0}}, TYPE2, 1'b0};
            else
                imm_ext = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0}; //{{11{TYPE2[19]}}, TYPE2, 1'b0};
        // TYPE 3 
        `IMM_TYPE3:
            if (imm_sel[3] == 1'b1) 
                imm_ext = {{20{1'b0}}, TYPE3};
            else
                imm_ext = {{20{TYPE3[11]}}, TYPE3};
        // TYPE 4 
        `IMM_TYPE4:
            if (imm_sel[3] == 1'b1) 
                imm_ext = {{20{1'b0}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
            else
                imm_ext = {{20{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
        // TYPE 5 
        `IMM_TYPE5:
            if (imm_sel[3] == 1'b1) 
                imm_ext = {{20{1'b0}}, TYPE5};
            else
                imm_ext = {{20{TYPE5[11]}}, TYPE5};
        // TYPE 6 
        `IMM_TYPE6:
            imm_ext = {{27{1'b0}}, TYPE6};
    endcase
end

endmodule