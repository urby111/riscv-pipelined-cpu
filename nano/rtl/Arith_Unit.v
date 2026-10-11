module Arith_Unit(
    input  [31:0] a,
    input  [31:0] b,
    input  [3:0]  alu_ctrl, // Driven by the ALU Decoder
    output reg [31:0] d,
    output        zero
    );

    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b0001;
    localparam ALU_SLL  = 4'b0010;
    localparam ALU_SLT  = 4'b0011;
    localparam ALU_SLTU = 4'b0100;
    localparam ALU_XOR  = 4'b0101;
    localparam ALU_SRL  = 4'b0110;
    localparam ALU_SRA  = 4'b0111;
    localparam ALU_OR   = 4'b1000;
    localparam ALU_AND  = 4'b1001;

    always @(*) begin
        case(alu_ctrl)
            ALU_ADD:  d = a + b;
            ALU_SUB:  d = a - b;
            ALU_SLL:  d = a << b[4:0];
            ALU_SLT:  d = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            ALU_SLTU: d = (a < b) ? 32'd1 : 32'd0;
            ALU_XOR:  d = a ^ b;
            ALU_SRL:  d = a >> b[4:0];
            ALU_SRA:  d = $signed(a) >>> b[4:0];
            ALU_OR:   d = a | b;
            ALU_AND:  d = a & b;
            default:  d = 32'h0;
        endcase
    end

    assign zero = (d == 32'b0);
endmodule
