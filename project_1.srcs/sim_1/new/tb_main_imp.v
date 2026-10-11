`timescale 1ns / 1ps

module tb_main_imp();

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

// 100 MHz
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin
    $monitor("%5t | tester=%h | tester2=%h",
             $time, tester, tester2);

    reset = 1;

    repeat (3) @(posedge clk);
    @(negedge clk);

    reset = 0;

    #300;

    $display("Simulation Complete.");
    $finish;
end

endmodule