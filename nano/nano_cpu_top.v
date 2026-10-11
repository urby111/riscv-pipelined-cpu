// Tang Nano 20K wrapper for the copied CPU and its unified 1 KiB RAM.
module nano_cpu_top (
    input wire clk,             // Onboard 27 MHz oscillator, FPGA pin 4
    input wire reset_button,    // Active-high S1 button, FPGA pin 88
    output wire [5:0] led       // LED0..LED5, active-low FPGA pins 15..20
);
    // Reset the CPU for 32 rising edges after configuration.
    reg [5:0] startup_count = 6'd0;
    reg [1:0] button_sync = 2'b00;
    always @(posedge clk) begin
        if (!startup_count[5])
            startup_count <= startup_count + 1'b1;
        button_sync <= {button_sync[0], reset_button};
    end
    // S1 connects to +3.3 V when pressed; the board pulls pin 88 low at rest.
    wire reset = !startup_count[5] || button_sync[1];
    wire [31:0] led_ram_word;

    main cpu_system (
        .clk(clk),
        .reset(reset),
        .led_word(led_ram_word)
    );

    // Bit 1 means LED on. Invert only because the board LEDs are active-low.
    // LED0 displays RAM bit 0, LED1 bit 1, ..., LED5 bit 5.
    assign led = ~led_ram_word[5:0];
endmodule
