# Pipelined RISC-V CPU

A 32-bit, five-stage RISC-V processor written in Verilog, with forwarding,
pipeline validity tracking, hazard handling, and a 1 KiB unified memory.
The project includes directed and independent reference-model tests, a
reproducible Vivado verification design, and a Tang Nano 20K hardware demo.

## Architecture

The pipeline has instruction fetch, decode, execute, memory, and writeback
stages. Forwarding resolves register dependencies, load-use dependencies insert
one bubble, and a late forwarding path handles load-to-store data. Redirects
invalidate younger instructions. Register x0 remains zero.

The supported subset contains 37 integer instructions:

- Register arithmetic: ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND.
- Immediate arithmetic: ADDI, SLLI, SLTI, SLTIU, XORI, SRLI, SRAI, ORI, ANDI.
- Upper immediates: LUI, AUIPC.
- Loads and stores: LB, LH, LW, LBU, LHU, SB, SH, SW.
- Branches: BEQ, BNE, BLT, BGE, BLTU, BGEU.
- Jumps: JAL, JALR.

MUL and the other M-extension instructions are disabled. Unsupported encodings
have no architectural effects rather than raising traps. There are no CSRs,
interrupts, traps, privileged instructions, or compressed instructions. The
verified scope assumes naturally aligned data accesses and word-aligned
instruction targets; JALR clears bit zero. Memory addresses use the low address
bits and wrap within the local 1 KiB memory. This is a small educational core,
not a claim of complete RISC-V system or ISA compliance.

## Repository layout

| Path | Contents |
| --- | --- |
| `project_1.srcs/sources_1/new/` | CPU RTL; `main.v` connects CPU and RAM |
| `project_1.srcs/sim_1/new/` | Original module and CPU testbenches |
| `tests/` | Directed regression and current verification instructions |
| `tests/performance_100mhz/` | Independent reference model and pipeline assertions |
| `tests/functional_fixes/` | Vivado synthesis sanity check |
| `tests/vivado_gui/` | Vivado recreation script, constraints, test program, and recorded timing evidence |
| `nano/` | Tang Nano 20K adaptation, tests, constraints, and demo program |

The existing directory names are retained so source references work unchanged.
Some RTL files are unused legacy modules; build scripts select the active
hierarchy. The board adaptation keeps its own RTL copy because its RAM and
top-level wrapper differ from the Vivado design.

## Run the CPU tests

Install Verilator (tested with 5.020), a C++ compiler, and make. On Windows,
run these from the repository root using WSL:

```powershell
wsl --exec bash tests/run_verilator.sh
wsl --exec bash tests/performance_100mhz/run_reference.sh
```

On Linux, run the same scripts directly with `bash`. Logs, executables, and
optional waveforms go to ignored `build/` directories. See [tests/README.md](tests/README.md).

## Vivado verification

The verification design targets `xc7a35tcpg236-1` with Vivado 2023.1. Recreate
the project using **Tools > Run Tcl Script** and select
`tests/vivado_gui/create_project.tcl`. This generates
`tests/vivado_gui/project/cpu_100mhz.xpr` from the checked-in source files.

To run the behavioral simulation, synthesis, implementation, and annotated
timing simulation from PowerShell:

```powershell
.\tests\vivado_gui\verify_project.ps1 -Vivado 'C:\Xilinx\Vivado\2023.1\bin\vivado.bat'
```

Set `-Vivado` to your installation path. This is a boardless out-of-context
verification design, not an Artix-7 board bitstream. See
[the Vivado instructions](tests/vivado_gui/README.md).

## Tang Nano 20K demo

The board runs the CPU at its onboard 27 MHz clock. The program writes
`0xAAAAAAAA` to RAM address `0x200`, reads it back, and displays the low six
bits on the LEDs. LED1, LED3, and LED5 are on. The active-high S1 button resets
the CPU.

Install OSS CAD Suite and set its location, then run:

```powershell
$env:OSS_CAD_SUITE = 'C:\tools\oss-cad-suite'
cd nano
.\test.cmd
.\build.cmd
.\test_gate.cmd
.\program.cmd
```

The last command programs the connected board's SRAM using openFPGALoader.
See [nano/README.md](nano/README.md) for the hardware and tool setup.

## Verification status

Recorded project results (CPU/Vivado results dated September 19, 2026):

| Check | Result |
| --- | --- |
| Directed CPU regression | 444 / 444 checks pass |
| Independent reference regression | 928 programs, 17,773 compared instructions, 331,137 checks pass |
| Vivado behavioral simulation | Two runs with 53 checked stores per run pass |
| Vivado routed static timing at 100 MHz | Setup +0.177 ns; hold +0.071 ns |
| Vivado annotated timing simulation | Correct checked stores, but six timing violations; unresolved |
| Tang Nano demo | RTL and synthesized simulation pass; build and SRAM upload recorded as successful |

Publication checks rerun on October 11, 2026: both Verilator suites pass with
the counts above, and the Tang Nano RTL test passes. The synthesized Gowin
primitive simulation also passes using the existing generated netlist.
The recorded Vivado routing/timing and physical board upload were not rerun
for this publication.

The Vivado verification runner deliberately fails on timing violations, even
when functional output checks pass. Passing static timing does not establish
a clean annotated timing simulation. See [the detailed results](tests/vivado_gui/RESULTS.md)
and [the Tang Nano results](nano/RESULTS.md). These are recorded results;
changes to the source or toolchain require rerunning the appropriate checks.

Only selected static timing reports are checked in as evidence. Generated
projects, tool caches, build outputs, bitstreams, local rollback archives, and
unrelated personal documents are excluded from version control.
