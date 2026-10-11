`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/19/2026 06:41:55 PM
// Design Name: 
// Module Name: adder
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module adder(
    input [7:0] a,
    input [7:0] b,
    output [7:0] c,
    input [0:0] clk
    );
    
    reg [7:0]r;
    always@(posedge clk) begin
        r <= a + b;
    end
    
    assign c = r;
endmodule
