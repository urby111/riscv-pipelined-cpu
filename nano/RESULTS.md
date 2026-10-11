# Verified reset fix

Issue: S1 is active-high, but the original wrapper treated it as active-low.
With the board's released-low level the original synthesized circuit stayed at PC zero
and drove LED pins 111111 (all off). See build/reset_bug_before.log.

Fix: active-high reset, synchronizer initialized to 00, and input pull-down.
RTL simulation: PASS (CPU store/readback and actual RAM display).
Synthesized Gowin primitive simulation: PASS with the physical idle-low button level.
See build/test.log and build/gate_test.log.

Tang Nano 20K build: PASS.
Target: GW2AR-LV18QN88C8/I7, family GW2A-18C.
Clock: 27 MHz; final routed maximum frequency: 88.92 MHz.
LUT4: 7982 / 20736; DFF: 2906 / 15552; RAM16SDP4: 258 / 648.
Bitstream: build/cpu_ram_led.fs (4620140 bytes).
SHA-256: 2C94EEACB21AEC7B36E5B51E18FDDD51851E9298D41745238BFF31B08D0EC1B8

Original CPU sources verified unchanged (28 files).
Hardware upload status is recorded separately in build/program.log when available.

Corrected bitstream uploaded successfully to the connected Tang Nano 20K SRAM.
openFPGALoader completed Load SRAM 100.00%, Done/DONE with exit code 0.
See build/program.log. User confirmed LED1, LED3, and LED5 are steadily lit; LED0, LED2, and LED4 are off.

