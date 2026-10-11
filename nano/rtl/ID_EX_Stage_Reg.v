`timescale 1ns / 1ps

module ID_EX_Stage_Reg (
    input clk,
    input reset,
    input stall,

    // --- Data Inputs (from Decode) ---
    input [31:0] PC_in,
    input [31:0] insr_in,   
    input [3:0] be_in, // NEW: 1111 = Word, 0011 = Halfword, 0001 = Byte
    input [31:0] rs1_in,
    input [31:0] rs2_in,
    input [31:0] imm_in,
    input [4:0]  rd_addr_in,
    input [4:0] rs1_addr_in,
    input [4:0] rs2_addr_in,

    // --- Control Inputs (from Control Unit) ---
    input [2:0]  func3_in, // used for MEM
    input        reg_write_in,
    input        mem_write_in,
    input        mem_read_in,
    input        branch_in,
    input        jump_in,
    input        r_jump_in,
    input        mem_to_reg_in,
    input        alu_src_in,
    input        arith_sel_in,
    input [3:0]  alu_op_in,
    input        reg_read_in,
    input        jump_back_in,
    input        is_auipc_in,
    input        is_lui_in,

    // --- Data Outputs (to Execute) ---
    output reg [31:0] PC_out,
    output reg [31:0] insr_out,   
    output reg [3:0] be_out, // NEW: 1111 = Word, 0011 = Halfword, 0001 = Byte
    output reg [31:0] rs1_out,
    output reg [31:0] rs2_out,
    output reg [31:0] imm_out,
    output reg [4:0]  rd_addr_out,
    output reg [4:0] rs1_addr_out,
    output reg [4:0] rs2_addr_out,

    // --- Control Outputs (to Execute) ---
    output reg [2:0]  func3_out, // used for MEM
    output reg        reg_write_out,
    output reg        mem_write_out,
    output reg        mem_read_out,
    output reg        branch_out,
    output reg        jump_out,
    output reg        r_jump_out,
    output reg        mem_to_reg_out,
    output reg        alu_src_out,
    output reg        arith_sel_out,
    output reg [3:0]  alu_op_out,
    output reg        reg_read_out,
    output reg        jump_back_out,
    output reg        is_auipc_out,
    output reg        is_lui_out
    
);

// --- Internal Pipeline Registers ---;
    always @(posedge clk) begin
        // Payload always advances; main_cpu.ex_valid suppresses all effects
        // during reset, load-use bubbles, and redirects.
            is_lui_out   <= is_lui_in;
            is_auipc_out   <= is_auipc_in;
            r_jump_out       <= r_jump_in;
            PC_out         <= PC_in;
            insr_out       <= insr_in;
            be_out         <= be_in;
            func3_out      <= func3_in;
            rs1_out        <= rs1_in;
            rs2_out        <= rs2_in;
            imm_out        <= imm_in;
            rd_addr_out    <= rd_addr_in;
            reg_write_out  <= reg_write_in;
            mem_write_out  <= mem_write_in;
            mem_read_out   <= mem_read_in;
            branch_out     <= branch_in;
            jump_out       <= jump_in;
            mem_to_reg_out <= mem_to_reg_in;
            alu_src_out    <= alu_src_in;
            alu_op_out     <= alu_op_in;
            reg_read_out   <= reg_read_in;
            jump_back_out  <= jump_back_in;
            rs1_addr_out   <= rs1_addr_in;
            rs2_addr_out   <= rs2_addr_in;
            arith_sel_out  <= arith_sel_in;
    end

endmodule
