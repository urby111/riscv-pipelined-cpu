`timescale 1ns / 1ps

module tb_Arith_MUX();

    // 1. Signals
    reg [31:0] rs2_val;
    reg [31:0] mem_val;
    reg [31:0] wb_val;
    reg [31:0] imm_val;
    reg [1:0]  fwd_sel;
    reg        alu_src;
    wire [31:0] alu_in_b;

    // 2. Instantiate Unit Under Test (UUT)
    Arith_MUX uut (
        .rs2_val(rs2_val),
        .mem_val(mem_val),
        .wb_val(wb_val),
        .imm_val(imm_val),
        .fwd_sel(fwd_sel),
        .alu_src(alu_src),
        .alu_in_b(alu_in_b)
    );

    // 3. Test Procedure
    initial begin
        // Initialize distinct values for easy tracking
        rs2_val = 32'hAAAA_AAAA; // 10 in our "head" (Register File)
        mem_val = 32'hBBBB_BBBB; // 20 in our "head" (Forward from MEM)
        wb_val  = 32'hCCCC_CCCC; // 30 in our "head" (Forward from WB)
        imm_val = 32'hDDDD_DDDD; // 40 in our "head" (Immediate)
        
        $display("---------------------------------------------------------");
        $display(" Time | ALU_SRC | FWD_SEL | Expected Output | Actual Output");
        $display("---------------------------------------------------------");

        // --- TEST 1: Standard Register Read (R-Type, no hazards) ---
        alu_src = 0; fwd_sel = 2'b00; #10;
        $display("%4t |    %b    |    %b   |   AAAAAAAA    |   %h", $time, alu_src, fwd_sel, alu_in_b);

        // --- TEST 2: Forward from MEM Stage (R-Type, hazard) ---
        alu_src = 0; fwd_sel = 2'b01; #10;
        $display("%4t |    %b    |    %b   |   BBBBBBBB    |   %h", $time, alu_src, fwd_sel, alu_in_b);

        // --- TEST 3: Forward from WB Stage (R-Type, hazard) ---
        alu_src = 0; fwd_sel = 2'b10; #10;
        $display("%4t |    %b    |    %b   |   CCCCCCCC    |   %h", $time, alu_src, fwd_sel, alu_in_b);

        // --- TEST 4: Immediate Value (I-Type, like ADDI) ---
        // Note: Even if fwd_sel is active, alu_src should override it
        alu_src = 1; fwd_sel = 2'b00; #10;
        $display("%4t |    %b    |    %b   |   DDDDDDDD    |   %h", $time, alu_src, fwd_sel, alu_in_b);

        // --- TEST 5: Immediate Override Check ---
        // If it's an ADDI, we don't care about forwarding RS2!
        alu_src = 1; fwd_sel = 2'b01; #10;
        $display("%4t |    %b    |    %b   |   DDDDDDDD    |   %h (Correct: Imm wins)", $time, alu_src, fwd_sel, alu_in_b);

        $display("---------------------------------------------------------");
        $finish;
    end

endmodule
