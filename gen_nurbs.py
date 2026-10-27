"""Evre 3 test vektorleri. Beklenen sonuc: Python'un kendi IEEE-754 float64 islemleri (nurbs.v ile ayni islem sirasi)."""
import math
import os
import random
import struct
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "model"))
import nurbs_model as nm  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
QNAN = 0x7FF8000000000000
MIN_NORMAL = 2.0 ** -1022


def f2i(x):
    return struct.unpack('<Q', struct.pack('<d', x))[0]


def pydiv(a, b):
    if b == 0:
        if a == 0 or a != a:
            return float('nan')
        return float('inf') * math.copysign(1, a) * math.copysign(1, b)
    return a / b


def rnd(rng, lo=-20, hi=20):
    return (rng.random() * 1.9 + 1.0) * 2.0 ** rng.randint(lo, hi) * rng.choice([-1, 1])


def write(name, tests):
    with open(os.path.join(HERE, name), "w") as f:
        f.write("%016x\n" % len(tests))
        for t in tests:
            for w in t:
                f.write("%016x\n" % w)


def div_tests(rng):
    vals = [0.0, -0.0, 1.0, -1.0, 3.0, float('inf'), -float('inf')]
    tests = []
    for a in vals:
        for b in vals:
            r = pydiv(a, b)
            tests.append([f2i(a), f2i(b), QNAN if r != r else f2i(r)])
    for a in (QNAN, 0x7FF0000000000001):
        tests.append([a, f2i(1.0), QNAN])
        tests.append([f2i(1.0), a, QNAN])
    while len(tests) < 20000:
        a = rnd(rng)
        k = rng.randint(0, 4)
        if k == 0:
            b = rnd(rng)
        elif k == 1:
            b = a * (1 + rng.randint(-4, 4) * 2.0 ** -52) or 1.0     # oran ~ 1
        elif k == 2:
            b = rnd(rng, -90, 90)
        elif k == 3:
            b = float(rng.randint(1, 50))
            a = b * rng.randint(1, 50)                                # tam bolunen
        else:
            b = rnd(rng, -3, 3)
            a = rnd(rng, -3, 3)
        r = pydiv(a, b)
        if r == 0 or (MIN_NORMAL <= abs(r) < float('inf')):
            tests.append([f2i(a), f2i(b), f2i(r)])
    return tests


def py_eval(u, K, P, W):
    def alpha(k0, k1):
        al = (u - k0) / (k1 - k0)
        return al, 1.0 - al

    def lerp4(a, b, om, al):
        return [om * a[c] + al * b[c] for c in range(4)]

    d = [[P[i][0] * W[i], P[i][1] * W[i], P[i][2] * W[i], W[i]] for i in range(4)]
    a11, a21, a31 = alpha(K[0], K[3]), alpha(K[1], K[4]), alpha(K[2], K[5])
    a22, a32, a33 = alpha(K[1], K[3]), alpha(K[2], K[4]), alpha(K[2], K[3])
    d11 = lerp4(d[0], d[1], a11[1], a11[0])
    d21 = lerp4(d[1], d[2], a21[1], a21[0])
    d31 = lerp4(d[2], d[3], a31[1], a31[0])
    d22 = lerp4(d11, d21, a22[1], a22[0])
    d32 = lerp4(d21, d31, a32[1], a32[0])
    f = lerp4(d22, d32, a33[1], a33[0])
    return [f[0] / f[3], f[1] / f[3], f[2] / f[3]]


def main():
    rng = random.Random(777)
    write("div.hex", div_tests(rng))
    nt = []
    for _ in range(400):
        u, K, P, W = nm.random_case(rng)
        exp = py_eval(u, K, P, W)
        words = [f2i(u)] + [f2i(x) for x in K]
        for i in range(4):
            words += [f2i(P[i][0]), f2i(P[i][1]), f2i(P[i][2]), f2i(W[i])]
        words += [f2i(x) for x in exp]
        nt.append(words)
    write("nurbs.hex", nt)
    print("nurbs vektorleri hazir: div 20000+, nurbs", len(nt))


if __name__ == "__main__":
    main()
