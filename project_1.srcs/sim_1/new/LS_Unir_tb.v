`timescale 1ns / 1ps

module tb_Ram;

    // 1. Define Parameters (Must match your RAM module)
    parameter ADDR_WIDTH = 10;
    parameter DATA_WIDTH = 32;

    // 2. Declare Signals
    // Inputs to the module are 'reg' so we can control them in initial blocks
    reg clk;
    reg we;
    reg [ADDR_WIDTH-1:0] addr;
    reg [DATA_WIDTH-1:0] din;
    
    // Outputs from the module are 'wire' to passively read them
    wire [DATA_WIDTH-1:0] dout;

    // 3. Instantiate the Unit Under Test (UUT)
    Ram #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) uut (
        .clk(clk),
        .we(we),
        .addr(addr),
        .din(din),
        .dout(dout)
    );

    // 4. Generate the Clock
    // Toggle the clock every 5ns. (5ns high, 5ns low = 10ns period -> 100 MHz)
    always #5 clk = ~clk;

    // 5. The Test Sequence
    initial begin
        // Initialize all inputs to 0
        clk = 0;
        we = 0;
        addr = 0;
        din = 0;

        // Wait a bit before starting
        #20; 
        
        $display("--- Starting RAM Test ---");

        // --- TEST 1: Write Data ---
        // We change inputs on the negative edge so they are stable 
        // when the positive edge of the clock hits.
        @(negedge clk); 
        we = 1;                     // Enable writing
        addr = 10'd15;              // Choose address 15
        din = 32'hDEADBEEF;         // Put some test hex data on the bus
        
        @(negedge clk);
        we = 1;                     
        addr = 10'd42;              // Choose address 42
        din = 32'hCAFEBABE;         // Put different data on the bus

        // --- TEST 2: Read Data ---
        @(negedge clk);
        we = 0;                     // Turn off write enable! (CRITICAL)
        addr = 10'd15;              // Look back at address 15
        
        @(negedge clk); // Wait one clock cycle for the RAM to process the read
        $display("Reading Addr 15: %h (Expected: deadbeef)", dout);

        @(negedge clk);
        addr = 10'd42;              // Look back at address 42
        
        @(negedge clk);
        $display("Reading Addr 42: %h (Expected: cafebabe)", dout);

        // --- TEST 3: Read an empty address ---
        @(negedge clk);
        addr = 10'd99;              // Address we never wrote to
        
        @(negedge clk);
        $display("Reading Addr 99: %h (Expected: xxxxxxxx)", dout);

        // End simulation
        #20;
        $display("--- Test Finished ---");
        $finish;
    end

endmodule