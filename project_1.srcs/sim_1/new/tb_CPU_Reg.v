`timescale 1ns / 1ps

module tb_CPU_Reg();

    // 1. Declare inputs as 'reg' (we drive these)
    reg clk;
    reg reg_write;
    reg [4:0] rs1;
    reg [4:0] rs2;
    reg [4:0] rd;
    reg [31:0] rd_in;

    // 2. Declare outputs as 'wire' (we observe these)
    wire [31:0] rs1_out;
    wire [31:0] rs2_out;

    // 3. Instantiate the Device Under Test (DUT)
    CPU_Reg #(
        .ADDR_WIDTH(5),
        .DATA_WIDTH(32)
    ) DUT (
        .clk(clk),
        .reg_write(reg_write),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .rd_in(rd_in),
        .rs1_out(rs1_out),
        .rs2_out(rs2_out)
    );

    // 4. Clock Generation (10 time units period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // 5. Test Sequence
    initial begin
        // --- Initialization ---
        reg_write = 0;
        rs1 = 0; rs2 = 0; rd = 0;
        rd_in = 0;
        
        $display("--- Starting CPU Register File Test ---");

        // Let the system settle
        #10; 

        // --- TEST 1: Write to a normal register (x5) ---
        $display("\n[TEST 1] Writing 32'hDEADBEEF to register x5...");
        rd = 5;
        rd_in = 32'hDEADBEEF;
        reg_write = 1;
        #10; // Wait for 1 clock cycle to let the write happen
        reg_write = 0; // Turn off write enable
        
        // Read it back
        rs1 = 5;
        rs2 = 0;
        #1; // Wait 1 time unit for combinational logic to update
        $display("Read rs1 (x5): %h", rs1_out);
        if (rs1_out == 32'hDEADBEEF) $display("-> TEST 1 PASSED");
        else $display("-> TEST 1 FAILED");

        // --- TEST 2: The Zero Register (x0) Protection ---
        $display("\n[TEST 2] Attempting to write 32'hFFFFFFFF to zero register x0...");
        rd = 0;
        rd_in = 32'hFFFFFFFF;
        reg_write = 1;
        #10; 
        reg_write = 0;
        
        // Read it back
        rs1 = 0;
        #1;
        $display("Read rs1 (x0): %h", rs1_out);
        if (rs1_out == 32'h00000000) $display("-> TEST 2 PASSED (x0 is protected)");
        else $display("-> TEST 2 FAILED (x0 was overwritten!)");

        // --- TEST 3: Simultaneous Reading ---
        $display("\n[TEST 3] Writing to x10, then reading x5 and x10 simultaneously...");
        // Write to x10
        rd = 10;
        rd_in = 32'hCAFEBABE;
        reg_write = 1;
        #10;
        reg_write = 0;

        // Read x5 on port 1, and x10 on port 2
        rs1 = 5;
        rs2 = 10;
        #1;
        $display("Read rs1 (x5) : %h", rs1_out);
        $display("Read rs2 (x10): %h", rs2_out);
        
        if (rs1_out == 32'hDEADBEEF && rs2_out == 32'hCAFEBABE) 
            $display("-> TEST 3 PASSED");
        else 
            $display("-> TEST 3 FAILED");

        // End simulation
        $display("\n--- Testbench Complete ---");
        $finish;
    end

endmodule