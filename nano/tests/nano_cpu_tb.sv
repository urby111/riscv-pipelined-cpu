`timescale 1ns/1ps
module nano_cpu_tb;
    reg clk = 0;
    reg reset_button = 0; // Released S1 is low on the actual board.
    wire [5:0] led;
    integer stores = 0;
    nano_cpu_top dut (.clk(clk), .reset_button(reset_button), .led(led));
    always #5 clk = ~clk;

    // Observe the original CPU's memory interface, not the displayed value.
    always @(posedge clk) begin
        if (dut.cpu_system.bus_we) begin
            if (dut.reset) $fatal(1, "CPU wrote while reset was asserted");
            if (dut.cpu_system.bus_data_addr !== 8'd128)
                $fatal(1, "Store targeted the wrong RAM word");
            if (dut.cpu_system.bus_be !== 4'b1111)
                $fatal(1, "Expected all four byte lanes to be written");
            if (dut.cpu_system.bus_write_data !== 32'hAAAAAAAA)
                $fatal(1, "CPU computed the wrong store data");
            stores = stores + 1;
        end
    end

    initial begin
        #1;
        if (dut.cpu_system.System_Memory.ram[128] !== 32'd0)
            $fatal(1, "Target RAM cell must start at zero, not the LED pattern");
        if (led !== 6'b111111) $fatal(1, "All LEDs must start off");
        repeat (160) @(negedge clk);
        if (stores != 1) $fatal(1, "Expected exactly one CPU store, got %0d", stores);
        if (dut.cpu_system.System_Memory.ram[128] !== 32'hAAAAAAAA)
            $fatal(1, "Actual RAM word does not contain the CPU pattern");
        if (dut.cpu_system.RISCV_Core.register_file.CPU_reg[2] !== 32'hAAAAAAAA)
            $fatal(1, "CPU load from the same address did not return the pattern");
        if (led !== 6'b010101) $fatal(1, "LED pins do not show inverted RAM bits 101010");
        $display("PASS: CPU stored AAAAAAAA at byte 0x200 / word 128, read it back, and LEDs display its six low bits");

        // A different RAM address must not change the display.
        dut.cpu_system.System_Memory.ram[129] = 32'hFFFFFFFF;
        #1;
        if (led !== 6'b010101) $fatal(1, "LEDs accidentally watch RAM word 129");
        // Changing the watched cell must change LEDs without another CPU store.
        dut.cpu_system.System_Memory.ram[128] = 32'h00000015;
        #1;
        if (led !== 6'b101010) $fatal(1, "LEDs are hard-coded or showing a store-bus shadow");
        dut.cpu_system.System_Memory.ram[128] = 32'hAAAAAAAA;
        #1;
        if (led !== 6'b010101) $fatal(1, "RAM-to-LED path did not restore");
        $display("PASS: adjacent-cell isolation and live watched-cell changes prove the LED RAM read path");

        reset_button = 1;
        repeat (8) @(negedge clk);
        if (!dut.reset) $fatal(1, "Reset button did not reset the CPU");
        reset_button = 0;
        repeat (160) @(negedge clk);
        if (stores != 2) $fatal(1, "CPU did not execute the store again after button reset");
        if (led !== 6'b010101) $fatal(1, "LED pattern not correct after reset");
        $display("PASS: synchronized button reset reruns the CPU program");
        $finish;
    end
    initial begin
        #100000;
        $fatal(1, "CPU demonstration timed out");
    end
endmodule
