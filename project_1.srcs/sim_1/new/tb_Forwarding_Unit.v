`timescale 1ns / 1ps

module tb_Forwarding_Unit();

    // Inputs (reg)
    reg [4:0] ex_rs1, ex_rs2;
    reg [4:0] mem_rd, wb_rd;
    reg mem_reg_write, wb_reg_write;

    // Outputs (wire)
    wire [1:0] fwd_a, fwd_b;

    // Instantiate Unit Under Test (UUT)
    Forwarding_Unit uut (
        .ex_rs1(ex_rs1), 
        .ex_rs2(ex_rs2),
        .mem_rd(mem_rd), 
        .wb_rd(wb_rd),
        .mem_reg_write(mem_reg_write), 
        .wb_reg_write(wb_reg_write),
        .fwd_a(fwd_a), 
        .fwd_b(fwd_b)
    );

    initial begin
        $display("------------------------------------------------------------");
        $display(" Time | RS1 | RS2 | MEM_RD | WB_RD | FWD_A | FWD_B | Note");
        $display("------------------------------------------------------------");

        // --- TEST 1: No Hazards (Clean running) ---
        ex_rs1 = 5; ex_rs2 = 6;
        mem_rd = 10; wb_rd = 11;
        mem_reg_write = 1; wb_reg_write = 1;
        #10; $display("%4t |  %2d |  %2d |   %2d   |   %2d  |  %b   |  %b   | Normal Path", $time, ex_rs1, ex_rs2, mem_rd, wb_rd, fwd_a, fwd_b);

        // --- TEST 2: Forward from MEM for RS1 ---
        mem_rd = 5; // Match RS1
        #10; $display("%4t |  %2d |  %2d |   %2d   |   %2d  |  %b   |  %b   | Forward MEM->A", $time, ex_rs1, ex_rs2, mem_rd, wb_rd, fwd_a, fwd_b);

        // --- TEST 3: Forward from WB for RS2 ---
        mem_rd = 10; // Clear MEM match
        wb_rd = 6;   // Match RS2
        #10; $display("%4t |  %2d |  %2d |   %2d   |   %2d  |  %b   |  %b   | Forward WB->B", $time, ex_rs1, ex_rs2, mem_rd, wb_rd, fwd_a, fwd_b);

        // --- TEST 4: Priority Check (MEM wins over WB) ---
        mem_rd = 5;  // Latest instruction writes to x5
        wb_rd = 5;   // Instruction 2 cycles ago also writes to x5
        #10; $display("%4t |  %2d |  %2d |   %2d   |   %2d  |  %b   |  %b   | Priority: MEM wins", $time, ex_rs1, ex_rs2, mem_rd, wb_rd, fwd_a, fwd_b);

        // --- TEST 5: The x0 Special Case ---
        // Even if x0 is the destination, we MUST NOT forward (should be 00)
        ex_rs1 = 0; mem_rd = 0; 
        #10; $display("%4t |  %2d |  %2d |   %2d   |   %2d  |  %b   |  %b   | x0 check (Correct: 00)", $time, ex_rs1, ex_rs2, mem_rd, wb_rd, fwd_a, fwd_b);

        // --- TEST 6: RegWrite Disable Check ---
        // Address matches, but the instruction isn't a "Write" type (e.g. a Branch)
        ex_rs1 = 8; mem_rd = 8; mem_reg_write = 0;
        #10; $display("%4t |  %2d |  %2d |   %2d   |   %2d  |  %b   |  %b   | RegWrite=0 Check", $time, ex_rs1, ex_rs2, mem_rd, wb_rd, fwd_a, fwd_b);

        $display("------------------------------------------------------------");
        $finish;
    end
endmodule
