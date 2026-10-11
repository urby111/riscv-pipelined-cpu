`timescale 1ns / 1ps


module Mem_Unit#(
    parameter ADDR_WIDTH = 10,
    parameter DATA_WIDTH = 32
)(
    input [DATA_WIDTH-1:0] ram_addr,
    input [DATA_WIDTH-1:0] data_to_ram,
    input [3:0] bit_offset,
    output [ADDR_WIDTH-1:0] raddr,     // Address bus
    output [DATA_WIDTH-1:0] rout      // Data input
    );
    
    always @(*) begin
    
    end
    
endmodule
