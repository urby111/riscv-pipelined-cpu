`timescale 1ns / 1ps

module PC_Reg_tb;

    // --- 1. Parameters & Testbench Signals ---
    parameter ADDR_WIDTH = 10;

    reg clk;
    reg reset;
    reg stall;
    reg [ADDR_WIDTH-1:0] next_PC;
    
    wire [ADDR_WIDTH-1:0] PC_out;

    // --- 2. Instantiate the Unit Under Test (UUT) ---
    PC_Reg #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) uut (
        .clk(clk),
        .reset(reset),
        .stall(stall),
        .next_PC(next_PC),
        .PC_out(PC_out)
    );

    // --- 3. Clock Generation (100MHz / 10ns Clock Period) ---
    always begin
        #5 clk = ~clk;
    end

    // --- 4. Test Stimulus Block ---
    initial begin
        // Initialize all input inputs
        clk = 0;
        reset = 1;
        stall = 0;
        next_PC = 0;

        // -------------------------------------------------------------
        // SCENARIO 1: Power-on Reset
        // -------------------------------------------------------------
        #12; // Wait slightly over 1 full clock cycle
        reset = 0; // Release reset
        $display("[TIME %0dns] Reset released. PC_out = %0d (Expected: 0)", $time, PC_out);

        // -------------------------------------------------------------
        // SCENARIO 2: Normal Step-by-Step Execution (Stall = 0)
        // -------------------------------------------------------------
        // Mimicking typical sequential program counter behavior (PC + 4)
        next_PC = 10'd4;
        #10; // Wait 1 clock cycle
        $display("[TIME %0dns] Normal Instruction Step 1. PC_out = %0d (Expected: 4)", $time, PC_out);
        
        next_PC = 10'd8;
        #10;
        $display("[TIME %0dns] Normal Instruction Step 2. PC_out = %0d (Expected: 8)", $time, PC_out);

        next_PC = 10'd12;
        #10;
        $display("[TIME %0dns] Normal Instruction Step 3. PC_out = %0d (Expected: 12)", $time, PC_out);

        // -------------------------------------------------------------
        // SCENARIO 3: Pipeline Hazard / Stall Asserted (Stall = 1)
        // -------------------------------------------------------------
        // Hazard unit flags a stall. The datapath tries to feed PC=16, 
        // but our PC register should successfully freeze and hold '12'.
        stall = 1;
        next_PC = 10'd16; 
        #10;
        $display("[TIME %0dns] STALL ACTIVE! next_PC was 16. PC_out = %0d (Expected: 12)", $time, PC_out);

        // Keep it stalled for a second cycle to prove multi-cycle stalling works.
        // Even if next_PC changes to 20, PC_out must remain stuck at 12.
        next_PC = 10'd20;
        #10;
        $display("[TIME %0dns] STALL STILL ACTIVE! next_PC was 20. PC_out = %0d (Expected: 12)", $time, PC_out);

        // -------------------------------------------------------------
        // SCENARIO 4: Stall Released (Stall = 0)
        // -------------------------------------------------------------
        // Hazard clears! Let's re-attempt the address we were paused on.
        stall = 0;
        next_PC = 10'd16; 
        #10;
        $display("[TIME %0dns] Stall dropped. PC_out = %0d (Expected: 16)", $time, PC_out);

        // -------------------------------------------------------------
        // SCENARIO 5: Branch / Jump Verification
        // -------------------------------------------------------------
        // Pass a non-sequential address to simulate a JAL, JALR, or BEQ jump target
        next_PC = 10'd240; 
        #10;
        $display("[TIME %0dns] Branch taken! PC_out = %0d (Expected: 240)", $time, PC_out);

        // Finish up simulation
        #20;
        $display("-----------------------------------------------------");
        $display("--- PC_Reg Simulation Tests Finished Successfully ---");
        $display("-----------------------------------------------------");
        $finish;
    end

endmodule