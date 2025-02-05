`ifdef TB_RUN
    `include "../../utils/encordings.v"
`else
    `include "./utils/encordings.v"
`endif

`timescale 1ns/100ps

module alu(DATA1, DATA2, SELECT, RESULT);

    // Initialize input ports
    input [31:0] DATA1, DATA2;
    input [4:0] SELECT;
    // Initialize output ports
    output reg [31:0] RESULT;

    // Define the wires
    wire [31:0] addData, subData, sllData, sltData, sltuData, xorData, srlData, sraData, orData, andData, mulData, mulhData, mulhuData, mulhsuData, divData, divuData, remData, remuData;

    // Assign operations
    // assign #1 forwardData = DATA1;
    assign #2 addData = DATA1 + DATA2;
    assign #2 subData = DATA1 - DATA2;

    assign #1 sltData = ($signed(DATA1) < $signed(DATA2)) ? 32'd1 : 32'd0;
    assign #1 sltuData = ($unsigned(DATA1) < $unsigned(DATA2)) ? 32'd1 : 32'd0;

    assign #1 sllData = DATA1 << DATA2[4:0];  // Limit shift amount to 5 bits
    assign #1 srlData = DATA1 >> DATA2[4:0];  // Limit shift amount to 5 bits
    assign #1 sraData = $signed(DATA1) >>> DATA2[4:0];  // Correct SRA

    assign #1 xorData = DATA1 ^ DATA2;
    assign #1 orData = DATA1 | DATA2;
    assign #1 andData = DATA1 & DATA2;

    assign #3 mulData = $signed(DATA1) * $signed(DATA2);
    assign #3 mulhData = ($signed(DATA1) * $signed(DATA2)) >> 32;
    assign #3 mulhsuData = ($signed(DATA1) * $unsigned(DATA2)) >> 32;
    assign #3 mulhuData = ($unsigned(DATA1) * $unsigned(DATA2)) >> 32;

    assign #3 divData = (DATA2 == 0) ? 32'b0 : DATA1 / DATA2;
    assign #3 divuData = (DATA2 == 0) ? 32'b0 : $unsigned(DATA1) / $unsigned(DATA2);
    assign #3 remData = (DATA2 == 0) ? 32'b0 : DATA1 % DATA2;
    assign #3 remuData = (DATA2 == 0) ? 32'b0 : $unsigned(DATA1) % $unsigned(DATA2);

    // Select operation based on SELECT signal
    always @(*) 
    begin
        case (SELECT)
            `ADD: RESULT = addData;
            `SUB: RESULT = subData;
            `SLL: RESULT = sllData;
            `SLT: RESULT = sltData;
            `SLTU: RESULT = sltuData;
            `XOR: RESULT = xorData;
            `SRL: RESULT = srlData;
            `SRA: RESULT = sraData;
            `OR: RESULT = orData;
            `AND: RESULT = andData;
            `MUL: RESULT = mulData;
            `MULH: RESULT = mulhData;
            `MULHSU: RESULT = mulhsuData;
            `MULHU: RESULT = mulhuData;
            `DIV: RESULT = divData;
            `DIVU: RESULT = divuData;
            `REM: RESULT = remData;
            `REMU: RESULT = remuData;
            // `FORWARD: RESULT = forwardData;
            default: RESULT = 32'b0;  // Prevents undefined behavior
        endcase
    end

endmodule
