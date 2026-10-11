`timescale 1ns / 1ps

module tb_main();

    // 1. Testbench Signals
    reg clk;
    reg reset;
    wire [31:0] tester; 
    wire [31:0] tester2;
    wire [31:0] tester3;
    wire [31:0] tester4;
    wire [31:0] tester5;
    wire [31:0] tester6;
    wire [31:0] tester7;
    wire [31:0] tester8;
    wire [31:0] tester9;

    // 2. Instantiate the Top-Level System
    main dut (
        .clk(clk),
        .reset(reset),
        .tester(tester),
        .tester2(tester2),
        .tester3(tester3),
        .tester4(tester4),
        .tester5(tester5),
        .tester6(tester6),
        .tester7(tester7),
        .tester8(tester8),
        .tester9(tester9)
    );

    // 3. Clock Generation (10ns period = 100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // 4. Test Sequence & Monitoring
    initial begin
        // Waveform dumping (Uncomment these if you want to view the waveforms in a tool like GTKWave)
        // $dumpfile("cpu_sim.vcd");
        // $dumpvars(0, tb_main);

        // Print a header for our console output
        $display("=================================================");
        $display(" Time (ns) | PC (Decimal) | Fetched Instruction ");
        $display("=================================================");
        
        // $monitor automatically prints these values whenever they change.
        // We are monitoring the exact wires connecting the CPU and the RAM.
        $monitor("     %5t |     %03d      |      %h", $time, dut.bus_fetch_addr, dut.bus_instruction);

        // Initialize signals (Reset is ACTIVE)
        reset = 1;

        // Hold reset active for 15ns (Wait for clock to stabilize)
        #15; 
        
        // Release reset so the CPU starts running
        reset = 0;

        // Let the CPU run for 300ns (30 clock cycles)
        #300;

        // End the simulation
        $display("=================================================");
        $display("Simulation Complete.");
        $finish;
    end

endmodule