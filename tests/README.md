# CPU verification

Run from the repository root in PowerShell with Verilator, g++, and make
installed in WSL:

```powershell
wsl --exec bash tests/run_verilator.sh
wsl --exec bash tests/performance_100mhz/run_reference.sh
```

On Linux, invoke the scripts with bash directly. Verilator 5.020 was used for
the recorded results. The runners compile the active main CPU/RAM hierarchy
from project_1.srcs/sources_1/new/ and exit nonzero when a check fails.

The directed regression checks register/immediate arithmetic, x0, forwarding,
LUI/AUIPC, loads and stores at valid byte/halfword offsets, load dependencies,
all six branch conditions, backward branches, JAL/JALR links and flushing,
JALR bit-zero clearing, and reset startup. The recorded run passes 444 checks.

The independent reference suite checks instruction order, register writeback,
final register/memory state, and pipeline validity. It includes boundary-value
branch cases, dependencies, wrong-path side effects, and disabled MUL. The
recorded run passes 331,137 checks across 928 programs.

MUL is disabled in the published core. Historical MUL-enabled tests and source
rollback snapshots are not part of this repository's test specification.
These directed/reference tests are not a complete ISA compliance suite or a
formal proof. Misaligned accesses, traps, interrupts, privileged behavior,
self-modifying-code collisions, and external memory wait states are outside
the supported scope.

Outputs are written to ignored build/ directories. To save a waveform for
the directed regression:

```powershell
wsl --exec bash tests/run_verilator.sh +trace
```

Lint warnings are retained with -Wno-fatal; a passing simulation does not
mean warning-free lint.

Additional checks:

- [Independent reference model](performance_100mhz/README.md)
- [Vivado synthesis sanity check](functional_fixes/README.md)
- [Vivado behavioral and timing verification](vivado_gui/README.md)
- [Tang Nano 20K RTL and synthesized simulation](../nano/README.md)
