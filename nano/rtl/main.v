`timescale 1ns / 1ps

module main(
    input clk,
    input reset,
    output [31:0] tester,
    output [31:0] tester2,
    output [31:0] tester3,
    output [31:0] tester4,
    output [31:0] tester5,
    output [31:0] tester6,
    output [31:0] tester7,
    output [31:0] tester8,
    output [31:0] tester9,
    output [31:0] led_word
);

    // Wires to connect the CPU and RAM together
    wire [7:0]  bus_fetch_addr;
    wire [31:0] bus_instruction;
    wire [31:0] buffer_instruction;
    wire stall;
    
    wire [7:0]  bus_data_addr;
    wire [31:0] bus_write_data;
    wire [31:0] bus_read_data;
    wire        bus_we;
    wire [3:0]  bus_be;
    wire is_jump;

    // 1. Instantiate the CPU Core
    main_cpu #(.ADDR_WIDTH(10), .DATA_WIDTH(32)) RISCV_Core (
        .clk(clk),
        .reset(reset),
        .is_jump(is_jump), // 
        // fetch     
        .fetch_addr(bus_fetch_addr),
        .instruction(bus_instruction),
        .stall_out(stall),
        .buffer_instruction(buffer_instruction),
        // MEM
        .data_addr(bus_data_addr),
        .mem_we(bus_we),
        .mem_be(bus_be),
        .write_data(bus_write_data),
        .ram_data(bus_read_data),
        
        .test(tester),
        .test2(tester2),
        .test3(tester3),
        .test4(tester4),
        .test5(tester5),
        .test6(tester6),
        .test7(tester7),
        .test8(tester8),
        .test9(tester9)
    );

    // 2. Instantiate the RAM
    Ram #(.ADDR_WIDTH(10), .DATA_WIDTH(32),
          .INIT_FILE("program.hex"), .LED_WORD_INDEX(128)) System_Memory (
        .clk(clk),
        // Connect the Instruction Port
        .instruction(bus_fetch_addr),
        .ins_out(bus_instruction),
        .buffer_instruction(buffer_instruction),
        .stall(stall),
        .is_jump(is_jump),
        // Connect the Data Port
        .addr(bus_data_addr),
        .we(bus_we),
        .be(bus_be),
        .din(bus_write_data),
        .dout(bus_read_data),
        .led_word(led_word)
    );

endmodule
