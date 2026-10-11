`timescale 1ns / 1ps

module Ram_tb();

    // Parameters
    reg clk;
    reg we;
    reg [3:0] be;
    reg [9:0] instruction;
    reg [9:0] addr;
    reg [31:0] din;
    wire [31:0] dout;
    wire [31:0] ins_out;

    // Instantiate the Unit Under Test (UUT)
    Ram #(.ADDR_WIDTH(10)) uut (
        .clk(clk),
        .we(we),
        .be(be),
        .instruction(instruction),
        .addr(addr),
        .din(din),
        .dout(dout),
        .ins_out(ins_out)
    );

    // Clock generation (100MHz)
    always #5 clk = ~clk;

    initial begin
        // Initialize Inputs
        clk = 0;
        we = 0;
        be = 0;
        instruction = 0;
        addr = 0;
        din = 0;

        // Wait for global reset
        #20;

        // --- TEST 1: Write a 32-bit Word ---
        // Let's store 0xDEADBEEF at address 4
        addr = 10'd4;
        din = 32'hDEADBEEF;
        be = 4'b1111; // Enable all bytes
        we = 1;
        #10;
        we = 0; // Disable write

        // --- TEST 2: Read that word back via dout ---
        addr = 10'd4;
        be = 4'b1111;
        #10;
        $display("At time %t, Read Dout: %h", $time, dout);

        // --- TEST 3: Fetch it via Instruction Port ---
        instruction = 10'd4;
        #10;
        $display("At time %t, Fetched Instruction: %h", $time, ins_out);

        // --- TEST 4: Partial Write (Byte masking) ---
        // Change only the "BEEF" part to "FACE"
        addr = 10'd4;
        din = 32'h0000FACE;
        be = 4'b0011; // Only update lowest 2 bytes
        we = 1;
        #10;
        we = 0;
        
        // Final Read to check if memory is now 0xDEADFACE
        be = 4'b1111;
        #10;
        $display("At time %t, After partial write: %h", $time, dout);

        #50;
        $finish;
    end

endmodule