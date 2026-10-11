`timescale 1ns / 1ps

module ALU_Decoder(
        input      [6:0] opcode,
        input      [2:0] func3,
        input      [6:0] func7,
        
        output reg [3:0] out  // Must be 'reg' to be assigned in an always block
    );

    // --- ALU Control Codes (Matching Pure_ALU) ---
    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b0001;
    localparam ALU_SLL  = 4'b0010;
    localparam ALU_SLT  = 4'b0011;
    localparam ALU_SLTU = 4'b0100;
    localparam ALU_XOR  = 4'b0101;
    localparam ALU_SRL  = 4'b0110;
    localparam ALU_SRA  = 4'b0111;
    localparam ALU_OR   = 4'b1000;
    localparam ALU_AND  = 4'b1001;

    // --- RV32I Opcodes ---
    localparam R_TYPE = 7'b0110011;
    localparam I_TYPE = 7'b0010011;
    localparam LOAD   = 7'b0000011;
    localparam STORE  = 7'b0100011;
    localparam BRANCH = 7'b1100011;
    localparam LUI    = 7'b0110111;
    localparam AUIPC  = 7'b0010111;
    localparam JAL    = 7'b1101111;
    localparam JALR   = 7'b1100111;

    // Bit 5 of func7 is the modifier bit for SUB and SRA
    wire f7_b5 = func7[5];

    always @(*) begin
        case(opcode)
            // Memory operations and Address Calculations just need an ADD
            LOAD, STORE, LUI, AUIPC, JAL, JALR: begin
                out = ALU_ADD; 
            end
            
            // Branches map to SUB or Comparison operations based on func3
            BRANCH: begin
                case(func3)
                    3'b000:  out = ALU_SUB;  // BEQ  -> Subtracts, checks if result == 0
                    3'b001:  out = ALU_SUB;  // BNE  -> Subtracts, checks if result != 0
                    3'b100:  out = ALU_SLT;  // BLT  -> Signed Comp, checks if result == 1
                    3'b101:  out = ALU_SLT;  // BGE  -> Signed Comp, checks if result == 0
                    3'b110:  out = ALU_SLTU; // BLTU -> Unsigned Comp, checks if result == 1
                    3'b111:  out = ALU_SLTU; // BGEU -> Unsigned Comp, checks if result == 0
                    default: out = ALU_SUB;
                endcase
            end

            // Register-Register Operations
            R_TYPE: begin
                case(func3)
                    3'b000: out = f7_b5 ? ALU_SUB : ALU_ADD; // Unsupported MUL is blocked by Control_Unit.
                    3'b001: out = ALU_SLL;
                    3'b010: out = ALU_SLT;
                    3'b011: out = ALU_SLTU;
                    3'b100: out = ALU_XOR;
                    3'b101: out = f7_b5 ? ALU_SRA : ALU_SRL; // SRL vs SRA
                    3'b110: out = ALU_OR;
                    3'b111: out = ALU_AND;
                    default: out = ALU_ADD;
                endcase
            end

            // Register-Immediate Operations
            I_TYPE: begin
                case(func3)
                    3'b000: out = ALU_ADD;                   // ADDI (never subtracts)
                    3'b001: out = ALU_SLL;
                    3'b010: out = ALU_SLT;
                    3'b011: out = ALU_SLTU;
                    3'b100: out = ALU_XOR;
                    3'b101: out = f7_b5 ? ALU_SRA : ALU_SRL; // SRLI vs SRAI
                    3'b110: out = ALU_OR;
                    3'b111: out = ALU_AND;
                    default: out = ALU_ADD;
                endcase
            end

            default: out = ALU_ADD;
        endcase
    end
endmodule
