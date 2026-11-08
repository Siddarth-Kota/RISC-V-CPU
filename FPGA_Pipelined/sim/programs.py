"""Deterministic directed and dependency-heavy RV32I workloads (no toolchain needed)."""
import random
from pathlib import Path

def imm(rd, rs, n, f=0): return ((n & 4095) << 20) | rs << 15 | f << 12 | rd << 7 | 0x13

def reg(rd, a, b, f=0, alt=0): return alt << 25 | b << 20 | a << 15 | f << 12 | rd << 7 | 0x33

def load(rd, a, off, f=2): return ((off & 4095) << 20) | a << 15 | f << 12 | rd << 7 | 3

def store(rs, a, off, f=2):
    n = off & 4095
    return (n >> 5) << 25 | rs << 20 | a << 15 | f << 12 | (n & 31) << 7 | 0x23

def branch(a, b, off, f=0):
    n = off & 8191
    return (n >> 12) << 31 | ((n >> 5) & 63) << 25 | b << 20 | a << 15 | f << 12 | ((n >> 1) & 15) << 8 | ((n >> 11) & 1) << 7 | 0x63

def jal(rd, off):
    n = off & 0x1fffff
    return (n >> 20) << 31 | ((n >> 1) & 1023) << 21 | ((n >> 11) & 1) << 20 | ((n >> 12) & 255) << 12 | rd << 7 | 0x6f

def write(path, words):
    Path(path).write_text(''.join(f'{x:08x}\n' for x in words + [imm(31, 0, 99), jal(0, 0)]))

def generate(directory):
    p = [0x123450b7, imm(2,1,17), 0x00000197, reg(4,3,2), jal(5,8), store(2,0,0), imm(6,5,7)]
    # Odd JALR target, immediately dependent on its base producer.
    target = (len(p) + 3) * 4
    p += [imm(7,0,target+1), 7 << 15 | 8 << 7 | 0x67, store(2,0,4), reg(9,8,6)]
    p += [imm(10,0,256), 0x80ff80b7, imm(1,1,-127), store(1,10,0)]
    for lane in range(4):
        p += [load(11,10,lane,0), imm(12,11,1), load(13,10,lane,4), store(11,10,8+lane,0)]
    for lane in (0,2):
        p += [load(14,10,lane,1), reg(15,14,14), load(16,10,lane,5), store(14,10,12+lane,1)]
    # A load feeding a store, branch, and indirect jump.
    p += [load(17,10,0), store(17,10,16), branch(17,1,8), store(0,10,0)]
    jump_pc = (len(p)+6)*4
    p += [imm(18,0,jump_pc+1), store(18,10,20), load(19,10,20), 19 << 15 | 20 << 7 | 0x67, store(0,10,0), store(0,10,4)]
    p += [imm(21,0,8)]
    loop = len(p)*4
    p += [load(22,10,0), imm(21,21,-1), branch(21,0,loop-(len(p)+2)*4,1)]
    write(Path(directory)/'directed.hex',p)
    rng = random.Random(20261108)
    p = [imm(r,0,r*7-80) for r in range(1,25)]
    for _ in range(450):
        dest,a,b = [rng.randrange(1,25) for _ in range(3)]
        kind = rng.randrange(7)
        if kind < 2:
            f = rng.randrange(8)
            n = rng.randrange(32) if f in (1,5) else rng.randrange(-2048,2048)
            if f == 5 and rng.randrange(2): n |= 0x400
            p.append(imm(dest,a,n,f))
        elif kind < 4:
            f = rng.randrange(8)
            p.append(reg(dest,a,b,f,32 if f in (0,5) and rng.randrange(2) else 0))
        elif kind == 4:
            f = rng.choice([0,1,2,4,5]); size = 1 << (f & 3)
            p += [load(dest,0,256+rng.randrange(64)//size*size,f), imm(a,dest,1)]
        elif kind == 5:
            f = rng.randrange(3); size = 1 << f
            p.append(store(a,0,256+rng.randrange(64)//size*size,f))
        else:
            # Taken control transfer must squash the following store.
            p += [branch(a,a,8), store(b,0,320)] if rng.randrange(2) else [jal(dest,8), store(b,0,324)]
    write(Path(directory)/'random.hex',p)


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('directory', type=Path, help='Output directory for generated hex workloads')
    args = parser.parse_args()
    args.directory.mkdir(parents=True, exist_ok=True)
    generate(args.directory)
