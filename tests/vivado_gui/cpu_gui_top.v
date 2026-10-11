`timescale 1ns/1ps
// Verification shell: the production CPU and RAM, with an initialized test
// program and registered observations of actual memory writes. No CPU changes.
module cpu_gui_top (
    input wire clk,
    input wire reset,
    output wire observe_clk,
    output wire [287:0] debug,
    output reg store_valid,
    output reg [7:0] store_addr,
    output reg [3:0] store_be,
    output reg [31:0] store_data
);
    wire core_clk;
    BUFG clock_buffer (.I(clk), .O(core_clk));
    assign observe_clk = core_clk;
    wire [7:0] fetch_addr, data_addr;
    wire [31:0] instruction, buffer_instruction, write_data, ram_data;
    wire [3:0] mem_be;
    wire stall, is_jump, mem_we;

    main_cpu core (
        .clk(core_clk), .reset(reset), .stall_out(stall), .is_jump(is_jump),
        .fetch_addr(fetch_addr), .instruction(instruction),
        .data_addr(data_addr), .mem_we(mem_we), .mem_be(mem_be),
        .write_data(write_data), .buffer_instruction(buffer_instruction),
        .ram_data(ram_data),
        .test(debug[31:0]), .test2(debug[63:32]), .test3(debug[95:64]),
        .test4(debug[127:96]), .test5(debug[159:128]), .test6(debug[191:160]),
        .test7(debug[223:192]), .test8(debug[255:224]), .test9(debug[287:256])
    );
    Ram #(.INIT_FILE("gui_program.mem")) memory (
        .clk(core_clk), .we(mem_we), .be(mem_be), .stall(stall),
        .is_jump(is_jump), .instruction(fetch_addr),
        .buffer_instruction(buffer_instruction), .addr(data_addr),
        .din(write_data), .dout(ram_data), .ins_out(instruction)
    );
    // These sample the same signals on the same clock edge as the RAM write.
    // Only store_valid needs reset; payload is ignored when it is false.
    always @(posedge core_clk) begin
        store_valid <= !reset && mem_we;
        store_addr <= data_addr;
        store_be <= mem_be;
        store_data <= write_data;
    end
endmodule
