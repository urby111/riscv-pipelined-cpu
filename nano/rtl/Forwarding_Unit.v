`timescale 1ns / 1ps

module Forwarding_Unit (
    input [4:0] ex_rs1,           // rs1 in Execute stage
    input [4:0] ex_rs2,           // rs2 in Execute stage
    input [4:0] mem_rd,           // rd in Memory stage
    input [4:0] wb_rd,            // rd in Write-Back stage
    input       mem_reg_write,    // Is MEM stage actually writing?
    input       wb_reg_write,     // Is WB stage actually writing?

    // --- Hazard Detection Interface (ID, EX, & MEM Stages) ---
    input [4:0] id_rs1,           // rs1 currently in Decode stage
    input [4:0] id_rs2,           // rs2 currently in Decode stage
    input [4:0] ex_rd,            // Destination register in Execute stage
    input       ex_mem_read,      // High if instruction in EX is a LOAD (pipe_mem_read)
    input       mem_mem_read,     // High if instruction in MEM is a LOAD (mem_read_en)
    input       is_jump,
    
    // --- NEW: MEM-to-MEM Forwarding Inputs ---
    input      id_mem_write,     // High if instruction in ID is a STORE
    input [4:0] mem_rs2,          // rs2 currently in Memory stage (Store Data)

    // --- Outputs ---
    output reg [1:0] fwd_a,       // Mux select for ALU input A
    output reg [1:0] fwd_b,       // Mux select for ALU input B
    output reg       stall,       // High when pipeline must freeze
    output reg       fwd_mem      // NEW: Mux select for Store Data in MEM stage
);
    always @(*) begin
        
        // =========================================================
        // 1. HAZARD DETECTION (MODIFIED FOR LOAD-STORE EXEMPTION)
        // =========================================================
        // We exempt id_rs2 from stalling if the ID instruction is a STORE, 
        // because the store doesn't need rs2 until the MEM stage.
        
        // Condition 1: Load in EX.
        if (ex_mem_read && (ex_rd != 0) && (ex_rd == id_rs1)) begin
            stall = 1'b1;
        end 
        else if (ex_mem_read && (ex_rd != 0) && (ex_rd == id_rs2) && !id_mem_write) begin
            stall = 1'b1; // Stall only if NOT a store
        end
        // One bubble is sufficient: when the consumer enters EX, synchronous
        // RAM data and its matching MEM/WB controls are available for WB->EX.
        else begin
            stall = 1'b0;
        end

        // =========================================================
        // 2. EX-STAGE FORWARDING (UNCHANGED)
        // =========================================================
        // --- Forwarding for Input A ---
        if (is_jump)
            fwd_a = 2'b11; // JAL/AUIPC always use PC, not encoded immediate bits.
        else if (mem_reg_write && (mem_rd != 0) && (mem_rd == ex_rs1))
            fwd_a = mem_mem_read ? 2'b00 : 2'b01;
        else if (wb_reg_write && (wb_rd != 0) && (wb_rd == ex_rs1))
            fwd_a = 2'b10; 
        else
            fwd_a = 2'b00; 

        // --- Forwarding for Input B ---
        if (mem_reg_write && (mem_rd != 0) && (mem_rd == ex_rs2))
            fwd_b = mem_mem_read ? 2'b00 : 2'b01;
        else if (wb_reg_write && (wb_rd != 0) && (wb_rd == ex_rs2))
            fwd_b = 2'b10; 
        else
            fwd_b = 2'b00; 

        // =========================================================
        // 3. MEM-STAGE FORWARDING (NEW: LOAD-TO-STORE)
        // =========================================================
        // If a Load is in WB and a Store is in MEM, route WB data directly
        // into the Store's data input multiplexer.
        if (wb_reg_write && (wb_rd != 0) && (wb_rd == mem_rs2))
            fwd_mem = 1'b1; // Grab Store Data from WB instead of EX/MEM pipe
        else
            fwd_mem = 1'b0; // Normal Store Data from EX/MEM pipe
            
    end
endmodule
