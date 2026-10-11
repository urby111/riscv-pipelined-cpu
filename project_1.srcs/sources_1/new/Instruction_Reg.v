`timescale 1ns / 1ps

// stores instrution to be decoded
module Instruction_Reg#(
    parameter ADDR_WIDTH = 10,
    parameter DATA_WIDTH = 32
)(
    input clk,
    input reset,
    input stall,
    input [DATA_WIDTH-1:0] din,      // Next PC (from PC+4 or Branch)
    output reg [DATA_WIDTH-1:0] pcout // Current PC (to RAM)
);

    always @(posedge clk) begin
        if (reset) begin
            pcout <= 32'h0; // Start at address 0 when reset
        end else if (!stall) begin
            pcout <= din;   // Latch the next address
        end
    end
endmodule
