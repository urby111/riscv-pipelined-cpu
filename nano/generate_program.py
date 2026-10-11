"""Generate the unified RAM image from the documented RV32I instruction fields."""
from pathlib import Path

DISPLAY_BYTE_ADDRESS = 0x200
DISPLAY_PATTERN = 0xAAAAAAAA

def addi(rd, rs1, immediate):
    return ((immediate & 0xFFF) << 20) | (rs1 << 15) | (rd << 7) | 0x13

def sw(rs2, rs1, immediate):
    return (((immediate >> 5) & 0x7F) << 25) | (rs2 << 20) | (rs1 << 15) | (2 << 12) | ((immediate & 0x1F) << 7) | 0x23

def lw(rd, rs1, immediate):
    return ((immediate & 0xFFF) << 20) | (rs1 << 15) | (2 << 12) | (rd << 7) | 0x03

upper = ((DISPLAY_PATTERN + 0x800) >> 12) & 0xFFFFF
lower = DISPLAY_PATTERN & 0xFFF
if lower & 0x800:
    lower -= 0x1000
assert ((upper << 12) + lower) & 0xFFFFFFFF == DISPLAY_PATTERN
assert DISPLAY_BYTE_ADDRESS % 4 == 0

image = [0x00000013] * 128 + [0] * 128
image[:6] = [
    0x00000013,                         # nop
    (upper << 12) | (1 << 7) | 0x37,   # lui x1, upper
    addi(1, 1, lower),                  # addi x1, x1, lower
    sw(1, 0, DISPLAY_BYTE_ADDRESS),     # sw x1, 0x200(x0)
    lw(2, 0, DISPLAY_BYTE_ADDRESS),     # lw x2, 0x200(x0)
    0x0000006F,                         # jal x0, 0
]
# The watched cell starts at zero. Only the running CPU supplies the pattern.
assert image[DISPLAY_BYTE_ADDRESS // 4] == 0
output = Path(__file__).resolve().parent / "program.hex"
output.write_text("".join(f"{word:08x}\n" for word in image), encoding="ascii")
print(f"Generated {output}: {len(image)} words, target word 128 initially zero.")
