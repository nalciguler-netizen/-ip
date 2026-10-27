// Kutuphane kendi kendini test eder: sonuclar ana bilgisayarin IEEE-754 double islemleriyle bit bit ayni olmali.
#include "geomchip.h"
#include <cmath>
#include <cstdio>
#include <cstring>
#include <random>

static std::mt19937_64 rng(12345);
static double U(double lo, double hi) { return std::uniform_real_distribution<double>(lo, hi)(rng); }
static double rnd(int lo = -20, int hi = 20) {
    int e = (int)(rng() % (uint64_t)(hi - lo + 1)) + lo;
    return std::ldexp(U(1.0, 1.9), e) * ((rng() & 1) ? -1.0 : 1.0);
}
static uint64_t bits(double d) { uint64_t u; std::memcpy(&u, &d, 8); return u; }
static int fails = 0;
static void check(const char* name, bool ok, int idx) {
    if (!ok) { if (fails < 10) std::printf("FAIL %s #%d\n", name, idx); fails++; }
}

static void host_nurbs(double u, const double K[6], const double cp[16], double out[3]) {
    auto alpha = [&](double k0, double k1, double& al, double& om) { al = (u - k0) / (k1 - k0); om = 1.0 - al; };
    auto lerp4 = [](const double* a, const double* b, double om, double al, double* y) {
        for (int c = 0; c < 4; c++) y[c] = om * a[c] + al * b[c];
    };
    double d[4][4];
    for (int i = 0; i < 4; i++) {
        d[i][0] = cp[4 * i] * cp[4 * i + 3]; d[i][1] = cp[4 * i + 1] * cp[4 * i + 3];
        d[i][2] = cp[4 * i + 2] * cp[4 * i + 3]; d[i][3] = cp[4 * i + 3];
    }
    double a11, o11, a21, o21, a31, o31, a22, o22, a32, o32, a33, o33;
    alpha(K[0], K[3], a11, o11); alpha(K[1], K[4], a21, o21); alpha(K[2], K[5], a31, o31);
    alpha(K[1], K[3], a22, o22); alpha(K[2], K[4], a32, o32); alpha(K[2], K[3], a33, o33);
    double d11[4], d21[4], d31[4], d22[4], d32[4], f[4];
    lerp4(d[0], d[1], o11, a11, d11); lerp4(d[1], d[2], o21, a21, d21); lerp4(d[2], d[3], o31, a31, d31);
    lerp4(d11, d21, o22, a22, d22); lerp4(d21, d31, o32, a32, d32); lerp4(d22, d32, o33, a33, f);
    out[0] = f[0] / f[3]; out[1] = f[1] / f[3]; out[2] = f[2] / f[3];
}

int main() {
    for (int i = 0; i < 20000; i++) {
        double a = rnd(), b = rnd();
        check("add", bits(chip_fp64_add(a, b)) == bits(a + b), i);
        check("mul", bits(chip_fp64_mul(a, b)) == bits(a * b), i);
        check("div", bits(chip_fp64_div(a, b)) == bits(a / b), i);
    }
    for (int i = 0; i < 5000; i++) {
        double a[3], b[3], o[3];
        for (int k = 0; k < 3; k++) { a[k] = rnd(-8, 8); b[k] = rnd(-8, 8); }
        double hd = (a[0] * b[0] + a[1] * b[1]) + a[2] * b[2];
        check("dot", bits(chip_vec3_dot(a, b)) == bits(hd), i);
        double hc[3] = {a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]};
        chip_vec3_cross(a, b, o);
        check("cross", bits(o[0]) == bits(hc[0]) && bits(o[1]) == bits(hc[1]) && bits(o[2]) == bits(hc[2]), i);
    }
    for (int i = 0; i < 2000; i++) {
        double A[16], B[16], C[16];
        for (int k = 0; k < 16; k++) { A[k] = rnd(-6, 6); B[k] = rnd(-6, 6); }
        chip_mat4_mul(A, B, C);
        bool ok = true;
        for (int r = 0; r < 4; r++)
            for (int c = 0; c < 4; c++) {
                double p0 = A[r * 4] * B[c], p1 = A[r * 4 + 1] * B[4 + c], p2 = A[r * 4 + 2] * B[8 + c], p3 = A[r * 4 + 3] * B[12 + c];
                ok = ok && bits(C[r * 4 + c]) == bits(((p0 + p1) + p2) + p3);
            }
        check("mat4", ok, i);
    }
    auto mkbox = [](double* b) {
        for (int k = 0; k < 3; k++) {
            double x = std::round(U(-4, 4)), y = std::round(U(-4, 4));
            b[k] = std::fmin(x, y); b[k + 3] = std::fmax(x, y);
        }
    };
    auto hit = [](const double* a, const double* b) {
        for (int k = 0; k < 3; k++) if (!(a[k] <= b[k + 3] && b[k] <= a[k + 3])) return 0;
        return 1;
    };
    for (int i = 0; i < 5000; i++) {
        double a[6], b[6]; mkbox(a); mkbox(b);
        check("aabb", chip_aabb_overlap(a, b) == hit(a, b), i);
    }
    for (int i = 0; i < 2000; i++) {
        double q[6], boxes[48]; mkbox(q);
        uint32_t mask = 0;
        for (int j = 0; j < 8; j++) { mkbox(boxes + 6 * j); mask |= (uint32_t)hit(q, boxes + 6 * j) << j; }
        check("aabb8", chip_aabb_multi8(q, boxes) == mask, i);
    }
    for (int i = 0; i < 2000; i++) {
        double K[6], cp[16], out[3], ref[3];
        K[2] = U(-5, 5); K[3] = K[2] + U(0.1, 3);
        K[1] = K[2] - ((rng() % 10 < 3) ? 0.0 : U(0.05, 2)); K[0] = K[1] - ((rng() % 10 < 3) ? 0.0 : U(0.05, 2));
        K[4] = K[3] + ((rng() % 10 < 3) ? 0.0 : U(0.05, 2)); K[5] = K[4] + ((rng() % 10 < 3) ? 0.0 : U(0.05, 2));
        double u = K[2] + (K[3] - K[2]) * U(0, 1);
        if (u >= K[3]) u = K[2];
        for (int m = 0; m < 4; m++) { cp[4 * m] = U(-10, 10); cp[4 * m + 1] = U(-10, 10); cp[4 * m + 2] = U(-10, 10); cp[4 * m + 3] = U(0.5, 3); }
        chip_nurbs3_eval(u, K, cp, out);
        host_nurbs(u, K, cp, ref);
        check("nurbs", bits(out[0]) == bits(ref[0]) && bits(out[1]) == bits(ref[1]) && bits(out[2]) == bits(ref[2]), i);
    }
    if (fails == 0) std::printf("PASS geomchip selftest\n");
    else std::printf("FAIL geomchip selftest: %d hata\n", fails);
    return fails ? 1 : 0;
}
