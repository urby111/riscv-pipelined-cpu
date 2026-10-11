set task_dir [file dirname [file normalize [info script]]]
source [file join $task_dir create_project.tcl]
proc require_sim_pass {mode} {
    global task_dir
    set path [file join $task_dir project cpu_100mhz.sim sim_1 $mode xsim simulate.log]
    set stream [open $path r]
    set log [read $stream]
    close $stream
    if {[string first "CPU_100MHZ_PASS:" $log] < 0 || [regexp -nocase {fatal:|timing violation|error:} $log]} {
        error "Simulation did not pass cleanly; see $path"
    }
    if {$mode eq "impl/timing"} {
        set stream [open [file join [file dirname $path] elaborate.log] r]
        set elaboration [read $stream]
        close $stream
        if {[string first "SDF backannotation was successful" $elaboration] < 0} {
            error "Cannot verify timing simulation: successful SDF annotation was not recorded"
        }
    }
}
launch_simulation -mode behavioral
close_sim
require_sim_pass behav
if {[get_property PROGRESS [get_runs synth_1]] ne "0%"} { reset_run synth_1 }
launch_runs synth_1 -jobs 2
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} { error "Synthesis failed" }
launch_runs impl_1 -to_step route_design -jobs 2
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] ne "100%"} { error "Implementation failed" }
open_run impl_1
report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -file [file join $task_dir timing_100mhz.rpt]
report_timing -delay_type max -max_paths 10 -file [file join $task_dir critical_paths.rpt]
report_drc -file [file join $task_dir drc.rpt]
set setup_slack [get_property SLACK [get_timing_paths -delay_type max -max_paths 1]]
set hold_slack [get_property SLACK [get_timing_paths -delay_type min -max_paths 1]]
puts "GUI_TIMING_RESULT setup_ns=$setup_slack hold_ns=$hold_slack"
launch_simulation -mode post-implementation -type timing
close_sim
require_sim_pass impl/timing
if {$setup_slack < 0 || $hold_slack < 0} { error "GUI verification design does not meet 100 MHz timing" }
close_project
