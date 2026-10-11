`timescale 1ns / 1ps

module WriteBack_Aligner(
    input  [31:0] mem_read_data,    // Data coming directly from RAM
    input  [1:0]  addr_offset,      // mem_alu_result[1:0]
    input  [2:0]  load_type,        // funct3 (000:LB, 001:LH, 010:LW, 100:LBU, 101:LHU)
    input         is_load,          // Control signal: 1 if this is a load instruction
    
    output reg [31:0] wb_data       // Final aligned/sign-extended data for the Register File
);

    // 1. Shift the raw RAM data to the bottom [7:0]
    wire [31:0] shifted_data = mem_read_data >> (addr_offset * 8);

    always @(*) begin
        if (is_load) begin
            case (load_type)
                // LB: Sign-extend byte
                3'b000: wb_data = {{24{shifted_data[7]}}, shifted_data[7:0]};
                // LH: Sign-extend halfword
                3'b001: wb_data = {{16{shifted_data[15]}}, shifted_data[15:0]};
                // LW: Full word
                3'b010: wb_data = shifted_data;
                // LBU: Zero-extend byte
                3'b100: wb_data = {24'b0, shifted_data[7:0]};
                // LHU: Zero-extend halfword
                3'b101: wb_data = {16'b0, shifted_data[15:0]};
                // Default
                default: wb_data = shifted_data;
            endcase
        end else begin
            // If it's not a load, just pass through (or return 0)
            wb_data = 32'b0;
        end
    end
endmodule