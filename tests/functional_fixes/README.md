# Vivado synthesis sanity check

This directory retains the synthesis runner from the functional-correction
work. It reads the current active CPU/RAM hierarchy, synthesizes main in
out-of-context mode for xc7a35tcpg236-1, and writes utilization/DRC reports.
It is a syntax, elaboration, and synthesis check; it does not establish timing
closure or board behavior.

From PowerShell at the repository root:

```powershell
.\tests\functional_fixes\check_synthesis.ps1 -Vivado 'C:\Xilinx\Vivado\2023.1\bin\vivado.bat'
```

Change -Vivado to your Vivado installation. Outputs go to the ignored build/
directory. A successful run prints FUNCTIONAL_FIXES_SYNTHESIS_PASS.

For the current functional reference suite, use
[performance_100mhz/run_reference.sh](../performance_100mhz/run_reference.sh).
The earlier MUL-enabled functional suite and rollback archives are local
historical artifacts and are excluded from this source publication.
