"""Evre 3 referans modeli: nurbs.v ile ayni islem sirasi (bit duzeyi, fp64_model islemleriyle).
Ayrica De Boor indekslerini BAGIMSIZ bir yontemle (Cox-de Boor taban fonksiyonlari) dogrular."""
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fp64_model as m  # noqa: E402

QNAN = 0x7FF8000000000000
ONE = 0x3FF0000000000000


def neg(x):
    return x ^ (1 << 63)


def div(a, b):
    sa, ea, fa = m.fields(a)
    sb, eb, fb = m.fields(b)
    s = sa ^ sb
    a_nan, b_nan = ea == 2047 and fa != 0, eb == 2047 and fb != 0
    a_inf, b_inf = ea == 2047 and fa == 0, eb == 2047 and fb == 0
    a_zero, b_zero = ea == 0, eb == 0
    if a_nan or b_nan or (a_inf and b_inf) or (a_zero and b_zero):
        return QNAN
    if a_inf or b_zero:
        return (s << 63) | (0x7FF << 52)
    if b_inf or a_zero:
        return s << 63
    num = ((1 << 52) | fa) << 55
    den = (1 << 52) | fb
    q, r = divmod(num, den)
    q &= (1 << 56) - 1
    e = ea - eb + 1023
    if q >> 55:
        mant, guard = q >> 3, (q >> 2) & 1
        sticky = 1 if ((q & 3) or r) else 0
    else:
        mant, guard = q >> 2, (q >> 1) & 1
        sticky = 1 if ((q & 1) or r) else 0
        e -= 1
    inc = guard & (sticky | (mant & 1))
    mr = mant + inc
    if mr >> 53:
        mr >>= 1
        e += 1
    if e >= 2047:
        return (s << 63) | (0x7FF << 52)
    if e <= 0:
        return s << 63
    return (s << 63) | (e << 52) | (mr & ((1 << 52) - 1))


def alpha(u, k0, k1):
    num = m.add(u, neg(k0))
    den = m.add(k1, neg(k0))
    al = div(num, den)
    return al, m.add(ONE, neg(al))


def lerp4(a, b, om, al):
    return [m.add(m.mul(om, a[c]), m.mul(al, b[c])) for c in range(4)]


def eval3(u, K, cp):
    d = []
    for i in range(4):
        x, y, z, w = cp[4 * i:4 * i + 4]
        d.append([m.mul(x, w), m.mul(y, w), m.mul(z, w), w])
    a11, a21, a31 = alpha(u, K[0], K[3]), alpha(u, K[1], K[4]), alpha(u, K[2], K[5])
    a22, a32, a33 = alpha(u, K[1], K[3]), alpha(u, K[2], K[4]), alpha(u, K[2], K[3])
    d11 = lerp4(d[0], d[1], a11[1], a11[0])
    d21 = lerp4(d[1], d[2], a21[1], a21[0])
    d31 = lerp4(d[2], d[3], a31[1], a31[0])
    d22 = lerp4(d11, d21, a22[1], a22[0])
    d32 = lerp4(d21, d31, a32[1], a32[0])
    f = lerp4(d22, d32, a33[1], a33[0])
    return [div(f[0], f[3]), div(f[1], f[3]), div(f[2], f[3])]


# ---- bagimsiz dogrulama: Cox-de Boor ----
def basis(t, i, p, u):
    if p == 0:
        return 1.0 if t[i] <= u < t[i + 1] else 0.0
    r = 0.0
    d1 = t[i + p] - t[i]
    if d1 > 0:
        r += (u - t[i]) / d1 * basis(t, i, p - 1, u)
    d2 = t[i + p + 1] - t[i + 1]
    if d2 > 0:
        r += (t[i + p + 1] - u) / d2 * basis(t, i + 1, p - 1, u)
    return r


def reference(u, K, P, W, pad_lo=1.0, pad_hi=1.0):
    t = [K[0] - pad_lo] + list(K) + [K[5] + pad_hi]     # 8 dugum, aktif aralik [t3,t4) = [K2,K3)
    N = [basis(t, i, 3, u) for i in range(4)]
    den = sum(W[i] * N[i] for i in range(4))
    return [sum(W[i] * P[i][c] * N[i] for i in range(4)) / den for c in range(3)]


def random_case(rng):
    k2 = rng.uniform(-5, 5)
    k3 = k2 + rng.uniform(0.1, 3)
    k1 = k2 - (0.0 if rng.random() < 0.3 else rng.uniform(0.05, 2))
    k0 = k1 - (0.0 if rng.random() < 0.3 else rng.uniform(0.05, 2))
    k4 = k3 + (0.0 if rng.random() < 0.3 else rng.uniform(0.05, 2))
    k5 = k4 + (0.0 if rng.random() < 0.3 else rng.uniform(0.05, 2))
    K = [k0, k1, k2, k3, k4, k5]
    u = k2 + (k3 - k2) * rng.random()
    if rng.random() < 0.1 or u >= k3:
        u = k2
    P = [[rng.uniform(-10, 10) for _ in range(3)] for _ in range(4)]
    W = [rng.uniform(0.5, 3) for _ in range(4)]
    return u, K, P, W


def selftest(n=3000, seed=11):
    rng = random.Random(seed)
    bad = 0
    for _ in range(n):
        u, K, P, W = random_case(rng)
        cp = []
        for i in range(4):
            cp += [m.f2i(P[i][0]), m.f2i(P[i][1]), m.f2i(P[i][2]), m.f2i(W[i])]
        got = [m.i2f(x) for x in eval3(m.f2i(u), [m.f2i(x) for x in K], cp)]
        for pad in ((1.0, 1.0), (7.5, 0.3)):                     # dis dugumler sonucu etkilememeli
            ref = reference(u, K, P, W, *pad)
            if any(abs(g - r) > 1e-9 * (1 + abs(r)) for g, r in zip(got, ref)):
                bad += 1
                if bad < 5:
                    print("UYUMSUZ", u, K, got, ref)
                break
    # duzgun kubik B-spline, orta nokta: agirliklar [1,23,23,1]/48
    K = [m.f2i(float(i)) for i in range(6)]
    P = [0.0, 10.0, 20.0, 30.0]
    cp = []
    for p in P:
        cp += [m.f2i(p), m.f2i(0.0), m.f2i(0.0), m.f2i(1.0)]
    x = m.i2f(eval3(m.f2i(2.5), K, cp)[0])
    want = (1 * 0 + 23 * 10 + 23 * 20 + 1 * 30) / 48
    if abs(x - want) > 1e-12:
        bad += 1
        print("duzgun B-spline UYUMSUZ", x, want)
    print("nurbs model testi:", "TAMAM" if bad == 0 else f"{bad} hata", f"({n} tur)")
    return bad


if __name__ == "__main__":
    raise SystemExit(1 if selftest() else 0)
