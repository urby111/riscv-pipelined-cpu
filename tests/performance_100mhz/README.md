# Independent architectural reference regression

This suite compares the current CPU against a separate instruction interpreter
and binds assertions that invalid pipeline slots cannot cause architectural
side effects. The historical directory name is retained for the existing
runner paths; this simulation does not measure clock frequency.

From the repository root:

```powershell
wsl --exec bash tests/performance_100mhz/run_reference.sh
```

Requires Verilator with --binary/--timing support, g++, and make. Outputs
go to the ignored build/ directory. The runner exits nonzero on failure.

The recorded default run passes 928 programs, 17,773 compared instructions,
and 331,137 checks. Coverage includes all six branch conditions across boundary
operand pairs, arithmetic forwarding, load-use dependencies, wrong-path stores
and register writes, reset, and deterministic mixed random programs. The model
compares instruction order and writeback, then every register and RAM word.
Bound assertions check validity gating in the execute, memory, and writeback
stages.

MUL encodings are retained as unsupported-instruction tests: they must leave
the destination register unchanged. The supported CPU subset excludes the
M extension, CSRs, traps, interrupts, and privileged/compressed instructions.
Naturally aligned data and word-aligned instruction targets are required.

Alternate deterministic seeds/program counts can be supplied as plusargs:

```powershell
wsl --exec bash tests/performance_100mhz/run_reference.sh +seed=12345 +programs=128
```

For actual FPGA timing verification, see [vivado_gui](../vivado_gui/README.md).
