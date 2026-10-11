# Vivado behavioral and timing verification

This boardless out-of-context design uses the current CPU/RAM RTL, a BUFG
clock wrapper, and a generated program with independent expected-store values.
It targets xc7a35tcpg236-1, Vivado 2023.1, and a 10 ns clock.

## Recreate the project

In Vivado, choose **Tools > Run Tcl Script** and select create_project.tcl.
The script creates project/cpu_100mhz.xpr using repository-relative sources,
constraints, program data, and testbench files. Generated project files are
excluded from Git. Open the generated project for subsequent GUI runs.

To regenerate the program and expected-store data with Python 3:

```powershell
python tests/vivado_gui/generate_program.py
```

The program performs arithmetic, branches, loads/stores, forwarding, jumps,
reset/startup, x0, and disabled-MUL checks. The testbench uses DUT observation
ports so it also works with the synthesized/implemented netlist.

## Run verification

From PowerShell at the repository root:

```powershell
.\tests\vivado_gui\verify_project.ps1 -Vivado 'C:\Xilinx\Vivado\2023.1\bin\vivado.bat'
```

Set -Vivado to your installation. This runs behavioral simulation,
synthesis, implementation, static timing reports, and post-implementation
timing simulation with SDF annotation. The runner requires correct checked
stores, successful SDF annotation, no simulator timing violations, and
nonnegative static setup/hold slack.

In the GUI, use **Run Simulation > Run Behavioral Simulation** first. Rerun
synthesis and implementation after RTL/program changes, then choose
**Run Simulation > Run Post-Implementation Timing Simulation**. Select
**Run All** until the result appears. CPU_100MHZ_PASS reports correct checked
stores; simulator warnings must also be inspected.

## Recorded status

The September 19, 2026 behavioral simulation passes two complete runs, each
with 53 checked stores over 196 cycles. Routed static timing passes at 100 MHz:
setup +0.177 ns, hold +0.071 ns, and no unconstrained internal endpoints.

Annotated timing simulation produces the correct checked stores but reports
six setup/hold violations at core/EX_MEM_Pipe/ALU_result_out_reg[7].
The verification runner rejects that result. This unresolved discrepancy is
documented in [RESULTS.md](RESULTS.md); this is not a clean timing-simulation
pass.

The checked-in timing/critical-path/DRC reports are selected recorded evidence.
Fresh simulator logs and generated netlists are written to the ignored project/
directory. External reset/observation paths are excluded because this is a
simulation interface with no board specification. The design does not generate
an Artix-7 board bitstream.
