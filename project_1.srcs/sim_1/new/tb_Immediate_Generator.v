`timescale 1ns / 1ps

module tb_Immediate_Generator();

    // Inputs
    reg clk;
    reg reset;
    reg [31:0] instruction;

    // Outputs
    wire [31:0] imm_out;

    // Instantiate the Unit Under Test (UUT)
    Immediate_Generator uut (
        .clk(clk), 
        .reset(reset), 
        .instruction(instruction), 
        .imm_out(imm_out)
    );

    // Clock generation (Though module is combinational, good for timing)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        // Initialize Inputs
        reset = 1;
        instruction = 32'h0;

        // Wait for reset
        #20;
        reset = 0;

        // --- TEST 1: Positive Immediate (ADDI x1, x0, 5) ---
        // imm[11:0] = 12'h005, rs1=0, func3=0, rd=1, opcode=7'b0010011
        instruction = 32'b000000000101_00000_000_00001_0010011;
        #10;
        $display("Test 1: Positive Imm=5 | imm_out = %d (Expected: 5)", $signed(imm_out));

        // --- TEST 2: Negative Immediate (ADDI x1, x0, -1) ---
        // imm[11:0] = 12'hFFF, rs1=0, func3=0, rd=1, opcode=7'b0010011
        instruction = 32'b111111111111_00000_000_00001_0010011;
        #10;
        $display("Test 2: Negative Imm=-1 | imm_out = %d (Expected: -1)", $signed(imm_out));

        // --- TEST 3: Edge Case "100000000000" (-2048) ---
        // This tests if the sign bit (1) is successfully copied 20 times.
        instruction = 32'b100000000000_00000_000_00001_0010011;
        #10;
        $display("Test 3: Min Negative Imm | imm_out = %d (Expected: -2048)", $signed(imm_out));

        // --- TEST 4: Invalid Opcode (Should default to 0) ---
        instruction = 32'b000000000101_00000_000_00001_1111111;
        #10;
        $display("Test 4: Bad Opcode | imm_out = %h (Expected: 0)", imm_out);

        #20;
        $finish;
    end
      
endmodule