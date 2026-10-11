`timescale 1ns / 1ps

module EX_MEM_Stage_Reg(
    input clk,
    input reset,
    input stall,
    // Inputs from Execute (EX) Stage
    input [31:0] insr_in,
    input [31:0] rs2_in,    
    input [3:0] be_in,
    input [2:0]  func3_in, // for mem
    input [4:0]  rd_addr_in,
    input [4:0]  rs1_addr_in,
    input [4:0]  rs2_addr_in,
    input        mem_to_reg_in,
    input        reg_write_in,
    input        mem_write_in,
    input        mem_read_in,
    input [31:0] ALU_result_in,
    
    // Outputs to Memory (MEM) Stage
    output reg [31:0] insr_out,
    output reg [31:0] rs2_out, 
    output reg [3:0] be_out,
    output reg [2:0]  func3_out,
    output reg        mem_to_reg_out,
    output reg [4:0]  rd_addr_out,
    output reg [4:0]  rs1_addr_out,
    output reg [4:0]  rs2_addr_out,
    output reg        reg_write_out, // Added matching output
    output reg        mem_write_out, // Added matching output
    output reg        mem_read_out,  // Added matching output
    output reg [31:0] ALU_result_out
    );
    
    always @(posedge clk) begin
        if (reset | stall) begin
            // Reset all signals to zero
            insr_out       <= 32'b0;
            rs2_out         <= 32'b0;
            be_out         <= 4'b0;
            func3_out      <= 3'b0;
            rd_addr_out    <= 5'd0;
            rs1_addr_out    <= 5'd0;
            rs2_addr_out    <= 5'd0;
            reg_write_out  <= 1'b0;
            mem_write_out  <= 1'b0;
            mem_read_out   <= 1'b0;
            ALU_result_out <= 32'h0;
            mem_to_reg_out <= 1'b0;
        end else begin
            // Pass all signals to the next stage
            insr_out       <= insr_in;
            rs2_out         <= rs2_in;
            be_out         <= be_in;
            func3_out      <= func3_in;
            rd_addr_out    <= rd_addr_in;
            rs1_addr_out    <= rs1_addr_in;
            rs2_addr_out    <= rs2_addr_in;
            reg_write_out  <= reg_write_in;
            mem_write_out  <= mem_write_in;
            mem_read_out   <= mem_read_in;
            ALU_result_out <= ALU_result_in;
            mem_to_reg_out <=  mem_to_reg_in;
        end
    end  
    
endmodule
