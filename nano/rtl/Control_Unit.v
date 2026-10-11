`timescale 1ns / 1ps

module Control_Unit(
    input clk,
    input reset,
    input [31:0] instruction,
    
    // Outputs based on your Control Word image
    output reg reg_write,   // Write result to register file?
    output reg mem_write,   // Write data to RAM?
    output reg mem_read,    // Read data from RAM?
    output reg branch,      // Is this a branch instruction?
    output reg jump,        // Is this a jump instruction?
    output reg mem_to_reg,  // 1: Data from RAM -> Reg, 0: ALU -> Reg
    output reg alu_src,     // 1: Use Immediate, 0: Use Register
    output reg reg_read,    // Enable reading from register file
    output reg jump_back,   // Specific return logic (JALR)
    output reg [3:0] mem_be, // NEW: 1111 = Word, 0011 = Halfword, 0001 = Byte
    output reg is_store,     // this is for data hazard and fowarding
    output reg is_auipc,     // this is for data hazard and fowarding
    output reg is_lui    // this is for data hazard and fowarding
);

    wire [6:0] opcode; 
    wire [2:0] func3;
    
    assign opcode = instruction[6:0];
    assign func3  = instruction[14:12];

    // This core implements the integer computational/load/store/control-flow
    // RV32I instructions only. MUL is disabled for this performance build.
    // Unsupported encodings are inert bubbles;
    // there is no privileged trap/CSR interface in this small core.
    reg supported;
    always @(*) begin
        case (opcode)
            7'h33: supported = (instruction[31:25] == 7'h00) ||
                              ((instruction[31:25] == 7'h20) && ((func3 == 0) || (func3 == 5)));
            7'h13: supported = (func3 == 1) ? (instruction[31:25] == 0) :
                              (func3 == 5) ? ((instruction[31:25] == 0) || (instruction[31:25] == 7'h20)) : 1'b1;
            7'h03: supported = (func3 == 0) || (func3 == 1) || (func3 == 2) || (func3 == 4) || (func3 == 5);
            7'h23: supported = (func3 == 0) || (func3 == 1) || (func3 == 2);
            7'h63: supported = (func3 == 0) || (func3 == 1) || (func3 >= 4);
            7'h67: supported = (func3 == 0);
            7'h37, 7'h17, 7'h6f: supported = 1'b1;
            default: supported = 1'b0;
        endcase
    end

    always @(*) begin
        // --- DEFAULT VALUES (Reset all to 0) ---
        reg_write  = 0; mem_write  = 0; mem_read   = 0;
        branch     = 0; jump       = 0; mem_to_reg = 0;
        alu_src    = 0; is_store   = 0; is_auipc = 0;
        reg_read   = 0; jump_back  = 0; is_lui = 0;
        mem_be     = 4'b0000; // Default: No memory lanes active

        if (supported) case(opcode)
            // --- I-Type (e.g., ADDI, ANDI, SLTI) ---
            7'b0010011: begin
                reg_write  = 1; 
                reg_read   = 1; 
                alu_src    = 1; 
            end

            // --- R-Type (e.g., ADD, SUB, AND, OR) ---
            7'b0110011: begin
                reg_write  = 1; 
                reg_read   = 1; 
                alu_src    = 0; 
            end

            // --- S-Type (e.g., SW, SH, SB) ---
            7'b0100011: begin
                mem_write  = 1; 
                reg_read   = 1; 
                alu_src    = 1; 
                is_store   = 1;
                // Determine write size width
                case(func3[1:0])
                    2'b00:   mem_be = 4'b0001; // SB (Byte)
                    2'b01:   mem_be = 4'b0011; // SH (Halfword)
                    2'b10:   mem_be = 4'b1111; // SW (Word)
                    default: mem_be = 4'b1111;
                endcase
            end

            // --- L-Type (e.g., LW, LH, LB, LBU, LHU) ---
            7'b0000011: begin
                reg_write  = 1; 
                mem_read   = 1; 
                alu_src    = 1; 
                mem_to_reg = 1; 
                reg_read   = 1; 
                
                // Determine read size width
                case(func3)
                    3'b000, 3'b100: mem_be = 4'b0001; // LB, LBU
                    3'b001, 3'b101: mem_be = 4'b0011; // LH, LHU
                    3'b010:        mem_be = 4'b1111; // LW
                    default: mem_be = 4'b1111;
                endcase
            end

            // --- B-Type (e.g., BEQ, BNE, BLT) ---
            7'b1100011: begin 
                branch     = 1; 
                reg_read   = 1; 
                alu_src    = 0; 
            end

            // --- J-Type (JAL) ---
            7'b1101111: begin
                jump       = 1;
                reg_write  = 1;
                alu_src    = 1; 
            end

            // --- I-Type Jump (JALR) ---
            7'b1100111: begin
                jump_back  = 1; 
                reg_write  = 1; 
                reg_read   = 1; 
                alu_src    = 1; 
            end

            // --- U-Type (LUI) ---
            7'b0110111: begin
                reg_write  = 1;
                alu_src    = 1;
                is_lui   = 1;
            end
            
            // --- U-Type (AUIPC) ---
            7'b0010111: begin
                reg_write  = 1;
                alu_src    = 1;
                is_auipc   = 1;
            end

            default: ; 
        endcase
    end
endmodule
