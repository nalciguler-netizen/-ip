"""Testbench girdilerini uretir: Python'un kendi IEEE-754 float64 sonuclari beklenen degerdir.
Her .hex dosyasi: ilk satir test sayisi, sonra her test icin 64-bit kelimeler (girdiler..., beklenen)."""
import os
import random
import struct
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "model"))

HERE = os.path.dirname(os.path.abspath(__file__))
MIN_NORMAL = 2.0 ** -1022
QNAN = 0x7FF8000000000000
INF = 0x7FF0000000000000


def f2i(x):
    return struct.unpack('<Q', struct.pack('<d', x))[0]


def rnd(rng, lo=-20, hi=20):
    return (rng.random() * 1.9 + 1.0) * 2.0 ** rng.randint(lo, hi) * rng.choice([-1, 1])


def ok_result(r):
    return r == 0 or (MIN_NORMAL <= abs(r) < float('inf'))


def write(name, words_per_test, tests):
    flat = [len(tests)]
    for t in tests:
        assert len(t) == words_per_test
        flat.extend(t)
    with open(os.path.join(HERE, name), "w") as f:
        for w in flat:
            f.write("%016x\n" % w)


def binary_tests(rng, op, n):
    tests = []
    while len(tests) < n:
        a = rnd(rng)
        k = rng.randint(0, 4)
        if k == 0:
            b = rnd(rng)
        elif k == 1:
            b = -a * (1 + rng.randint(-8, 8) * 2.0 ** -52)      # yakin iptal
        elif k == 2:
            b = rnd(rng, -90, 90)                                # buyuk us farki
        elif k == 3:
            b = a * 2.0 ** rng.randint(-60, -50)                 # yuvarlama esitligi bolgesi
        else:
            b = a * (1 + rng.randint(1, 4) * 2.0 ** -52)         # ayni us
        r = op(a, b)
        if ok_result(r):
            tests.append([f2i(a), f2i(b), f2i(r)])
    return tests


def special_tests(op):
    vals = [0.0, -0.0, 1.0, -1.0, 2.5, float('inf'), -float('inf')]
    tests = [[f2i(a), f2i(b), f2i(op(a, b)) if op(a, b) == op(a, b) else QNAN] for a in vals for b in vals]
    # NaN girdileri
    for a in (QNAN, 0x7FF0000000000001):
        tests.append([a, f2i(1.0), QNAN])
        tests.append([f2i(1.0), a, QNAN])
    return tests


def main():
    rng = random.Random(2026)
    add_t = special_tests(lambda a, b: a + b) + binary_tests(rng, lambda a, b: a + b, 20000)
    mul_t = special_tests(lambda a, b: a * b) + binary_tests(rng, lambda a, b: a * b, 20000)
    write("add.hex", 3, add_t)
    write("mul.hex", 3, mul_t)

    dot_t, cross_t, mat_t = [], [], []
    for _ in range(3000):
        a = [rnd(rng, -8, 8) for _ in range(3)]
        b = [rnd(rng, -8, 8) for _ in range(3)]
        d = (a[0] * b[0] + a[1] * b[1]) + a[2] * b[2]
        c = [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]
        dot_t.append([f2i(x) for x in a + b] + [f2i(d)])
        cross_t.append([f2i(x) for x in a + b] + [f2i(x) for x in c])
    # basit bilinen durumlar: x ekseni x y ekseni = z ekseni
    cross_t.append([f2i(x) for x in [1, 0, 0, 0, 1, 0]] + [f2i(x) for x in [0, 0, 1]])
    dot_t.append([f2i(x) for x in [1, 2, 3, 4, 5, 6]] + [f2i(32.0)])
    for _ in range(600):
        A = [rnd(rng, -6, 6) for _ in range(16)]
        B = [rnd(rng, -6, 6) for _ in range(16)]
        C = []
        for i in range(4):
            for j in range(4):
                p = [A[i * 4 + k] * B[k * 4 + j] for k in range(4)]
                C.append(((p[0] + p[1]) + p[2]) + p[3])
        mat_t.append([f2i(x) for x in A + B + C])
    ident = [1.0 if i == j else 0.0 for i in range(4) for j in range(4)]
    A = [float(i + 1) for i in range(16)]
    mat_t.append([f2i(x) for x in A + ident + A])           # A * I = A
    write("dot.hex", 7, dot_t)
    write("cross.hex", 9, cross_t)
    write("mat4.hex", 48, mat_t)
    print("vektorler hazir:", len(add_t), len(mul_t), len(dot_t), len(cross_t), len(mat_t))


if __name__ == "__main__":
    main()
