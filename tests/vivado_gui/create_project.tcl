# Open this .tcl with Tools > Run Tcl Script, or open the generated .xpr directly.
set task_dir [file dirname [file normalize [info script]]]
set root [file normalize [file join $task_dir ../..]]
set rtl [file join $root project_1.srcs/sources_1/new]
set project_file [file join $task_dir project cpu_100mhz.xpr]
if {[file exists $project_file]} {
    open_project $project_file
} else {
    create_project cpu_100mhz [file join $task_dir project] -part xc7a35tcpg236-1
}
set_param general.maxThreads 2
foreach module {
    main_cpu Ram Arith_Unit ALU_Decoder Arith_MUX Branch_MUX Control_Unit
    CPU_Reg EX_MEM_Stage_Reg Forwarding_Unit Hazard_Buffer ID_EX_Stage_Reg
    Immediate_Generator Instruction_Reg MEM_WB_Stage_Reg Mem_Fwd_MUX PC WriteBack_Aligner
} {
    add_files -norecurse [file join $rtl $module.v]
}
add_files -norecurse [file join $task_dir cpu_gui_top.v]
add_files -norecurse [file join $task_dir gui_program.mem]
set_property top cpu_gui_top [get_filesets sources_1]
add_files -fileset constrs_1 -norecurse [file join $task_dir clock_100mhz.xdc]
add_files -fileset constrs_1 -norecurse [file join $task_dir physical.xdc]
set_property used_in_synthesis false [get_files physical.xdc]
add_files -fileset sim_1 -norecurse [file join $task_dir tb_cpu_100mhz.sv]
add_files -fileset sim_1 -norecurse [file join $task_dir expected_stores.vh]
set_property include_dirs [list $task_dir] [get_filesets sim_1]
set_property top tb_cpu_100mhz [get_filesets sim_1]
set_property xsim.simulate.runtime all [get_filesets sim_1]
set_property target_simulator XSim [current_project]
# Boardless implementation: no I/O buffers or physical board pin assignments.
# This is the same OOC timing method as the previous 100 MHz characterization.
set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value {-mode out_of_context} -objects [get_runs synth_1]
set_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
puts "GUI_PROJECT_READY $project_file"
