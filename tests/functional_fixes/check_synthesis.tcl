# Syntax/elaboration/synthesis sanity only. Timing optimization is a later task.
set task_dir [file dirname [file normalize [info script]]]
set project_dir [file normalize [file join $task_dir ../..]]
set source_dir [file join $project_dir project_1.srcs/sources_1/new]
set_param general.maxThreads 2
create_project -in_memory -part xc7a35tcpg236-1
foreach module {
    main main_cpu Ram Arith_Unit ALU_Decoder Arith_MUX Branch_MUX Control_Unit
    CPU_Reg EX_MEM_Stage_Reg Forwarding_Unit Hazard_Buffer ID_EX_Stage_Reg
    Immediate_Generator Instruction_Reg MEM_WB_Stage_Reg Mem_Fwd_MUX PC WriteBack_Aligner
} {
    read_verilog [file join $source_dir $module.v]
}
synth_design -top main -part xc7a35tcpg236-1 -mode out_of_context
report_utilization -file [file join $task_dir build synthesis_utilization.rpt]
report_drc -file [file join $task_dir build synthesis_drc.rpt]
puts "FUNCTIONAL_FIXES_SYNTHESIS_PASS"
close_project
