"""Assemble a bounded RV32I test and interpret it to obtain expected stores."""
from pathlib import Path

HERE = Path(__file__).resolve().parent
code, notes, labels, fixups = [], [], {}, []
MASK = 0xffffffff

def emit(word, note):
    code.append(word & MASK)
    notes.append(note)

def label(name):
    labels[name] = 4 * len(code)

def i(imm, rs, f3, rd, op=0x13):
    return ((imm & 4095) << 20) | (rs << 15) | (f3 << 12) | (rd << 7) | op

def r(f7, rs2, rs1, f3, rd):
    return (f7 << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | 0x33

def s(imm, rs2, rs1=31, f3=2):
    return (((imm >> 5) & 127) << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | ((imm & 31) << 7) | 0x23

def b(imm, rs2, rs1, f3):
    return (((imm >> 12) & 1) << 31) | (((imm >> 5) & 63) << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | (((imm >> 1) & 15) << 8) | (((imm >> 11) & 1) << 7) | 0x63

def j(imm, rd):
    return (((imm >> 20) & 1) << 31) | (((imm >> 1) & 1023) << 21) | (((imm >> 11) & 1) << 20) | (((imm >> 12) & 255) << 12) | (rd << 7) | 0x6f

def branch(name, f3, rs1, rs2):
    fixups.append((len(code), lambda delta: b(delta, rs2, rs1, f3), name, False))
    emit(0, f"branch f3={f3} x{rs1},x{rs2},{name}")

def jump(name, rd=0):
    fixups.append((len(code), lambda delta: j(delta, rd), name, False))
    emit(0, f"jal x{rd},{name}")

def constant(rd, value):
    emit(((value + 0x800) & 0xfffff000) | (rd << 7) | 0x37, f"lui x{rd},high({value & MASK:08x})")
    emit(i(value, rd, 0, rd), f"addi x{rd},x{rd},low({value & MASK:08x})")

def result(rd):
    emit(s(160, rd), f"sw x{rd},160(x31) -- checked result")

emit(i(1, 1, 0, 1), "addi x1,x1,1 -- must execute once after reset")
emit(i(768, 0, 0, 31), "addi x31,x0,768 -- scratch base")
result(1)
constant(1, 0x80000001)
constant(2, 31)
for name, f7, f3 in [("ADD",0,0),("SUB",32,0),("SLL",0,1),("SLT",0,2),("SLTU",0,3),
                     ("XOR",0,4),("SRL",0,5),("SRA",32,5),("OR",0,6),("AND",0,7)]:
    emit(r(f7,2,1,f3,3), f"{name} x3,x1,x2; immediate forwarding to store")
    result(3)
for name, f3, imm in [("ADDI",0,-1),("SLLI",1,31),("SLTI",2,-1),("SLTIU",3,-1),
                      ("XORI",4,-1),("SRLI",5,31),("SRAI",5,1055),("ORI",6,85),("ANDI",7,255)]:
    emit(i(imm,1,f3,3), f"{name} x3,x1,{imm}")
    result(3)
emit(0x123451b7, "lui x3,0x12345")
result(3)
emit(0x00001197, "auipc x3,0x1")
result(3)
emit(i(99,0,0,0), "addi x0,x0,99 -- x0 stays zero")
result(0)

# Initialize scratch on every run; do not rely on reload for warm reset.
constant(4, 0x80ff7f81)
emit(s(0,4), "sw x4,0(x31)")
for name, f3, offset in [("LB",0,0),("LBU",4,0),("LH",1,2),("LHU",5,2),("LW",2,0)]:
    emit(i(offset,31,f3,5,3), f"{name} x5,{offset}(x31)")
    emit(i(1,5,0,6), "addi x6,x5,1 -- load-use dependency")
    result(6)
emit(i(0,31,2,5,3), "lw x5,0(x31)")
emit(s(4,5), "sw x5,4(x31) -- late load-to-store forwarding")
emit(i(4,31,2,6,3), "lw x6,4(x31)")
result(6)
emit(s(1,2,31,0), "sb x2,1(x31)")
emit(s(2,2,31,1), "sh x2,2(x31)")
emit(i(0,31,2,6,3), "lw x6,0(x31) -- verify byte lanes")
result(6)
constant(3, 0x76543210)
emit(r(1,2,1,0,3), "MUL disabled -- must preserve x3")
emit(i(1,3,0,4), "addi x4,x3,1 -- no false MUL result forwarding")
result(4)

for pair, x, y in [(0,0,0),(1,-1,1)]:
    emit(i(x,0,0,1), f"addi x1,x0,{x}")
    emit(i(y,0,0,2), f"addi x2,x0,{y}")
    tests = [(0,x==y),(1,x!=y),(4,x<y),(5,x>=y),(6,(x&MASK)<(y&MASK)),(7,(x&MASK)>=(y&MASK))]
    for f3,taken in tests:
        target = f"branch_{pair}_{f3}"
        branch(target if taken else "failure", f3, 1, 2)
        if taken:
            emit(s(252,1), "wrong-path completion store -- MUST be squashed")
            label(target)
        emit(i(10+f3,0,0,3), "branch marker")
        result(3)

emit(s(8,0), "initialize zero scratch word")
emit(i(8,31,2,1,3), "lw x1,8(x31)")
branch("load_branch",0,1,0)
emit(s(252,2), "wrong-path store after load/branch -- MUST be squashed")
label("load_branch")
jump("function",5)
result(6)
result(5)
fixups.append((len(code), lambda absolute: i(absolute+1,0,0,9), "indirect_target", True))
emit(0, "addi x9,x0,indirect_target+1")
emit(i(0,9,0,9,0x67), "jalr x9,0(x9) -- odd target and source/destination alias")
emit(s(252,2), "wrong-path JALR store -- MUST be squashed")
label("indirect_target")
result(9)
emit(i(3,0,0,10), "loop count=3")
label("loop")
emit(i(-1,10,0,10), "decrement loop count")
branch("loop",1,10,0)
result(10)
constant(11, 0x600dc0de)
emit(s(252,11), "completion signature")
label("halt")
jump("halt")
label("function")
emit(i(3,5,0,6), "function uses JAL link immediately")
emit(i(0,5,0,0,0x67), "jalr x0,0(x5) -- return")
label("failure")
emit(s(252,0), "failure signature")
jump("halt")

for pos, encode, target, absolute in fixups:
    code[pos] = encode(labels[target] if absolute else labels[target] - pos*4)
assert len(code) <= 192, f"Program overlaps scratch RAM: {len(code)} words"
words = code + [0x00000013] * (256-len(code))
(HERE / "gui_program.mem").write_text("".join(f"{w:08x}\n" for w in words))
(HERE / "program_listing.txt").write_text("".join(f"{n*4:03x}: {w:08x}  {text}\n" for n,(w,text) in enumerate(zip(code,notes))))

# Independent architectural interpreter. Only emitted instructions are decoded;
# pipeline state, forwarding, and timing are intentionally absent from this model.
def sign(value, bits):
    return value - (1 << bits) if value & (1 << (bits-1)) else value

mem = bytearray(b"".join(w.to_bytes(4,"little") for w in words))
regs, stores, pc = [0]*32, [], 0
for steps in range(2000):
    if pc == labels["halt"]:
        break
    insn = int.from_bytes(mem[pc:pc+4],"little")
    op, rd, f3 = insn & 127, (insn >> 7)&31, (insn >> 12)&7
    rs1, rs2, f7 = (insn >> 15)&31, (insn >> 20)&31, insn >> 25
    x,y = regs[rs1],regs[rs2]
    imm = sign(insn >> 20,12)
    nxt,value = pc+4,None
    if op == 0x37: value = insn & 0xfffff000
    elif op == 0x17: value = pc + (insn & 0xfffff000)
    elif op in (0x13,0x33):
        if op == 0x13: y = imm & MASK
        if op == 0x33 and f7 == 1: pass # Disabled M extension.
        elif f3 == 0: value = x-y if op==0x33 and f7==32 else x+y
        elif f3 == 1: value = x << (y&31)
        elif f3 == 2: value = int(sign(x,32)<sign(y,32))
        elif f3 == 3: value = int(x<y)
        elif f3 == 4: value = x^y
        elif f3 == 5: value = (sign(x,32) if f7==32 else x) >> (y&31)
        elif f3 == 6: value = x|y
        elif f3 == 7: value = x&y
    elif op == 3:
        addr = (x+imm)&1023
        size = {0:1,1:2,2:4,4:1,5:2}[f3]
        value = int.from_bytes(mem[addr:addr+size],"little",signed=f3 in (0,1))
    elif op == 0x23:
        offset = sign(((insn>>25)<<5)|((insn>>7)&31),12)
        addr = (x+offset)&1023
        size = 1 << f3
        stores.append((addr>>2,((1<<size)-1)<<(addr&3),(y << (8*(addr&3)))&MASK))
        mem[addr:addr+size] = (y & ((1<<(8*size))-1)).to_bytes(size,"little")
    elif op == 0x63:
        offset = sign(((insn>>31)<<12)|(((insn>>7)&1)<<11)|(((insn>>25)&63)<<5)|(((insn>>8)&15)<<1),13)
        take = {0:x==y,1:x!=y,4:sign(x,32)<sign(y,32),5:sign(x,32)>=sign(y,32),6:x<y,7:x>=y}[f3]
        if take: nxt = pc+offset
    elif op == 0x6f:
        offset = sign(((insn>>31)<<20)|(((insn>>12)&255)<<12)|(((insn>>20)&1)<<11)|(((insn>>21)&1023)<<1),21)
        value,nxt = pc+4,pc+offset
    elif op == 0x67: value,nxt = pc+4,(x+imm)&~1
    else: raise ValueError(f"Unexpected instruction {insn:08x}")
    if value is not None and rd: regs[rd] = value & MASK
    pc = nxt & 1023
else: raise RuntimeError("Reference program did not halt")
assert stores[-1] == (255,15,0x600dc0de)
lines = [f"localparam integer EXPECTED_COUNT = {len(stores)};\n",
         "reg [7:0] expected_addr [0:EXPECTED_COUNT-1];\n",
         "reg [3:0] expected_be [0:EXPECTED_COUNT-1];\n",
         "reg [31:0] expected_data [0:EXPECTED_COUNT-1];\n",
         "task initialize_expected; begin\n"]
for n,(addr,be,data) in enumerate(stores):
    lines.append(f"    expected_addr[{n}]=8'h{addr:02x}; expected_be[{n}]=4'h{be:x}; expected_data[{n}]=32'h{data:08x};\n")
lines.append("end endtask\n")
(HERE / "expected_stores.vh").write_text("".join(lines))
print(f"Generated {len(code)} program words, {len(stores)} expected stores, {steps} reference instructions")
