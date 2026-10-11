// Bound to the CPU by the performance regression. Payload values are allowed
// to be stale/arbitrary for invalid slots; architectural side effects are not.
module verify_validity(
    input clk, reset, ex_valid, mem_valid, wb_valid,
    input ex_reg_write, ex_mem_write, ex_mem_read, ex_redirect,
    input mem_we, mem_reg_write, wb_reg_write
);
    always @(posedge clk) if (!reset) begin
        if (!ex_valid && (ex_reg_write || ex_mem_write || ex_mem_read || ex_redirect))
            $fatal(1, "Invalid EX slot has a side effect");
        if (!mem_valid && (mem_we || mem_reg_write))
            $fatal(1, "Invalid MEM slot has a side effect");
        if (!wb_valid && wb_reg_write)
            $fatal(1, "Invalid WB slot writes a register");
    end
endmodule

bind main_cpu verify_validity validity_monitor(
    .clk(clk), .reset(reset), .ex_valid(ex_valid), .mem_valid(mem_valid),
    .wb_valid(wb_valid), .ex_reg_write(ex_reg_write), .ex_mem_write(ex_mem_write),
    .ex_mem_read(ex_mem_read), .ex_redirect(ex_redirect), .mem_we(mem_we),
    .mem_reg_write(mem_reg_write), .wb_reg_write(wb_reg_write)
);
