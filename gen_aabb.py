"""Evre 2 test vektorleri. Beklenen sonuc Python'un kendi float karsilastirmasindan gelir."""
import os
import random
import struct

HERE = os.path.dirname(os.path.abspath(__file__))


def f2i(x):
    return struct.unpack('<Q', struct.pack('<d', x))[0]


def coord(rng):
    r = rng.random()
    if r < 0.05:
        return rng.choice([0.0, -0.0])
    if r < 0.08:
        return rng.choice([float('inf'), -float('inf')])
    return float(rng.randint(-4, 4)) if r < 0.55 else rng.uniform(-10, 10)


def make_box(rng):
    lo, hi = [], []
    for _ in range(3):
        a, b = coord(rng), coord(rng)
        if a > b:
            a, b = b, a
        lo.append(a)
        hi.append(b)
    if rng.random() < 0.01:                       # nadiren NaN
        lo[rng.randint(0, 2)] = float('nan')
    return lo + hi


def hit(a, b):
    return int(all(a[k] <= b[k + 3] and b[k] <= a[k + 3] for k in range(3)))


def write(name, tests):
    with open(os.path.join(HERE, name), "w") as f:
        f.write("%016x\n" % len(tests))
        for t in tests:
            for w in t:
                f.write("%016x\n" % w)


def main():
    rng = random.Random(4242)
    t1, t2 = [], []
    for _ in range(3000):
        a, b = make_box(rng), make_box(rng)
        t1.append([f2i(x) for x in a + b] + [hit(a, b)])
    for _ in range(1000):
        q = make_box(rng)
        boxes = [make_box(rng) for _ in range(8)]
        mask = sum(hit(q, bx) << i for i, bx in enumerate(boxes))
        t2.append([f2i(x) for x in q] + [f2i(x) for bx in boxes for x in bx] + [mask])
    write("aabb.hex", t1)
    write("aabb8.hex", t2)
    ones = sum(t[-1] for t in t1)
    print("aabb vektorleri hazir:", len(t1), "test,", ones, "kesisen,", len(t1) - ones, "kesismeyen;", len(t2), "coklu test")


if __name__ == "__main__":
    main()
