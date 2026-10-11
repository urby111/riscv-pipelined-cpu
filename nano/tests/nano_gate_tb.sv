`timescale 1ns/1ps
module nano_gate_tb;
    reg clk = 0;
    reg reset_button = 0; // Actual board idle level: S1 is active-high.
    wire [5:0] led;
    nano_cpu_top dut (.clk(clk), .reset_button(reset_button), .led(led));
    always #5 clk = ~clk;
    initial begin
        #1;
        if (led !== 6'b111111)
            $fatal(1, "Watched RAM bits must start at zero in the synthesized circuit");
        repeat (200) @(negedge clk);
        $display("Synthesized circuit: startup_count=%d pc=%h ram=%h led=%b", dut.startup_count, dut.\cpu_system.RISCV_Core.if_pc , dut.led_ram_word, led);
        if (led !== 6'b010101)
            $fatal(1, "Synthesized CPU/RAM/LED path failed");
        reset_button = 1;
        repeat (8) @(negedge clk);
        if (dut.\cpu_system.RISCV_Core.if_pc !== 10'd0)
            $fatal(1, "Synthesized CPU did not reset when S1 was pressed");
        reset_button = 0;
        repeat (200) @(negedge clk);
        if (led !== 6'b010101 || dut.\cpu_system.RISCV_Core.if_pc === 10'd0)
            $fatal(1, "Synthesized circuit did not restart after button reset");
        $display("PASS: synthesized Gowin primitives execute the CPU store and drive LED pins");
        $finish;
    end
endmodule
