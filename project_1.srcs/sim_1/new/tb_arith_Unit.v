`timescale 1ns / 1ps

module Arith_Unit_tb();

    // Inputs
    reg [31:0] a;
    reg [31:0] b;
    reg        arith_sel;
    reg [2:0]  sel;

    // Outputs
    wire [31:0] d;
    wire        zero;

    // Instantiate the Unit Under Test (UUT)
    Arith_Unit uut (
        .a(a), 
        .b(b), 
        .arith_sel(arith_sel), 
        .sel(sel), 
        .d(d), 
        .zero(zero)
    );

    // Helper task to make the test cases readable
    task check_alu(input [31:0] val_a, input [31:0] val_b, input [2:0] s, input a_s);
        begin
            a = val_a;
            b = val_b;
            sel = s;
            arith_sel = a_s;
            #10; // Wait 10ns for logic to settle
        end
    endtask

    initial begin
        // Initialize Inputs
        a = 0; b = 0; sel = 0; arith_sel = 0;

        // Wait for global reset
        #100;
        
        // --- TEST CASES ---

        // 1. Test ADD (10 + 5 = 15)
        check_alu(32'd10, 32'd5, 3'b000, 1'b0);

        // 2. Test SUB (10 - 5 = 5)
        check_alu(32'd10, 32'd5, 3'b000, 1'b1);

        // 3. Test SLL (Shift 1 left by 2 bits = 4)
        check_alu(32'h0000_0001, 32'd2, 3'b001, 1'b0);

        // 4. Test SLT (Is -5 < 10? Yes, should be 1)
        check_alu(32'hFFFF_FFFB, 32'd10, 3'b010, 1'b0);

        // 5. Test SLTU (Is -5 < 10 unsigned? No, -5 is a huge number unsigned)
        check_alu(32'hFFFF_FFFB, 32'd10, 3'b011, 1'b0);

        // 6. Test XOR (0xAA ^ 0xFF = 0x55)
        check_alu(32'h0000_00AA, 32'h0000_00FF, 3'b100, 1'b0);

        // 7. Test SRL (Logical shift right: 0x80000000 >> 1 = 0x40000000)
        check_alu(32'h8000_0000, 32'd1, 3'b101, 1'b0);

        // 8. Test SRA (Arithmetic shift right: 0x80000000 >>> 1 = 0xC0000000)
        check_alu(32'h8000_0000, 32'd1, 3'b101, 1'b1);

        // 9. Test OR (0x0F | 0xF0 = 0xFF)
        check_alu(32'h0000_000F, 32'h0000_00F0, 3'b110, 1'b0);

        // 10. Test AND (0xFF & 0x0F = 0x0F)
        check_alu(32'h0000_00FF, 32'h0000_000F, 3'b111, 1'b0);
        
        // 11. Test ZERO FLAG (5 - 5 = 0, zero should be 1)
        check_alu(32'd5, 32'd5, 3'b000, 1'b1);

        #50;
        $finish;
    end
      
endmodule