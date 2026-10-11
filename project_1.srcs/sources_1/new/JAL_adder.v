`timescale 1ns / 1ps



module JAL_adder#(
    parameter ADDR_WIDTH = 10,
    parameter DATA_WIDTH = 32
)(
    input [ADDR_WIDTH-1:0] hazard_buffer_in,
    input [31:0] imm_in,
    
    output [31:0] JAL_result_out
);
endmodule
