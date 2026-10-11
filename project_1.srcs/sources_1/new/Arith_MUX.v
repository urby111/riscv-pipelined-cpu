module Arith_MUX(
    input [31:0] rs1_data,
    input [31:0] rs2_data,
    input [31:0] PC_in,
    input [31:0] mem_data,
    input [31:0] wb_data,
    input [31:0] imm_data,
    
    input [1:0] fwd_sel_a,
    input [1:0] fwd_sel_b,
    input       alu_src,
    input       is_lui,
    
    output [31:0] alu_in_a,
    output [31:0] alu_in_b,
    output [31:0] rs2_out
);
    // Input A Mux (4-to-1)
    assign alu_in_a = (is_lui) ? 32'b0:
                      (fwd_sel_a == 2'b01) ? mem_data :
                      (fwd_sel_a == 2'b11) ? PC_in    :
                      (fwd_sel_a == 2'b10) ? wb_data  : rs1_data;

    // Input B Mux (Forwarding + ALU_Src)
    wire [31:0] temp_rs2;
    assign temp_rs2 = (fwd_sel_b == 2'b01) ? mem_data :
                      (fwd_sel_b == 2'b10) ? wb_data  : rs2_data;
                          
    assign alu_in_b = (alu_src) ? imm_data : temp_rs2;
    
    assign rs2_out = temp_rs2;
endmodule