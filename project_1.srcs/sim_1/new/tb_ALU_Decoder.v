`timescale 1ns / 1ps

module tb_ALU_Decoder;

    // --- Inputs to UUT ---
    reg [6:0] opcode;
    reg [2:0] func3;
    reg [6:0] func7;

    // --- Outputs from UUT ---
    wire [3:0] out;

    // Internal variables for testing
    reg [31:0] mem [0:6];
    reg [31:0] instruction;
    integer i;

    // --- Instantiate the Unit Under Test (UUT) ---
    ALU_Decoder uut (
        .opcode(opcode),
        .func3(func3),
        .func7(func7),
        .out(out)
    );

    initial begin
        // 1. Initialize the machine code memory array
        mem[0] = 32'h00452583; // LW
        mem[1] = 32'h00B506B3; // ADD
        mem[2] = 32'h00B6A423; // SW
        mem[3] = 32'h00059463; // BNE
        mem[4] = 32'h0180006F; // JAL
        mem[5] = 32'h00158593; // ADDI
        mem[6] = 32'h00000033; // NOP (ADD x0, x0, x0)

        // Set up the console output formatting
        $display("=================================================================");
        $display(" Instruction | Opcode  | func3 |  func7  | ALU_CTRL Out | Hex Out");
        $display("=================================================================");

        // 2. Loop through the array and test each instruction
        for (i = 0; i < 7; i = i + 1) begin
            instruction = mem[i];

            // Slice the 32-bit instruction into its specific RV32I fields
            opcode = instruction[6:0];
            func3  = instruction[14:12];
            func7  = instruction[31:25];

            // Wait 10ns for the combinational logic inside ALU_Decoder to settle
            #10;

            // Print the current state to the console
            $display("  0x%08X | %b |  %b  | %b |     %b     |   0x%01X", 
                     instruction, opcode, func3, func7, out, out);
        end

        $display("=================================================================");
        $finish; // End simulation
    end

endmodule
