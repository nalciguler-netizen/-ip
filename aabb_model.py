"""Evre 2 referans modeli: aabb.v ile ayni mantik (bit desenleri uzerinde). Python float karsilastirmasiyla dogrular."""
import random
import struct


def f2i(x):
    return struct.unpack('<Q', struct.pack('<d', x))[0]


def le(a, b):
    a_nan = ((a >> 52) & 0x7FF) == 0x7FF and (a & ((1 << 52) - 1)) != 0
    b_nan = ((b >> 52) & 0x7FF) == 0x7FF and (b & ((1 << 52) - 1)) != 0
    ma, mb = a & ((1 << 63) - 1), b & ((1 << 63) - 1)
    sa, sb = a >> 63, b >> 63
    if a_nan or b_nan:
        return 0
    if ma == 0 and mb == 0:
        return 1
    if sa != sb:
        return sa
    return int(ma >= mb) if sa else int(ma <= mb)


def overlap(a, b):
    ok = 1
    for k in range(3):
        ok &= le(a[k], b[k + 3]) & le(b[k], a[k + 3])
    return ok


def selftest(n=300000, seed=7):
    rng = random.Random(seed)
    specials = [0.0, -0.0, float('inf'), -float('inf'), float('nan'), 5e-324, -5e-324, 1.0, -1.0]
    bad = 0
    for _ in range(n):
        x = rng.choice(specials) if rng.random() < 0.4 else rng.choice([-1, 1]) * rng.random() * 10 ** rng.randint(-3, 3)
        y = rng.choice(specials) if rng.random() < 0.4 else rng.choice([-1, 1]) * rng.random() * 10 ** rng.randint(-3, 3)
        if le(f2i(x), f2i(y)) != int(x <= y):
            bad += 1
            if bad < 5:
                print("UYUMSUZ", x, y)
    print("aabb model testi:", "TAMAM" if bad == 0 else f"{bad} hata", f"({n} tur)")
    return bad


if __name__ == "__main__":
    raise SystemExit(1 if selftest() else 0)
