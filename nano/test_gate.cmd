@echo off
setlocal
cd /d "%~dp0"
call toolchain.cmd
if errorlevel 1 exit /b 1
if not exist build\cpu_ram_led.json (
    echo Run build.cmd first.
    exit /b 1
)
yosys -Q -T -l build/gate_netlist.log -p "read_json build/cpu_ram_led.json; write_verilog -noattr build/cpu_ram_led_synth.v"
if errorlevel 1 exit /b 1
iverilog -g2012 -s nano_gate_tb -o build/nano_gate_tb.vvp build/cpu_ram_led_synth.v tests/nano_gate_tb.sv "%OSS_CAD_SUITE%\share\yosys\gowin\cells_sim.v"
if errorlevel 1 exit /b 1
vvp build/nano_gate_tb.vvp
exit /b %errorlevel%
