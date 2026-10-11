`timescale 1ns / 1ps

module tb_Reg_pipe();

    // 1. Signals for the DUT (Device Under Test)
    reg clk;
    reg reset;
    reg [31:0] rs1;
    reg [31:0] rs2;
    reg [4:0] rd;
    
    wire [31:0] out_rs1;
    wire [31:0] out_rs2;
    wire [4:0] out_rd;

    // 2. Instantiate the Module
    Reg_pipe DUT (
        .clk(clk),
        .reset(reset),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .out_rs1(out_rs1),
        .out_rs2(out_rs2),
        .out_rd(out_rd)
    );

    // 3. Clock Generation (100MHz / 10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // 4. Stimulus
    initial begin
        // Initial state
        reset = 1;
        rs1 = 0; rs2 = 0; rd = 0;
        
        // Wait 20ns and release reset
        #20 reset = 0;
        
        // --- Test Case 1 ---
        @(negedge clk); // Apply data on falling edge to meet setup time
        rs1 = 32'hAAAA_AAAA;
        rs2 = 32'hBBBB_BBBB;
        rd  = 5'd10;
        
        $display("Input: rs1=%h, rs2=%h, rd=%d", rs1, rs2, rd);
        
        @(posedge clk); // Rising edge happens
        #1; // Small delay to let the 'reg' update in simulation
        $display("Output after 1st Clock: out_rs1=%h, out_rs2=%h, out_rd=%d", out_rs1, out_rs2, out_rd);

        // --- Test Case 2 ---
        @(negedge clk);
        rs1 = 32'h1234_5678;
        rs2 = 32'h8765_4321;
        rd  = 5'd31;

        @(posedge clk);
        #1;
        $display("Output after 2nd Clock: out_rs1=%h, out_rs2=%h, out_rd=%d", out_rs1, out_rs2, out_rd);

        #20;
        $finish;
    end

endmodule