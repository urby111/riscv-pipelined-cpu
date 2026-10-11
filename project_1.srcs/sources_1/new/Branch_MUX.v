`timescale 1ns / 1ps

module Branch_MUX(
    input        branch_en,   // High if the current instruction is a BRANCH opcode
    input [2:0]  func3,       // From instruction[14:12] to specify branch type
    input [31:0] rs1,         // Forwarded register operands, independent of ALU result.
    input [31:0] rs2,
    
    output reg        take_branch // High if the branch condition is met
    );

    // --- Branch Condition Evaluation ---
    always @(*) begin
        if (branch_en) begin
            case (func3)
                3'b000:  take_branch = (rs1 == rs2);                  // BEQ
                3'b001:  take_branch = (rs1 != rs2);                  // BNE
                3'b100:  take_branch = ($signed(rs1) < $signed(rs2)); // BLT
                3'b101:  take_branch = ($signed(rs1) >= $signed(rs2));// BGE
                3'b110:  take_branch = (rs1 < rs2);                   // BLTU
                3'b111:  take_branch = (rs1 >= rs2);                  // BGEU
                default: take_branch = 1'b0;
            endcase
        end else begin
            take_branch = 1'b0; // Not a branch instruction, don't take it
        end
    end


endmodule
