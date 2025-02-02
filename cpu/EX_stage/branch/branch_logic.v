`ifdef TB_RUN
    `include "../../utils/encordings.v"
`else
    `include "./utils/encordings.v"
`endif

`timescale 1ns/100ps

module branch_logic (
    input wire [31:0] data1,
    input wire [31:0] data2,
    input wire [3:0] op,  // Updated to 4-bit op
    output reg out
);

    // Define comparison wires
    wire BEQ, BNE, BLT, BGE, BLTU, BGEU;

    assign BEQ  = (data1 == data2);
    assign BNE  = (data1 != data2);
    assign BLT  = ($signed(data1) < $signed(data2));
    assign BGE  = ($signed(data1) >= $signed(data2));
    assign BLTU = ($unsigned(data1) < $unsigned(data2));
    assign BGEU = ($unsigned(data1) >= $unsigned(data2));

    always @(*) begin
        #2 // Delay for branch decision
        
        if (op[3]) begin
            case (op[2:0])
                3'b010: out = 1'b1;  // JAL/JALR (Unconditional branch)
                3'b000: out = BEQ;
                3'b001: out = BNE;
                3'b100: out = BLT;
                3'b101: out = BGE;
                3'b110: out = BLTU;
                3'b111: out = BGEU;
                default: out = 1'b0;
            endcase
        end else begin
            out = 1'b0;  // No branch when op[3] is low
        end
    end

    // Debugging output
    // always @(*) begin
    //     $display("Branch Logic | data1: %d, data2: %d, op: %b, out: %b", data1, data2, op, out);
    // end

endmodule
