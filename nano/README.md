# CPU RAM display on Tang Nano 20K

This is a copy of the CPU sources from
`../project_1.srcs/sources_1/new`, adapted for the Tang Nano 20K.
The original CPU project is unchanged. All 28 Verilog files are copied into
`rtl`; `sources.f` lists the active hierarchy and excludes unused legacy modules.

The CPU runs at the board's 27 MHz clock. After automatic startup reset it
executes a short RV32I program that:

1. Builds **`0xAAAAAAAA`**, the 32-bit pattern `10101010...10101010`, in x1.
2. Stores it at **byte address `0x200` (512)**.
3. Loads that address back into x2, then loops forever.

The six onboard LEDs display **bits 5 through 0 of that RAM cell**. The LEDs
are static for this program. LED1, LED3, and LED5 light; LED0, LED2, and LED4
are off. In bit order LED5..LED0 the visible binary value is `101010`.
The FPGA pin levels are inverted because a low voltage turns these LEDs on.

## Build and upload from PowerShell

```powershell
$env:OSS_CAD_SUITE = 'C:\tools\oss-cad-suite'
cd nano
.\test.cmd
.\build.cmd
.\test_gate.cmd
.\program.cmd
```

The ready-to-upload bitstream is **`build/cpu_ram_led.fs`**.
`program.cmd` loads SRAM only using openFPGALoader. Connect the Tang Nano 20K
and configure its USB/JTAG driver for openFPGALoader on Windows before uploading.
No driver changes are performed by these scripts.

The scripts require OSS CAD Suite (Yosys, nextpnr-himbaechel, Apicula's
gowin_pack, Icarus Verilog, Python, and openFPGALoader). Set
`$env:OSS_CAD_SUITE` to the extracted suite's root folder; `toolchain.cmd`
loads its `environment.bat`.
Pressing S1 resets the CPU and runs the program again; RAM is not cleared by
the button. The program writes the pattern again after reset.

## The exact RAM-to-LED path

The store in `program.S` is `sw x1, 512(x0)`. `generate_program.py` encodes
that instruction in `program.hex`; the CPU executes the hex image loaded into
the actual RAM. The destination cell starts at zero, so the pattern is not
preloaded into the displayed cell.

`rtl/main_cpu.v` converts the CPU byte address into the RAM word index:

```verilog
assign data_addr = mem_alu_result[ADDR_WIDTH-1:2];
```

With `ADDR_WIDTH=10`, this is bits `[9:2]`: `0x200 / 4 = 128`.
`rtl/main.v` connects the original CPU data bus to the memory and selects
word 128 for display:

```verilog
Ram #(.ADDR_WIDTH(10), .DATA_WIDTH(32),
      .INIT_FILE("program.hex"), .LED_WORD_INDEX(128)) System_Memory (
```

The existing write logic in `rtl/Ram.v` writes each enabled byte to
`ram[addr]`. The new output reads that same memory array directly:

```verilog
assign led_word = ram[LED_WORD_INDEX];
```

`main` passes this output to `nano_cpu_top.v`, which drives the pins:

```verilog
assign led = ~led_ram_word[5:0];
```

`tangnano20k.cst` connects LED0..LED5 to FPGA pins 15..20, clock to pin 4,
and the active-high S1 reset button to pin 88. S1 is low when released;
pressing it connects the input to +3.3 V. The input uses a pull-down.

## Verification and changes

`test.cmd` checks a real execution of the copied CPU: the write address, all
four byte enables, the complete 32-bit store data, RAM contents, x2 readback,
and LED output. It also changes RAM word 129 and checks the display is
unchanged, then changes word 128 and checks that LEDs update without another
CPU store. This distinguishes a RAM read from a hard-coded pattern or a
latched store-bus value. Button reset and repeated execution are also tested.

The CPU core itself and its component modules are unchanged. Only the copied
`main.v` and `Ram.v` are adapted: a program image and a RAM observation port
are added, and the Xilinx-specific distributed-memory preference is removed
so the Gowin toolchain can choose an implementation. The local source-copy
manifest is excluded from version control.

`build/synthesis.log` and `build/place_route.log` contain the build evidence.
The build targets 27 MHz with no timing-failure override.

`test_gate.cmd` also simulates the synthesized Gowin primitives with S1
released low, verifies the RAM-to-LED result, and presses/releases the
active-high button. The initial version incorrectly treated S1 as
active-low and held the CPU in reset at the board's real idle level.
The corrected wrapper uses an active-high button with a pull-down.

Board pins were checked against
[Apicula's Tang Nano 20K constraints](https://github.com/YosysHQ/apicula/blob/master/examples/tangnano20k.cst).
