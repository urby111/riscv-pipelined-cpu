create_clock -name clk -period 10.000 [get_ports clk]
# Boardless verification shell: timing of observation ports and the testbench
# reset source is unspecified. All internal CPU, RAM and monitor paths are timed.
set_false_path -from [get_ports reset]
set_false_path -to [get_ports {debug[*] observe_clk store_valid store_addr[*] store_be[*] store_data[*]}]
