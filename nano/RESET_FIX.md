# Reset polarity fix

The initial Nano wrapper treated S1 as active-low and enabled an input pull-up.
The Tang Nano 20K schematic shows that S1 connects to +3.3 V when pressed,
and pin 88 has a board pull-down when released. S1 is active-high.

Before: reset = !startup_count[5] || !button_sync[1]
After:  reset = !startup_count[5] ||  button_sync[1]

The synchronizer now starts at 00. The constraint uses PULL_MODE=DOWN.
All six LEDs remain connected to the low six bits of actual RAM word 128.

The original synthesized circuit was reproduced with the board's idle-low
input in simulation. It stopped at PC 000, with RAM bits 00 and raw LED pins
111111 (all off). See build/reset_bug_before.log.

The fixed RTL test checks the CPU's full 32-bit store, address, byte enables,
readback, live RAM display, adjacent-cell isolation, and active-high reset.
The fixed gate test uses the actual synthesized Gowin primitives and checks
startup, the LED pattern, and a button press/release. Both tests pass.

Source: Sipeed Tang Nano 20K schematic, sheets GW2AR-18 and PERIPHERALS:
https://dl.sipeed.com/fileList/TANG/Nano_20K/2_Schematic/Tang_Nano_20K_3921_Schematics.pdf

Re-upload using program.cmd in this folder after the corrected bitstream is
built. No LED pattern is hard-coded in the hardware wrapper.

Hardware verification: corrected bitstream uploaded successfully to SRAM.
User confirmed the expected steady alternating LED pattern on the physical board.
