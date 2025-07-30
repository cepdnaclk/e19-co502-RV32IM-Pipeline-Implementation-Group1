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

    // Intermediate registers for power optimization
    reg [31:0] addData, subData;
    reg [31:0] sllData, srlData, sraData;
    reg [31:0] sltData, sltuData;
    reg [31:0] xorData, orData, andData;
    reg [31:0] mulData, mulhData, mulhsuData, mulhuData;
    reg [31:0] divData, divuData, remData, remuData;
    
    // Operation activation signals to reduce switching activity
    wire do_add_sub = (SELECT == `ADD) || (SELECT == `SUB);
    wire do_shifts = (SELECT == `SLL) || (SELECT == `SRL) || (SELECT == `SRA);
    wire do_logic = (SELECT == `XOR) || (SELECT == `OR) || (SELECT == `AND);
    wire do_compare = (SELECT == `SLT) || (SELECT == `SLTU);
    wire do_mul = (SELECT == `MUL) || (SELECT == `MULH) || (SELECT == `MULHSU) || (SELECT == `MULHU);
    wire do_div = (SELECT == `DIV) || (SELECT == `DIVU) || (SELECT == `REM) || (SELECT == `REMU);
    
    // Operand isolation for multiplication and division
    wire [31:0] mul_op1 = do_mul ? DATA1 : 32'b0;
    wire [31:0] mul_op2 = do_mul ? DATA2 : 32'b0;
    wire [31:0] div_op1 = do_div ? DATA1 : 32'b0;
    wire [31:0] div_op2 = do_div ? DATA2 : 32'b0;
    
    // Power-optimized calculation signals - only computed when needed
    
    // For MUL operations - optimized to reduce toggling
    wire signed [63:0] mul_prod_ss = do_mul ? $signed(mul_op1) * $signed(mul_op2) : 64'b0;
    wire signed [63:0] mulh_prod = do_mul && (SELECT == `MULH) ? 
                     $signed({{32{mul_op1[31]}}, mul_op1}) * $signed({{32{mul_op2[31]}}, mul_op2}) : 64'b0;
    wire signed [63:0] mulhsu_prod = do_mul && (SELECT == `MULHSU) ? 
                     $signed({{32{mul_op1[31]}}, mul_op1}) * $unsigned({32'b0, mul_op2}) : 64'b0;
    wire unsigned [63:0] mulhu_prod = do_mul && (SELECT == `MULHU) ? 
                     $unsigned({32'b0, mul_op1}) * $unsigned({32'b0, mul_op2}) : 64'b0;
    
    // For DIV operations - optimized with operand isolation
    wire [31:0] safe_div_op2 = (div_op2 == 0) ? 32'd1 : div_op2; // Prevent div by zero
    
    // Division operations gated to reduce power
    wire signed [31:0] div_quotient = do_div && (SELECT == `DIV) ? 
                     $signed(div_op1) / $signed(safe_div_op2) : 32'b0;
    wire signed [31:0] div_remainder = do_div && (SELECT == `REM) ? 
                     $signed(div_op1) % $signed(safe_div_op2) : 32'b0;
    wire [31:0] divu_quotient = do_div && (SELECT == `DIVU) ? 
                     $unsigned(div_op1) / $unsigned(safe_div_op2) : 32'b0;
    wire [31:0] divu_remainder = do_div && (SELECT == `REMU) ? 
                     $unsigned(div_op1) % $unsigned(safe_div_op2) : 32'b0;

    // === Combinational logic with activity-based computation ===
    always @(*) begin
        // Default values to minimize switching
        addData = 32'b0;
        subData = 32'b0;
        sllData = 32'b0;
        srlData = 32'b0;
        sraData = 32'b0;
        sltData = 32'b0;
        sltuData = 32'b0;
        xorData = 32'b0;
        orData = 32'b0;
        andData = 32'b0;
        mulData = 32'b0;
        mulhData = 32'b0;
        mulhsuData = 32'b0;
        mulhuData = 32'b0;
        divData = 32'b0;
        divuData = 32'b0;
        remData = 32'b0;
        remuData = 32'b0;
        
        // Only perform calculations that are needed
        if (do_add_sub) begin
            if (SELECT == `ADD)
                addData = DATA1 + DATA2;
            else // SUB
                subData = DATA1 - DATA2;
        end
        
        if (do_shifts) begin
            case (SELECT)
                `SLL: sllData = DATA1 << DATA2[4:0];
                `SRL: srlData = DATA1 >> DATA2[4:0];
                `SRA: sraData = DATA1 >>> DATA2[4:0];
            endcase
        end
        
        if (do_compare) begin
            if (SELECT == `SLT)
                sltData = (DATA1 < $signed(DATA2)) ? 32'd1 : 32'd0;
            else // SLTU
                sltuData = ($unsigned(DATA1) < $unsigned(DATA2)) ? 32'd1 : 32'd0;
        end
        
        if (do_logic) begin
            case (SELECT)
                `XOR: xorData = DATA1 ^ DATA2;
                `OR:  orData  = DATA1 | DATA2;
                `AND: andData = DATA1 & DATA2;
            endcase
        end
        
        // Use multiplication results
        if (do_mul) begin
            case (SELECT)
                `MUL:    mulData = mul_prod_ss[31:0];
                `MULH:   mulhData = mulh_prod[63:32];
                `MULHSU: mulhsuData = mulhsu_prod[63:32];
                `MULHU:  mulhuData = mulhu_prod[63:32];
            endcase
        end
        
        // Use division results with proper handling of divide-by-zero
        if (do_div) begin
            case (SELECT)
                `DIV: begin
                    if (DATA2 == 0)
                        divData = 32'hFFFFFFFF; // DIV by 0 returns -1
                    else if (DATA1 == 32'h80000000 && DATA2 == 32'hFFFFFFFF)
                        divData = 32'h80000000; // Overflow case
                    else
                        divData = div_quotient;
                end
                
                `DIVU: begin
                    if (DATA2 == 0)
                        divuData = 32'hFFFFFFFF; // DIVU by 0 returns max unsigned
                    else
                        divuData = divu_quotient;
                end
                
                `REM: begin
                    if (DATA2 == 0)
                        remData = DATA1; // REM by 0 returns dividend
                    else if (DATA1 == 32'h80000000 && DATA2 == 32'hFFFFFFFF)
                        remData = 32'h0; // Special case
                    else
                        remData = div_remainder;
                end
                
                `REMU: begin
                    if (DATA2 == 0)
                        remuData = DATA1; // REMU by 0 returns dividend
                    else
                        remuData = divu_remainder;
                end
            endcase
        end
    end

    // Output multiplexer with minimized switching
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
            default: RESULT = (SELECT[4:3] == 2'b11) ? DATA2 : 32'd0;
        endcase
    end

endmodule