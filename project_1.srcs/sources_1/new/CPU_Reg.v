module CPU_Reg#(
    parameter ADDR_WIDTH = 5, 
    parameter DATA_WIDTH = 32  
)(
    input clk,            // Need a clock for writing
    input reset,
    input reg_write,      // Control signal: Enable writing?
    input [4:0] rs1,      // Source 1 Address
    input [4:0] rs2,      // Source 2 Address
    input [4:0] rd,       // Destination Address
    input [31:0] rd_in,   // Data to be written
    
    output reg [31:0] rs1_out,
    output reg [31:0] rs2_out
);
    
    // Register array
    reg [DATA_WIDTH-1:0] CPU_reg [2**ADDR_WIDTH-1:0];
    integer i;

    // --- WRITE & RESET LOGIC (Sequential) ---
    always @(posedge clk) begin
        if (reset) begin
            // Force every register to zero on reset
            for (i = 0; i < 2**ADDR_WIDTH; i = i + 1) begin
                CPU_reg[i] <= 32'b0;
            end
        end else if (reg_write && rd != 5'b0) begin
            // Use Byte Enable to mask the write for sub-word instructions (sb, sh)
            CPU_reg[rd]<= rd_in;
        end
    end

    // --- READ LOGIC (Combinational) ---
    // In RISC-V, Register 0 is hardwired to 0
    always @(*) begin
        rs1_out = (rs1 == 5'b0) ? 32'b0 : CPU_reg[rs1];
        rs2_out = (rs2 == 5'b0) ? 32'b0 : CPU_reg[rs2];
    end

endmodule