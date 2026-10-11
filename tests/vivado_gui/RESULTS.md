# GUI verification results — September 19, 2026

Target: xc7a35tcpg236-1, Vivado 2023.1, 10.000 ns clock, boardless
out-of-context implementation of `cpu_gui_top`. MUL remains disabled.

## Observed results

| Check | Result |
| --- | --- |
| Original Verilator regression | 444 / 444 checks pass |
| Expanded independent reference regression | 928 programs, 17,773 retired instructions, 331,137 checks pass |
| XSim behavioral simulation | Two runs; 53 checked stores and 196 cycles per run; pass |
| Routed static setup timing | +0.177 ns worst slack; zero failing endpoints |
| Routed static hold timing | +0.071 ns worst slack; zero failing endpoints |
| Routed pulse-width timing | +3.750 ns worst slack; zero failing endpoints |
| Unconstrained internal endpoints | Zero |
| XSim post-implementation timing | Both runs produce correct stores, but six timing violations; not a clean pass |

The final timing simulation successfully annotated the implementation SDF.
Timing checks were not disabled. `verify_project.tcl` intentionally fails when
the simulator logs any timing violation, even if the CPU result checker prints
`CPU_100MHZ_PASS`.

## Remaining issue

All six warnings concern `core/EX_MEM_Pipe/ALU_result_out_reg[7]`. The first run
reports a hold violation at 436.967 ns, then setup and hold violations at
1117.040 ns. The second run repeats these three warnings at 2596.967 ns and
3277.040 ns. Correct observed stores do not establish that these violations
are harmless. The discrepancy between passing static timing and the annotated
simulation remains unresolved; do not describe this as a fully verified
100 MHz CPU yet.

The worst static setup path is different: RAM read-data bit 31 to the PC
register's clock enable, through load/forwarding/branch logic. Its data delay
is 9.545 ns, including 7.189 ns of routing. This describes this specific routed
verification design, not every program image or future board implementation.

## Evidence

- `timing_100mhz.rpt`: setup, hold, pulse-width and constraint coverage.
- `critical_paths.rpt`: detailed longest paths.
- `project/cpu_100mhz.sim/sim_1/behav/xsim/simulate.log`: behavioral checks.
- `project/cpu_100mhz.sim/sim_1/impl/timing/xsim/simulate.log`: correct stores and timing violations.
- `project/cpu_100mhz.sim/sim_1/impl/timing/xsim/elaborate.log`: successful SDF annotation.
- `verify.log`: automated verification rejects the timing run.
The three `.rpt` files are checked in as selected recorded evidence. The
generated `project/` directory and logs are excluded from version control;
running `verify_project.ps1` regenerates them. Local rollback snapshots are
also excluded from this source publication.

The project and testbench are ready to reproduce these results through the GUI;
resolving the remaining timing violations is additional CPU timing work.
