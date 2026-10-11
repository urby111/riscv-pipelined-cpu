`timescale 1ns / 1ps


module Mem_Fwd_MUX (
    input  [31:0] ex_mem_rs2_data, // Default store data (piped from EX/MEM register)
    input  [31:0] wb_data,         // Forwarded data from WB stage (the Load data)
    input         fwd_mem,         // 1-bit control signal from your hazard unit
    
    output [31:0] store_data_out   // Final data routed to Data Memory 'WriteData' port
);

    // =========================================================
    // MEM-STAGE FORWARDING (LOAD-TO-STORE)
    // =========================================================
    // If fwd_mem is 1, grab the WB data. Otherwise, use normal EX/MEM data.
    assign store_data_out = (fwd_mem) ? wb_data : ex_mem_rs2_data;

endmodule