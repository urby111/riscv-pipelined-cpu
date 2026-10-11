`timescale 1ns / 1ps


module Hazard_Buffer#(
    parameter ADDR_WIDTH = 10,
    parameter DATA_WIDTH = 32
)(
    input clk,
    input stall,
    input reset,
    input [ADDR_WIDTH-1:0] d_in,    // This is the 'next address' coming FROM the main unit
    output [ADDR_WIDTH-1:0] pc_out
);

reg [ADDR_WIDTH-1:0] count_reg;

always @(posedge clk) begin
        if (reset) begin
            count_reg <= 32'd0;       // Reset to the first instruction// CORRECTED: Hold internal reg value (freeze)
        end else if (!stall) begin
            count_reg <= d_in;        // Simply capture the address calculated in 'main'
        end                           // CORRECTED: Added missing end keyword
    end

    // Continuous assignment to drive the output wire
    assign pc_out = count_reg;
    

endmodule
