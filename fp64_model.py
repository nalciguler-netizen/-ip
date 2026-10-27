"""Evre 1 referans modeli: Verilog modullerinin adim adim ayni algoritmasi (tamsayi aritmetigi).
Calistirinca rastgele sayilarla Python float sonuclariyla (IEEE-754) karsilastirir."""
import random
import struct

QNAN = 0x7FF8000000000000


def f2i(x):
    return struct.unpack('<Q', struct.pack('<d', x))[0]


def i2f(x):
    return struct.unpack('<d', struct.pack('<Q', x))[0]


def fields(x):
    return x >> 63, (x >> 52) & 0x7FF, x & ((1 << 52) - 1)


def mul(a, b):
    sa, ea, fa = fields(a)
    sb, eb, fb = fields(b)
    s = sa ^ sb
    a_nan, b_nan = ea == 2047 and fa != 0, eb == 2047 and fb != 0
    a_inf, b_inf = ea == 2047 and fa == 0, eb == 2047 and fb == 0
    a_zero, b_zero = ea == 0, eb == 0
    if a_nan or b_nan:
        return QNAN
    if (a_inf and b_zero) or (b_inf and a_zero):
        return QNAN
    if a_inf or b_inf:
        return (s << 63) | (0x7FF << 52)
    if a_zero or b_zero:
        return s << 63
    p = ((1 << 52) | fa) * ((1 << 52) | fb)
    if p >> 105:
        mant, guard = p >> 53, (p >> 52) & 1
        sticky = (p & ((1 << 52) - 1)) != 0
        e = ea + eb - 1023 + 1
    else:
        mant, guard = p >> 52, (p >> 51) & 1
        sticky = (p & ((1 << 51) - 1)) != 0
        e = ea + eb - 1023
    inc = guard & (1 if (sticky or (mant & 1)) else 0)
    mr = mant + inc
    if mr >> 53:
        mr >>= 1
        e += 1
    if e >= 2047:
        return (s << 63) | (0x7FF << 52)
    if e <= 0:
        return s << 63
    return (s << 63) | (e << 52) | (mr & ((1 << 52) - 1))


def add(a, b):
    sa, ea, fa = fields(a)
    sb, eb, fb = fields(b)
    a_nan, b_nan = ea == 2047 and fa != 0, eb == 2047 and fb != 0
    a_inf, b_inf = ea == 2047 and fa == 0, eb == 2047 and fb == 0
    a_zero, b_zero = ea == 0, eb == 0
    if a_nan or b_nan:
        return QNAN
    if a_inf and b_inf:
        return a if sa == sb else QNAN
    if a_inf:
        return a
    if b_inf:
        return b
    if a_zero and b_zero:
        return (sa & sb) << 63
    if a_zero:
        return b
    if b_zero:
        return a
    big, small = (a, b) if (a & ((1 << 63) - 1)) >= (b & ((1 << 63) - 1)) else (b, a)
    sbig, ebig, fbig = fields(big)
    ssm, esm, fsm = fields(small)
    ediff = ebig - esm
    m_big = ((1 << 52) | fbig) << 3
    m_small = ((1 << 52) | fsm) << 3
    ec = 60 if ediff > 60 else ediff
    ext = (m_small << 56) >> ec
    shifted = ext >> 56
    sticky = 1 if (ext & ((1 << 56) - 1)) else 0
    if sbig ^ ssm:
        s_sum = m_big - shifted - sticky
    else:
        s_sum = m_big + shifted
    if s_sum == 0:
        return 0
    p = s_sum.bit_length() - 1
    lz = 56 - p
    nm = (s_sum << lz) & ((1 << 57) - 1)
    e = ebig + 1 - lz
    mant, guard = nm >> 4, (nm >> 3) & 1
    rem = 1 if ((nm & 7) or sticky) else 0
    inc = guard & (rem | (mant & 1))
    mr = mant + inc
    if mr >> 53:
        mr >>= 1
        e += 1
    if e >= 2047:
        return (sbig << 63) | (0x7FF << 52)
    if e <= 0:
        return sbig << 63
    return (sbig << 63) | (e << 52) | (mr & ((1 << 52) - 1))


def neg(x):
    return x ^ (1 << 63)


def dot(a, b):
    p = [mul(x, y) for x, y in zip(a, b)]
    s = p[0]
    for q in p[1:]:
        s = add(s, q)
    return s


def cross(a, b):
    ax, ay, az = a
    bx, by, bz = b
    return [add(mul(ay, bz), neg(mul(az, by))),
            add(mul(az, bx), neg(mul(ax, bz))),
            add(mul(ax, by), neg(mul(ay, bx)))]


def mat4(A, B):
    C = []
    for i in range(4):
        for j in range(4):
            C.append(dot([A[i * 4 + k] for k in range(4)], [B[k * 4 + j] for k in range(4)]))
    return C


def rnd(rng, lo=-20, hi=20):
    e = rng.randint(lo, hi)
    return (rng.random() * 1.9 + 1.0) * 2.0 ** e * rng.choice([-1, 1])


def selftest(n=200000, seed=1):
    rng = random.Random(seed)
    bad = 0
    for _ in range(n):
        k = rng.randint(0, 3)
        a = rnd(rng)
        if k == 0:
            b = rnd(rng)
        elif k == 1:
            b = -a * (1 + rng.randint(-8, 8) * 2.0 ** -52)
        elif k == 2:
            b = rnd(rng, -90, 90)
        else:
            b = a * 2.0 ** rng.randint(-60, -50)
        for op, ref in ((add, a + b), (mul, a * b)):
            if ref != 0 and not (2.0 ** -1022 <= abs(ref) < float('inf')):
                continue
            got = op(f2i(a), f2i(b))
            if got != f2i(ref):
                bad += 1
                if bad < 5:
                    print("UYUMSUZ", op.__name__, a, b, hex(got), hex(f2i(ref)))
    print("model testi:", "TAMAM" if bad == 0 else f"{bad} hata", f"({n} tur)")
    return bad


if __name__ == "__main__":
    raise SystemExit(1 if selftest() else 0)
