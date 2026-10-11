`timescale 1ns / 1ps

module Ram#(
    parameter ADDR_WIDTH = 10, // 1024 bytes total
    parameter DATA_WIDTH = 32, // Port width is 32-bit
    parameter INIT_FILE = ""  // Optional synthesized program image; empty keeps demo.
)(
    input clk,
    input we,
    input [3:0] be,               // Base Byte Enable from Control Unit
    input stall, // for stall for load
    input is_jump,
    
    // FIX 1: Changed from [ADDR_WIDTH-1:0] to [ADDR_WIDTH-3:0] 
    // This perfectly matches the 8-bit 'fetch_addr' coming from the CPU
    input [ADDR_WIDTH-3:0] instruction, 
    input [DATA_WIDTH-1:0] buffer_instruction,
    
    input [ADDR_WIDTH-3:0] addr,        // Word index from CPU (MEM stage)
    input [DATA_WIDTH-1:0] din,         // Data already shifted to its byte lanes
    output reg [DATA_WIDTH-1:0] dout,   // Aligned data back to CPU
    output reg [DATA_WIDTH-1:0] ins_out // Instruction to CPU
);

    // Array depth = 2^(ADDR_WIDTH - 2)
    // This small (1 KiB) memory favors clock speed over LUT usage. Keep the
    // synchronous read outputs in fabric registers: BRAM clock-to-output plus
    // load alignment and WB->EX forwarding exceeded the 10 ns timing budget.
    (* ram_style = "distributed" *) reg [DATA_WIDTH-1:0] ram [0:(2**(ADDR_WIDTH-2))-1];

    // Convert byte addresses to word addresses (divide by 4) for Data Memory
  
    
    // --- SMART ALIGNMENT LOGIC (Data Memory) ---
    
    
    // The CPU shifts data with the original byte offset. addr is a word index
    // and must never be used as a byte offset.
    wire [DATA_WIDTH-1:0] shifted_din = din;

    initial begin
      if (INIT_FILE != "") begin
        $readmemh(INIT_FILE, ram);
      end else begin
        // Assuming your RAM starts at Byte Address 0 (PC = 0)
        ram[0] = 32'hff010113; // PC = 0:  addi sp, sp, -16   <- Allocate 16 bytes on stack
        ram[1] = 32'h00112623; // PC = 4:  sw   ra, 12(sp)    <- Save Return Address
        ram[2] = 32'h00812423; // PC = 8:  sw   s0, 8(sp)     <- Save Frame Pointer
        ram[3] = 32'h01010413; // PC = 12: addi s0, sp, 16    <- Establish new Frame Pointer
        ram[4] = 32'h00a12223; // PC = 16: sw   a0, 4(sp)     <- Save argument register a0 to stack
        ram[5] = 32'h00412503; // PC = 20: lw   a0, 4(sp)     <- Load value from stack back into a0
        ram[6] = 32'h00000013; // PC = 24: NOP; hardware MUL is disabled.
        ram[7] = 32'h00c12083; // PC = 28: lw   ra, 12(sp)    <- Restore Return Address
        ram[8] = 32'h00812403; // PC = 32: lw   s0, 8(sp)     <- Restore Frame Pointer
        ram[9] = 32'h01010113; // PC = 36: addi sp, sp, 16    <- Deallocate 16 bytes from stack
        ram[10]= 32'h00008067; // PC = 40: jalr x0, 0(ra)     <- Return to caller (ret
      end
    end

    // Synchronous Logic (Perfect BRAM Inference Pattern)
    always @(posedge clk) begin
        // WRITE Logic (Data Memory)
        if (we) begin
            if (be[0]) ram[addr][7:0]   <= shifted_din[7:0];
            if (be[1]) ram[addr][15:8]  <= shifted_din[15:8];
            if (be[2]) ram[addr][23:16] <= shifted_din[23:16];
            if (be[3]) ram[addr][31:24] <= shifted_din[31:24];
        end
        
        // READ Logic (Data Memory)
        dout <= ram[addr];
        
        // --- INSTRUCTION FETCH LOGIC ---
        // FIX 2: Because the CPU already divided the address by 4, 
        // the 'instruction' port is exactly the index we want (0, 1, 2, 3...)
        // The CPU tracks fetch validity and discards wrong-path instructions.
        // Do not route branch decisions into a 32-bit instruction reset mux.
        if (!stall)
            ins_out <= ram[instruction];
        
    end
endmodule
