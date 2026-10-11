`timescale 1ns / 1ps

module PC_MUX #(
    parameter ADDR_WIDTH = 10
)(
    input reset,
    input stall,                    // 1: Freeze PC, 0: Normal update
    input [ADDR_WIDTH-1:0] next_PC, // Calculated PC (PC + 4)
    input [ADDR_WIDTH-1:0] current_PC, // NEW: The actual current PC register value
    output reg [ADDR_WIDTH-1:0] PC_out
);

    // Completely combinational selection using blocking assignments (=)
    always @(*) begin
        if (reset) begin
            PC_out = 0;              // Boot up at address 0
        end else if (stall) begin
            PC_out = current_PC;     // STALL: Feed back the current PC so it doesn't change
        end else begin
            PC_out = next_PC;        // NORMAL: Advance to next instruction (PC + 4)
        end
        
    end

endmodule