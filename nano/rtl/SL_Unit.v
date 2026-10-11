`timescale 1ns / 1ps

module LS_Unit#(
    parameter ADDR_WIDTH = 10,
    parameter DATA_WIDTH = 32
)(
    // Removed clk - this unit is usually combinatorial logic
    input [31:0] reg_data_raw,   // The 32-bit word straight from RAM
    input [31:0] ram_data_raw,   // The 32-bit word straight from RAM
    input [1:0]  sel,      // Matches RISC-V funct3 (LB, LH, LW, LBU, LHU)
    output reg [31:0] data_to_reg, // The formatted data
    input [ADDR_WIDTH-1:0] addr,     // Address bus
    input [DATA_WIDTH-1:0] rout      // Data input
    );
    
    // --- RISC-V Funct3 Load Labels ---
    localparam store  = 3'b10; 
    localparam load  = 3'b01;

    always @(*) begin 
        case(sel)
            store : data_to_reg = reg_data_raw;
            default: data_to_reg = ram_data_raw;
        endcase
    end
endmodule
