`timescale 1ns / 1ps



module FE_ID_Pipe#(
    parameter ADDR_WIDTH = 10,
    parameter DATA_WIDTH = 32
)(
    input reset,
    input clk,
    input [ADDR_WIDTH-1:0] current_PC, // NEW: The actual current PC register value
    
    output reg [ADDR_WIDTH-1:0] PC_out
    );
    
    always@(posedge clk) begin
        if (reset) begin
            PC_out <= 0;
       end else 
            PC_out <= current_PC;
    end
    
endmodule
