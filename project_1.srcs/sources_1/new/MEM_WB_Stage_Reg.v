`timescale 1ns / 1ps

module MEM_WB_Stage_Reg(
    input clk,
    input reset,
    
    // Inputs from Memory (MEM) Stage
    input [31:0] insr_in,
    input [2:0] func3_in, // for writig data to reg w h b
    input [4:0]  rd_addr_in,
    input        reg_write_in,
    input        mem_to_reg_in,   // Essential for choosing the WB data
    input [31:0] LD_result_in,    // Data loaded from RAM
    input [31:0] ALU_result_in,   // Data calculated by ALU
    
    // Outputs to Write-Back (WB) Stage
    output reg [31:0] insr_out,
    output reg [2:0] func3_out,
    output reg [4:0]  rd_addr_out,
    output reg        reg_write_out,
    output reg        mem_to_reg_out,
    output reg [31:0] LD_result_out,
    output reg [31:0] ALU_result_out
    );
    
    always @(posedge clk) begin
        if (reset) begin
            insr_out       <= 32'b0;
            func3_out         <= 3'b0;
            rd_addr_out    <= 5'd0;
            reg_write_out  <= 1'b0;
            mem_to_reg_out <= 1'b0;
            LD_result_out  <= 32'h0;
            ALU_result_out <= 32'h0;
        end else begin
            insr_out       <= insr_in;
            func3_out         <= func3_in;
            rd_addr_out    <= rd_addr_in;
            reg_write_out  <= reg_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            LD_result_out  <= LD_result_in;
            ALU_result_out <= ALU_result_in;
        end
    end
    
endmodule