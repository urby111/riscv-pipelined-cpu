`timescale 1ns / 1ps

module tb_adder();
    // 1. Create signals to connect to the adder
    reg [7:0] a_sim;
    reg [7:0] b_sim;
    wire [7:0] c_sim;
    reg       clk_sim;

    // 2. Instantiate your adder (The Unit Under Test)
    adder uut (
        .a(a_sim),
        .b(b_sim),
        .c(c_sim),
        .clk(clk_sim)
    );

    // 3. Generate the Clock (100MHz)
    initial clk_sim = 0;
    always #5 clk_sim = ~clk_sim; // Toggle every 5ns

    // 4. Feed the data (The Stimulus)
    initial begin
        // Initialize values
        a_sim = 8'd10;  // 10 in decimal
        b_sim = 8'd20;  // 20 in decimal
        
        #20;            // Wait 20ns
        a_sim = 8'd50;  // Change values
        b_sim = 8'd5;
        
        #20;
        $finish;        // Stop the simulation
    end
endmodule
