module main_cpu#(
    parameter ADDR_WIDTH = 10,
    parameter DATA_WIDTH = 32
)(
    input clk,
    input reset,
    
    // --- Top-Level Control ---
    output stall_out,            // stall for mem forwarding
    output is_jump,
    
    // --- Instruction Memory Interface ---
    output [ADDR_WIDTH-3:0] fetch_addr, 
    input  [DATA_WIDTH-1:0] instruction,
    
    // --- Data Memory Interface ---
    output [ADDR_WIDTH-3:0] data_addr,   // address to ram
    output                  mem_we,      // tell whether to write or not
    output [3:0]            mem_be,      // how many bytes does mem need
    output [DATA_WIDTH-1:0] write_data,  // data to be written
    output [DATA_WIDTH-1:0] buffer_instruction, 
    input  [DATA_WIDTH-1:0] ram_data,    // data recieved from ram to mem
    
    // --- Debug/Test Ports ---
    output [DATA_WIDTH-1:0] test,        
    output [DATA_WIDTH-1:0] test2,
    output [DATA_WIDTH-1:0] test3,       
    output [DATA_WIDTH-1:0] test4,       
    output [DATA_WIDTH-1:0] test5,
    output [DATA_WIDTH-1:0] test6,       
    output [DATA_WIDTH-1:0] test7,       
    output [DATA_WIDTH-1:0] test8,
    output [DATA_WIDTH-1:0] test9        
);

    // =========================================================================
    // 1. WIRE DECLARATIONS (Organized by Pipeline Stage)
    // =========================================================================

    // --- Instruction Fetch (IF) Wires ---
    wire [ADDR_WIDTH-1:0] if_pc; 
    wire [ADDR_WIDTH-1:0] if_pc_hazard_buffer; 
    wire [ADDR_WIDTH-1:0] if_pc_plus_4; 
    wire [ADDR_WIDTH-1:0] if_pc_next;
    wire [DATA_WIDTH-1:0] if_instruction;
    wire [DATA_WIDTH-1:0] if_jal_target;
    // Valid bits carry bubbles; instruction/data buses are never reset on flush.
    // Decode validity follows the synchronous instruction-memory read enable.
    reg id_valid, ex_valid, mem_valid, wb_valid;

    // --- Instruction Decode (ID) Wires ---
    wire [31:0] id_imm_raw;    
    wire [3:0]  id_mem_be;      
    wire [3:0]  id_alu_op;      
    wire [31:0] id_rs1_raw;
    wire [31:0] id_rs2_raw;
    wire [31:0] id_rs1_fwd;     // Internal WB->ID forwarding
    wire [31:0] id_rs2_fwd;     // Internal WB->ID forwarding
    
    wire id_reg_write, id_mem_write, id_mem_read;
    wire id_branch, id_jump, id_mem_to_reg, id_alu_src;
    wire id_reg_read, id_jump_back, id_is_store;
    wire id_is_auipc, id_is_lui;
    wire id_arith_sel = 1'b0; // Legacy pipeline control; not used by this ALU.

    wire [6:0] id_opcode = if_instruction[6:0];
    wire [2:0] id_func3  = if_instruction[14:12];
    wire [6:0] id_func7  = if_instruction[31:25];
    wire [4:0] id_rs1_addr = id_reg_read ? if_instruction[19:15] : 5'd0;
    wire id_uses_rs2 = id_reg_read &&
                       ((id_opcode == 7'h33) || (id_opcode == 7'h23) || (id_opcode == 7'h63));
    wire [4:0] id_rs2_addr = id_uses_rs2 ? if_instruction[24:20] : 5'd0;

    // --- Execute (EX) Wires ---
    wire [31:0] ex_pc;  
    wire [31:0] ex_instruction;    
    wire [31:0] ex_rs1_data;
    wire [31:0] ex_rs2_data;
    wire [31:0] ex_imm; 
    wire [4:0]  ex_rs1_addr, ex_rs2_addr, ex_rd_addr;
    wire [3:0]  ex_mem_be;      
    wire [2:0]  ex_func3;
    wire [3:0]  ex_alu_op; 

    wire ex_reg_write, ex_mem_write, ex_mem_read;
    wire ex_branch, ex_jump, ex_mem_to_reg;
    wire ex_alu_src, ex_reg_read, ex_jump_back;
    wire ex_arith_sel, ex_is_auipc, ex_is_lui;
    wire ex_reg_write_raw, ex_mem_write_raw, ex_mem_read_raw;
    wire ex_branch_raw, ex_jump_back_raw;
    assign ex_reg_write = ex_valid && ex_reg_write_raw;
    assign ex_mem_write = ex_valid && ex_mem_write_raw;
    assign ex_mem_read = ex_valid && ex_mem_read_raw;
    assign ex_branch = ex_valid && ex_branch_raw;
    assign ex_jump_back = ex_valid && ex_jump_back_raw;

    wire [31:0] ex_alu_in_a, ex_alu_in_b;
    wire [31:0] ex_alu_result;
    wire [31:0] ex_rs2_fwd;     // Output from Arith Mux
    wire        ex_alu_zero;
    wire        ex_take_branch; // Output from Branch MUX
    wire        ex_redirect = ex_jump_back | ex_take_branch;
    wire [31:0] ex_write_result = (ex_jump | ex_jump_back) ? (ex_pc + 32'd4) : ex_alu_result;

    // --- Memory (MEM) Wires ---
    wire [31:0] mem_instruction;   
    wire [31:0] mem_rs2_data;
    wire [31:0] mem_alu_result;
    wire [4:0]  mem_rd_addr, mem_rs1_addr, mem_rs2_addr;
    wire [3:0]  mem_be_raw;
    wire [2:0]  mem_func3;

    wire mem_reg_write, mem_read_en, mem_to_reg_ctrl;
    wire [31:0] mem_fwd_data_out;
    wire mem_write_en;

    // --- Write-Back (WB) Wires ---
    wire [31:0] wb_alu_result;
    wire [31:0] wb_aligned_load_data;
    wire [31:0] wb_final_data;
    wire [4:0]  wb_rd_addr;
    wire [2:0]  wb_func3;
    wire        wb_reg_write, wb_mem_to_reg;
    wire wb_reg_write_raw;
    assign wb_reg_write = wb_valid && wb_reg_write_raw;

    // --- Hazard & Forwarding Wires ---
    reg [1:0]   fwd_sel_a;
    reg [1:0]   fwd_sel_b;
    wire        hz_stall;
    wire        fwd_mem_control; // Undeclared in original code, explicit here

    // --- Unused/Legacy Wires (Kept to maintain exact structural parity) ---
    wire [31:0] corrected_instruction;
    wire [31:0] w_alu_result_raw; 
    wire [31:0] wb_ld_data;
    wire [31:0] wb_insr;   
    wire [31:0] old_instruction;

    // Decide forwarding while the consumer is in decode, then register the
    // selection alongside its operands. Today's EX/MEM producers will be in
    // MEM/WB when this consumer executes. No extra pipeline cycle is added.
    // Raw source fields are safe here: immediate/LUI/PC selection overrides
    // unused operands, while the separate hazard unit masks unused sources.
    always @(posedge clk) begin
        if (reset) begin
            fwd_sel_a <= 2'b00;
            fwd_sel_b <= 2'b00;
        end else begin
            if (id_jump || id_is_auipc)
                fwd_sel_a <= 2'b11;
            else if (ex_reg_write && ex_rd_addr != 0 && ex_rd_addr == if_instruction[19:15])
                fwd_sel_a <= ex_mem_read ? 2'b00 : 2'b01;
            else if (mem_reg_write && mem_rd_addr != 0 && mem_rd_addr == if_instruction[19:15])
                fwd_sel_a <= 2'b10;
            else
                fwd_sel_a <= 2'b00;

            if (ex_reg_write && ex_rd_addr != 0 && ex_rd_addr == if_instruction[24:20])
                fwd_sel_b <= ex_mem_read ? 2'b00 : 2'b01;
            else if (mem_reg_write && mem_rd_addr != 0 && mem_rd_addr == if_instruction[24:20])
                fwd_sel_b <= 2'b10;
            else
                fwd_sel_b <= 2'b00;
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            id_valid <= 1'b0;
            ex_valid <= 1'b0;
            mem_valid <= 1'b0;
            wb_valid <= 1'b0;
        end else begin
            if (is_jump) id_valid <= 1'b0;
            else if (!stall_out) id_valid <= 1'b1;
            ex_valid <= id_valid && !hz_stall && !ex_redirect;
            mem_valid <= ex_valid;
            wb_valid <= mem_valid;
        end
    end

    // =========================================================================
    // 2. TOP-LEVEL ASSIGNMENTS & DEBUG PORTS
    // =========================================================================

    assign stall_out   = hz_stall && !ex_redirect;
    wire id_take_jump = id_valid && id_jump && !hz_stall;
    assign is_jump     = id_take_jump | ex_redirect;
    assign mem_we      = mem_write_en && !reset;

    assign test        = wb_final_data;   
    assign test2       = instruction;
    assign test3       = if_pc;
    assign test4       = ex_take_branch;
    assign test5       = is_jump;
    assign test6       = hz_stall;
    assign test7       = ex_jump_back;
    assign test8       = if_pc_hazard_buffer;
    assign test9       = if_pc_next;

    // =========================================================================
    // 3. INSTRUCTION FETCH (IF) STAGE
    // =========================================================================

    assign if_instruction = instruction;
    assign if_pc_plus_4   = if_pc + 4;
    assign if_jal_target  = if_pc_hazard_buffer + id_imm_raw; 
    assign fetch_addr     = if_pc[ADDR_WIDTH-1:2];
    assign if_pc_next      = ex_take_branch ? (ex_imm + ex_pc) :
                             ex_jump_back ? (ex_alu_result & 32'hfffffffe) :
                             id_take_jump ? if_jal_target :
                             hz_stall ? if_pc : if_pc_plus_4;

    Hazard_Buffer #(.ADDR_WIDTH(ADDR_WIDTH)) pc_reg (
        .clk    (clk),
        .reset  (reset),
        .stall  (stall_out),
        .d_in   (if_pc),               
        .pc_out (if_pc_hazard_buffer)  
    );

    PC #(.ADDR_WIDTH(ADDR_WIDTH)) program_counter (
        .clk         (clk),
        .stall       (hz_stall),
        .reset       (reset),
        .is_jump     (id_take_jump),
        .alu_insr    (ex_alu_result),
        .branch_insr (ex_imm + ex_pc),
        .is_r_jump   (ex_jump_back),
        .is_branch   (ex_take_branch),
        .jump_insr   (if_jal_target[ADDR_WIDTH-1:0]),
        .d_in        (if_pc_plus_4),     
        .pc_out      (if_pc)             
    );

    Instruction_Reg buffer(
        .clk   (clk),
        .reset (reset),
        .stall (stall_out),
        .din   (if_instruction),     
        .pcout (buffer_instruction) 
    );

    // =========================================================================
    // 4. INSTRUCTION DECODE (ID) STAGE
    // =========================================================================

    CPU_Reg register_file (
        .clk        (clk),
        .reset      (reset),
        .reg_write  (wb_reg_write), 
        .rs1        (if_instruction[19:15]),
        .rs2        (if_instruction[24:20]),
        .rd         (wb_rd_addr),    
        .rd_in      (wb_final_data), 
        .rs1_out    (id_rs1_raw),         
        .rs2_out    (id_rs2_raw)          
    );

    // Internal WB->ID Forwarding Logic
    assign id_rs1_fwd = (wb_reg_write && (wb_rd_addr != 0) && (wb_rd_addr == if_instruction[19:15])) 
                        ? wb_final_data : id_rs1_raw;

    assign id_rs2_fwd = (wb_reg_write && (wb_rd_addr != 0) && (wb_rd_addr == if_instruction[24:20])) 
                        ? wb_final_data : id_rs2_raw;

    Control_Unit controller (
        .clk         (clk),
        .reset       (reset),
        .instruction (if_instruction), 
        .reg_write   (id_reg_write),
        .mem_write   (id_mem_write),
        .mem_read    (id_mem_read),
        .branch      (id_branch),
        .jump        (id_jump),
        .mem_to_reg  (id_mem_to_reg),
        .alu_src     (id_alu_src),
        .reg_read    (id_reg_read),
        .jump_back   (id_jump_back),
        .mem_be      (id_mem_be),
        .is_store    (id_is_store),
        .is_auipc    (id_is_auipc),
        .is_lui      (id_is_lui)
    );

    Immediate_Generator ImmGen (
        .instruction (if_instruction), 
        .imm_out     (id_imm_raw)        
    );

    ALU_Decoder Control_Decoder (
        .opcode (id_opcode),
        .func3  (id_func3),
        .func7  (id_func7),
        .out    (id_alu_op)       
    );

    // =========================================================================
    // 5. ID / EX PIPELINE REGISTER
    // =========================================================================

    ID_EX_Stage_Reg ID_EX_Pipe (
        .clk            (clk),
        .reset          (reset),
        .stall          (hz_stall | ex_jump_back | ex_take_branch),
        
        // Data Inputs
        .insr_in        (if_instruction),
        .be_in          (id_mem_be),
        .rs1_in         (id_rs1_fwd),
        .rs2_in         (id_rs2_fwd),
        .imm_in         (id_imm_raw),
        .rd_addr_in     (if_instruction[11:7]),
        .rs1_addr_in    (id_rs1_addr),
        .rs2_addr_in    (id_rs2_addr),
        // Explicit extension also prevents undriven upper bits in XSim.
        .PC_in          ({{(32-ADDR_WIDTH){1'b0}}, if_pc_hazard_buffer}),
        
        // Control Inputs
        .is_lui_in      (id_is_lui),
        .is_auipc_in    (id_is_auipc),
        .r_jump_in      (id_jump_back),
        .func3_in       (id_func3),
        .reg_write_in   (id_reg_write),
        .mem_write_in   (id_mem_write),
        .mem_read_in    (id_mem_read),
        .branch_in      (id_branch),
        .jump_in        (id_jump),
        .mem_to_reg_in  (id_mem_to_reg),
        .alu_src_in     (id_alu_src),
        .alu_op_in      (id_alu_op),
        .arith_sel_in   (id_arith_sel),
        .reg_read_in    (id_reg_read),
        .jump_back_in   (id_jump_back),

        // Data Outputs
        .is_auipc_out   (ex_is_auipc),
        .is_lui_out     (ex_is_lui),
        .r_jump_out     (ex_jump_back_raw),
        .PC_out         (ex_pc), 
        .insr_out       (ex_instruction),
        .be_out         (ex_mem_be),
        .rs1_out        (ex_rs1_data),
        .rs2_out        (ex_rs2_data),
        .imm_out        (ex_imm),
        .rd_addr_out    (ex_rd_addr),
        .rs1_addr_out   (ex_rs1_addr),
        .rs2_addr_out   (ex_rs2_addr),

        // Control Outputs
        .func3_out      (ex_func3),
        .reg_write_out  (ex_reg_write_raw),
        .mem_write_out  (ex_mem_write_raw),
        .mem_read_out   (ex_mem_read_raw),
        .branch_out     (ex_branch_raw),
        .jump_out       (ex_jump),
        .mem_to_reg_out (ex_mem_to_reg),
        .alu_src_out    (ex_alu_src),
        .alu_op_out     (ex_alu_op),
        .arith_sel_out  (ex_arith_sel),
        .reg_read_out   (ex_reg_read),
        .jump_back_out  () // r_jump_out above drives the same legacy control.
    );

    // =========================================================================
    // 6. EXECUTE (EX) STAGE & FORWARDING UNIT
    // =========================================================================

    Forwarding_Unit FWD_BRAIN (
        .ex_rs1        (ex_rs1_addr),
        .ex_rs2        (ex_rs2_addr),
        .mem_rd        (mem_rd_addr),
        .wb_rd         (wb_rd_addr),
        .mem_reg_write (mem_reg_write),
        .wb_reg_write  (wb_reg_write),
        
        .id_rs1        (id_valid ? id_rs1_addr : 5'd0),
        .id_rs2        (id_valid ? id_rs2_addr : 5'd0),
        .ex_rd         (ex_rd_addr),
        .ex_mem_read   (ex_mem_read),
        .is_jump       (ex_jump | ex_is_auipc),
        .mem_mem_read  (mem_read_en),
        .id_mem_write  (id_is_store),   
        .mem_rs2       (mem_rs2_addr),          
        
        .fwd_a         (), // Registered one stage earlier above.
        .fwd_b         (),
        .stall         (hz_stall),
        .fwd_mem       (fwd_mem_control)
    );

    Arith_MUX ALU_MUXES (
        .rs1_data  (ex_rs1_data),   
        .rs2_data  (ex_rs2_data),   
        .mem_data  (mem_alu_result), 
        .PC_in     (ex_pc),
        .wb_data   (wb_final_data), 
        .imm_data  (ex_imm),    
        .fwd_sel_a (fwd_sel_a),    
        .fwd_sel_b (fwd_sel_b),    
        .alu_src   (ex_alu_src),   
        .is_lui    (ex_is_lui),
        .alu_in_a  (ex_alu_in_a),     
        .alu_in_b  (ex_alu_in_b),      
        .rs2_out   (ex_rs2_fwd)
    );

    Arith_Unit ALU (
        .a        (ex_alu_in_a),       
        .b        (ex_alu_in_b),       
        .alu_ctrl (ex_alu_op), 
        .d        (ex_alu_result),            
        .zero     (ex_alu_zero)            
    );

    Branch_MUX pc_ctrl (
        .func3       (ex_func3),
        .branch_en   (ex_branch),
        .rs1         (ex_alu_in_a),
        .rs2         (ex_rs2_fwd),
        .take_branch (ex_take_branch)
    );

    // =========================================================================
    // 7. EX / MEM PIPELINE REGISTER
    // =========================================================================

    EX_MEM_Stage_Reg EX_MEM_Pipe (
        .clk            (clk),
        .reset          (reset),
        .stall          (1'b0),
        
        // Inputs
        .insr_in        (ex_instruction),
        .rs2_in         (ex_rs2_fwd),
        .be_in          (ex_mem_be),
        .func3_in       (ex_func3),
        .rs1_addr_in    (ex_rs1_addr),
        .rs2_addr_in    (ex_rs2_addr),
        .mem_to_reg_in  (ex_mem_to_reg),
        .rd_addr_in     (ex_rd_addr),    
        .reg_write_in   (ex_reg_write),  
        .mem_write_in   (ex_mem_write),  
        .mem_read_in    (ex_mem_read),   
        .ALU_result_in  (ex_write_result),
        
        // Outputs
        .insr_out       (mem_instruction),
        .rs2_out        (mem_rs2_data),
        .be_out         (mem_be_raw),
        .func3_out      (mem_func3),
        .mem_to_reg_out (mem_to_reg_ctrl),
        .rd_addr_out    (mem_rd_addr),      
        .reg_write_out  (mem_reg_write),   
        .mem_write_out  (mem_write_en),
        .mem_read_out   (mem_read_en),      
        .ALU_result_out (mem_alu_result),   
        .rs1_addr_out   (mem_rs1_addr),
        .rs2_addr_out   (mem_rs2_addr)
    );

    // =========================================================================
    // 8. MEMORY (MEM) STAGE
    // =========================================================================

    assign data_addr  = mem_alu_result[ADDR_WIDTH-1:2];
    assign mem_be     = mem_be_raw << mem_alu_result[1:0];
    // Both store data and byte enables use the original byte offset, once.
    assign write_data = mem_fwd_data_out << {mem_alu_result[1:0], 3'b000};

    Mem_Fwd_MUX my_mem_fwd_mux (
        .ex_mem_rs2_data (mem_rs2_data), 
        .wb_data         (wb_final_data),
        .fwd_mem         (fwd_mem_control),              
        .store_data_out  (mem_fwd_data_out)        
    );

    // =========================================================================
    // 9. MEM / WB PIPELINE REGISTER
    // =========================================================================

    MEM_WB_Stage_Reg MEM_WB_Pipe (
        .clk            (clk),
        .reset          (reset),
        
        // Inputs
        .insr_in        (mem_instruction),
        .LD_result_in   (32'd0), // RAM itself registers load data on this edge.
        .func3_in       (mem_func3),
        .rd_addr_in     (mem_rd_addr),    
        .reg_write_in   (mem_reg_write),  
        .mem_to_reg_in  (mem_read_en),
        .ALU_result_in  (mem_alu_result), 
        
        // Outputs
        .insr_out       (),
        .LD_result_out  (),
        .func3_out      (wb_func3),
        .rd_addr_out    (wb_rd_addr),
        .reg_write_out  (wb_reg_write_raw),
        .mem_to_reg_out (wb_mem_to_reg),
        .ALU_result_out (wb_alu_result)
    );

    // =========================================================================
    // 10. WRITE-BACK (WB) STAGE
    // =========================================================================

    WriteBack_Aligner wb_unit (
        .mem_read_data  (ram_data),       
        .addr_offset    (wb_alu_result[1:0]),
        .load_type      (wb_func3),         
        .is_load        (wb_mem_to_reg),         
        .wb_data        (wb_aligned_load_data)       
    );

    // The Write-Back Mux
    assign wb_final_data = (wb_mem_to_reg) ? wb_aligned_load_data : wb_alu_result;

endmodule
