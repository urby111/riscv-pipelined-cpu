`timescale 1ns/1ps
module tb_cpu_100mhz;
    reg clk = 0;
    reg reset = 1;
    real half_period_ns = 5.0; // Default: 10 ns period = 100 MHz.
    initial begin
        // Optional slower clock is for diagnosis; the delivered test uses 5 ns.
        if ($value$plusargs("half_period_ns=%f", half_period_ns)) begin end
        forever #(half_period_ns) clk = ~clk;
    end

    wire observe_clk, store_valid;
    wire [287:0] debug;
    wire [7:0] store_addr;
    wire [3:0] store_be;
    wire [31:0] store_data;
    cpu_gui_top dut (
        .clk(clk), .reset(reset), .observe_clk(observe_clk), .debug(debug),
        .store_valid(store_valid), .store_addr(store_addr),
        .store_be(store_be), .store_data(store_data)
    );

    `include "expected_stores.vh"
    integer seen = 0;
    integer cycles = 0;
    integer quiet_cycles = 0;
    integer run_number = 1;
    reg done = 0;
    reg [31:0] mask;

    initial begin
        initialize_expected();
        // Netlist simulation asserts global reset for its first 100 ns.
        // Keep our synchronous reset active for 200 ns, then release away
        // from the active edge. The clock runs throughout startup.
        repeat (20) @(negedge clk);
        reset = 0;
        wait(done);
        // Repeat after reset without reloading RAM: tests reset/restart and
        // program initialization of its scratch data as well as first boot.
        @(negedge clk); reset = 1;
        repeat (20) @(negedge clk);
        seen = 0; cycles = 0; quiet_cycles = 0; done = 0; run_number = 2;
        reset = 0;
        wait(done);
        if (half_period_ns == 5.0)
            $display("CPU_100MHZ_PASS: %0d checked stores per run; 2 runs; 10 ns clock", EXPECTED_COUNT);
        else
            $display("CPU_DIAGNOSTIC_PASS: %0d stores per run; 2 runs; clock period=%0.3f ns", EXPECTED_COUNT, 2.0*half_period_ns);
        $finish;
    end

    // Observe only DUT PORTS, never RTL register names or memory hierarchy.
    // Sample after the buffered clock's falling edge, allowing registered
    // observation outputs to settle even with annotated routing delays.
    always @(negedge observe_clk) begin
        #1;
        if (!reset && !done) begin
            cycles = cycles + 1;
            if (store_valid !== 1'b0 && store_valid !== 1'b1)
                $fatal(1, "Unknown store_valid at %t", $time);
            if (store_valid === 1'b1) begin
                if (seen >= EXPECTED_COUNT)
                    $fatal(1, "Unexpected extra store after completion");
                mask = {{8{expected_be[seen][3]}}, {8{expected_be[seen][2]}},
                        {8{expected_be[seen][1]}}, {8{expected_be[seen][0]}}};
                if (store_addr !== expected_addr[seen] ||
                    store_be !== expected_be[seen] ||
                    (store_data & mask) !== (expected_data[seen] & mask))
                    $fatal(1, "Store %0d mismatch: addr=%h be=%h data=%h; expected addr=%h be=%h data=%h",
                           seen, store_addr, store_be, store_data,
                           expected_addr[seen], expected_be[seen], expected_data[seen]);
                seen = seen + 1;
            end
            if (seen == EXPECTED_COUNT) begin
                quiet_cycles = quiet_cycles + 1;
                if (quiet_cycles == 20) begin
                    done = 1;
                    $display("RUN %0d PASS: %0d stores, %0d cycles", run_number, seen, cycles);
                end
            end
            if (cycles > 2000)
                $fatal(1, "Timeout: only %0d of %0d expected stores", seen, EXPECTED_COUNT);
        end
    end
    initial begin
        #50000;
        $fatal(1, "Global watchdog: simulation did not complete");
    end
endmodule
