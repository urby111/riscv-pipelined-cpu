# RV32I program executed by the copied CPU, beginning at byte address 0.
# program.hex contains these instructions and the initial 1 KiB RAM image.
    nop
    lui  x1, 0xAAAAB       # x1 = 0xAAAAB000
    addi x1, x1, -1366    # x1 = 0xAAAAAAAA = 10101010...10101010
    sw   x1, 512(x0)      # Write to byte address 0x200 = RAM word index 128
    lw   x2, 512(x0)      # Read the same RAM word back through the CPU
stop:
    jal  x0, stop         # Hold the pattern by looping here
