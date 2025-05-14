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

    // Internal operation results
    reg [31:0] operation_result;
    
    // Only execute the selected operation
    always @(*) begin
        // Default output
        operation_result = 32'd0;
        
        case (SELECT)
            // Arithmetic operations
            `ADD:    operation_result = #2 DATA1 + DATA2;
            `SUB:    operation_result = #2 DATA1 - DATA2;
            
            // Shift operations
            `SLL:    operation_result = #1 DATA1 << DATA2[4:0];
            `SRL:    operation_result = #1 DATA1 >> DATA2[4:0];
            `SRA:    operation_result = #1 DATA1 >>> DATA2[4:0];
            
            // Comparison operations
            `SLT:    operation_result = #1 (DATA1 < $signed(DATA2)) ? 32'd1 : 32'd0;
            `SLTU:   operation_result = #1 ($unsigned(DATA1) < $unsigned(DATA2)) ? 32'd1 : 32'd0;
            
            // Logical operations
            `XOR:    operation_result = #1 DATA1 ^ DATA2;
            `OR:     operation_result = #1 DATA1 | DATA2;
            `AND:    operation_result = #1 DATA1 & DATA2;
            
            // Multiplication operations
            `MUL:    operation_result = #3 DATA1 * DATA2;
            `MULH:   operation_result = #3 ($signed({{32{DATA1[31]}}, DATA1}) * $signed({{32{DATA2[31]}}, DATA2})) >> 32;
            `MULHSU: operation_result = #3 ($signed({{32{DATA1[31]}}, DATA1}) * $unsigned({32'b0, DATA2})) >> 32;
            `MULHU:  operation_result = #3 ($unsigned({32'b0, DATA1}) * $unsigned({32'b0, DATA2})) >> 32;
            
            // Division and remainder operations
            `DIV:    operation_result = #3 (DATA2 == 0) ? 32'd0 : $signed(DATA1) / $signed(DATA2);
            `DIVU:   operation_result = #3 (DATA2 == 0) ? 32'd0 : $unsigned(DATA1) / $unsigned(DATA2);
            `REM:    operation_result = #3 (DATA2 == 0) ? 32'd0 : $signed(DATA1) % $signed(DATA2);
            `REMU:   operation_result = #3 (DATA2 == 0) ? 32'd0 : $unsigned(DATA1) % $unsigned(DATA2);
            
            // Forward operation (special case)
            default: begin
                if (SELECT[4:3] == 2'b11)
                    operation_result = #1 DATA2;
                else
                    operation_result = 32'd0;
            end
        endcase
        
        // Assign to output
        RESULT = operation_result;
    end

endmodule