`ifdef TB_RUN
    `include "../../utils/encordings.v"
`else
    `include "./utils/encordings.v"
`endif

`timescale 1ns/100ps

module alu (
    input  signed [31:0] DATA1,    // Signed input (for signed ops)
    input         [31:0] DATA2,    // Unsigned input (cast where needed)
    input         [4:0]  SELECT,   // Operation selector
    output reg    [31:0] RESULT    // Output result
);

    // Intermediate wires for each operation
    wire [31:0] forwardData;
    wire [31:0] addData, subData;
    wire [31:0] sllData, srlData, sraData;
    wire [31:0] sltData, sltuData;
    wire [31:0] xorData, orData, andData;
    wire [31:0] mulData, mulhData, mulhsuData, mulhuData;
    wire [31:0] divData, divuData, remData, remuData;

    // === Combinational logic ===
    assign #1 forwardData = DATA2;
    assign #2 addData = DATA1 + DATA2;
    assign #2 subData = DATA1 - DATA2;

    assign #1 sltData = (DATA1 < $signed(DATA2)) ? 32'd1 : 32'd0;
    assign #1 sltuData = ($unsigned(DATA1) < $unsigned(DATA2)) ? 32'd1 : 32'd0;

    assign #1 sllData = DATA1 << DATA2[4:0];                    // Logical left
    assign #1 srlData = DATA1 >> DATA2[4:0];                    // Logical right
    assign #1 sraData = DATA1 >>> DATA2[4:0];                   // Arithmetic right

    assign #1 xorData = DATA1 ^ DATA2;
    assign #1 orData  = DATA1 | DATA2;
    assign #1 andData = DATA1 & DATA2;

    // Multiplication with proper 64-bit casts
    assign #3 mulData   = DATA1 * DATA2;
    assign #3 mulhData  = ($signed({{32{DATA1[31]}}, DATA1}) * $signed({{32{DATA2[31]}}, DATA2})) >> 32;
    assign #3 mulhsuData = ($signed({{32{DATA1[31]}}, DATA1}) * $unsigned({32'b0, DATA2})) >> 32;
    assign #3 mulhuData = ($unsigned({32'b0, DATA1}) * $unsigned({32'b0, DATA2})) >> 32;

    // Division and remainder with divide-by-zero protection
    assign #3 divData  = (DATA2 == 0) ? 32'd0 : DATA1 / DATA2;
    assign #3 divuData = (DATA2 == 0) ? 32'd0 : $unsigned(DATA1) / $unsigned(DATA2);
    assign #3 remData  = (DATA2 == 0) ? 32'd0 : DATA1 % DATA2;
    assign #3 remuData = (DATA2 == 0) ? 32'd0 : $unsigned(DATA1) % $unsigned(DATA2);

    // === Output selection based on operation code ===
    always @(*) begin
        case (SELECT)
            `ADD:    RESULT = addData;
            `SUB:    RESULT = subData;
            `SLL:    RESULT = sllData;
            `SLT:    RESULT = sltData;
            `SLTU:   RESULT = sltuData;
            `XOR:    RESULT = xorData;
            `SRL:    RESULT = srlData;
            `SRA:    RESULT = sraData;
            `OR:     RESULT = orData;
            `AND:    RESULT = andData;

            `MUL:    RESULT = mulData;
            `MULH:   RESULT = mulhData;
            `MULHSU: RESULT = mulhsuData;
            `MULHU:  RESULT = mulhuData;
            `DIV:    RESULT = divData;
            `DIVU:   RESULT = divuData;
            `REM:    RESULT = remData;
            `REMU:   RESULT = remuData;

            default: begin
                if (SELECT[4:3] == 2'b11)
                    RESULT = forwardData;
                else
                    RESULT = 32'd0;
            end
        endcase
    end

endmodule
