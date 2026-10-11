`timescale 1ns / 1ps

module tb_Control_reg();

    // Inputs
    reg clk;
    reg reset;
    reg reg_write, mem_write, mem_read, branch, jump, mem_to_reg, alu_src, reg_read, jump_back;
    reg [1:0] alu_op;

    // Outputs (Wires connecting to the UUT outputs)
    wire r_reg_write, r_mem_write, r_mem_read, r_branch, r_jump, r_mem_to_reg, r_alu_src, r_reg_read, r_jump_back;
    wire [1:0] r_alu_op;

    // Instantiate the Unit Under Test (UUT)
    Control_reg uut (
        .clk(clk), .reset(reset),
        .reg_write(reg_write), .mem_write(mem_write), .mem_read(mem_read),
        .branch(branch), .jump(jump), .mem_to_reg(mem_to_reg),
        .alu_src(alu_src), .alu_op(alu_op), .reg_read(reg_read), .jump_back(jump_back),
        // Outputs
        .r_reg_write(r_reg_write), .r_mem_write(r_mem_write), .r_mem_read(r_mem_read),
        .r_branch(r_branch), .r_jump(r_jump), .r_mem_to_reg(r_mem_to_reg),
        .r_alu_src(r_alu_src), .r_alu_op(r_alu_op), .r_reg_read(r_reg_read), .r_jump_back(r_jump_back)
    );

    // Clock Generation (100MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        // --- STEP 1: Reset Phase ---
        reset = 1;
        reg_write = 1; alu_src = 1; // Try to set inputs while in reset
        #15; 
        reset = 0;
        $display("After Reset: r_reg_write = %b (Expected: 0)", r_reg_write);

        // --- STEP 2: Pass ADDI Signals ---
        // Let's pretend the Control Unit just decoded an ADDI
        reg_write = 1;
        alu_src   = 1;
        alu_op    = 2'b00;
        mem_write = 0;
        
        #10; // Wait one clock cycle
        $display("Cycle 1: r_reg_write = %b, r_alu_src = %b (Expected: 1, 1)", r_reg_write, r_alu_src);

        // --- STEP 3: Change Inputs (Simulate next instruction) ---
        // Pretend next instruction is a 'Store' (No reg_write)
        reg_write = 0;
        mem_write = 1;
        
        #2; // Check halfway through the cycle
        $display("Mid-Cycle: r_reg_write is still %b (Should hold old value until next clock)", r_reg_write);
        
        #8; // Finish the cycle
        $display("Cycle 2: r_reg_write = %b, r_mem_write = %b (Expected: 0, 1)", r_reg_write, r_mem_write);

        #20;
        $finish;
    end

endmodule