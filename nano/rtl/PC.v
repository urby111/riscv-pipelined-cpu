`timescale 1ns / 1ps

module PC#(
    parameter ADDR_WIDTH = 10,
    parameter DATA_WIDTH = 32
)(
    input clk,
    input stall,
    input is_r_jump,
    input reset,
    input is_jump,
    input is_branch,
    input [ADDR_WIDTH-1:0] jump_insr,
    input [31:0] alu_insr,
    input [31:0] branch_insr,
    input [ADDR_WIDTH-1:0] d_in,    // This is the 'next address' coming FROM the main unit
    output [ADDR_WIDTH-1:0] pc_out
);
    
    reg [31:0] count_reg;

    always @(posedge clk) begin
        if (reset) begin
            count_reg <= 32'd0;       // Reset to the first instruction
        end else if (is_branch) begin
            count_reg <= branch_insr;
        end else if (is_r_jump) begin
            count_reg <= alu_insr & 32'hfffffffe; // JALR always clears target bit 0.
        end else if (is_jump) begin
            count_reg <= jump_insr;
        end else if (stall) begin
            count_reg <= count_reg;   // CORRECTED: Hold internal reg value (freeze)
        end else begin
            count_reg <= d_in;        // Simply capture the address calculated in 'main'
        end                           // CORRECTED: Added missing end keyword
    end

    // Continuous assignment to drive the output wire
    assign pc_out = count_reg;
    
endmodule
