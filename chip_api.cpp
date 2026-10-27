// geomchip C arayuzu: Verilator modellerini cagirir.
#include "geomchip.h"
#include <cstring>

#include "Vfp64_add.h"
#include "Vfp64_mul.h"
#include "Vfp64_div.h"
#include "Vvec3_dot.h"
#include "Vvec3_cross.h"
#include "Vmat4_mul.h"
#include "Vaabb_overlap.h"
#include "Vaabb_multi.h"
#include "Vnurbs3_eval.h"

namespace {
inline uint64_t d2u(double d) { uint64_t u; std::memcpy(&u, &d, 8); return u; }
inline double   u2d(uint64_t u) { double d; std::memcpy(&d, &u, 8); return d; }

// genis portlar 32 bitlik kelimelerden olusur (kucuk uclu): 64 bitlik eleman i -> kelime 2i, 2i+1
template <class W> inline void put64(W& w, int i, uint64_t v) {
    w[2 * i] = (uint32_t)v;
    w[2 * i + 1] = (uint32_t)(v >> 32);
}
template <class W> inline uint64_t get64(const W& w, int i) {
    return ((uint64_t)(uint32_t)w[2 * i + 1] << 32) | (uint64_t)(uint32_t)w[2 * i];
}
template <class M> inline M& model() {
    static M* m = new M;
    return *m;
}
}  // namespace

extern "C" {

uint64_t chip_fp64_add_bits(uint64_t a, uint64_t b) { auto& m = model<Vfp64_add>(); m.a = a; m.b = b; m.eval(); return m.y; }
uint64_t chip_fp64_mul_bits(uint64_t a, uint64_t b) { auto& m = model<Vfp64_mul>(); m.a = a; m.b = b; m.eval(); return m.y; }
uint64_t chip_fp64_div_bits(uint64_t a, uint64_t b) { auto& m = model<Vfp64_div>(); m.a = a; m.b = b; m.eval(); return m.y; }
double chip_fp64_add(double a, double b) { return u2d(chip_fp64_add_bits(d2u(a), d2u(b))); }
double chip_fp64_mul(double a, double b) { return u2d(chip_fp64_mul_bits(d2u(a), d2u(b))); }
double chip_fp64_div(double a, double b) { return u2d(chip_fp64_div_bits(d2u(a), d2u(b))); }

double chip_vec3_dot(const double a[3], const double b[3]) {
    auto& m = model<Vvec3_dot>();
    for (int i = 0; i < 3; i++) { put64(m.a, i, d2u(a[i])); put64(m.b, i, d2u(b[i])); }
    m.eval();
    return u2d(m.y);
}

void chip_vec3_cross(const double a[3], const double b[3], double out[3]) {
    auto& m = model<Vvec3_cross>();
    for (int i = 0; i < 3; i++) { put64(m.a, i, d2u(a[i])); put64(m.b, i, d2u(b[i])); }
    m.eval();
    for (int i = 0; i < 3; i++) out[i] = u2d(get64(m.y, i));
}

void chip_mat4_mul(const double A[16], const double B[16], double C[16]) {
    auto& m = model<Vmat4_mul>();
    for (int i = 0; i < 16; i++) { put64(m.a, i, d2u(A[i])); put64(m.b, i, d2u(B[i])); }
    m.eval();
    for (int i = 0; i < 16; i++) C[i] = u2d(get64(m.c, i));
}

int chip_aabb_overlap(const double a[6], const double b[6]) {
    auto& m = model<Vaabb_overlap>();
    for (int i = 0; i < 6; i++) { put64(m.a, i, d2u(a[i])); put64(m.b, i, d2u(b[i])); }
    m.eval();
    return (int)(m.hit & 1);
}

uint32_t chip_aabb_multi8(const double q[6], const double boxes[48]) {
    auto& m = model<Vaabb_multi>();
    for (int i = 0; i < 6; i++) put64(m.q, i, d2u(q[i]));
    for (int i = 0; i < 48; i++) put64(m.boxes, i, d2u(boxes[i]));
    m.eval();
    return (uint32_t)(m.mask & 0xFF);
}

void chip_nurbs3_eval(double u, const double knots[6], const double cp[16], double out[3]) {
    auto& m = model<Vnurbs3_eval>();
    m.u = d2u(u);
    for (int i = 0; i < 6; i++) put64(m.k, i, d2u(knots[i]));
    for (int i = 0; i < 16; i++) put64(m.cp, i, d2u(cp[i]));
    m.eval();
    for (int i = 0; i < 3; i++) out[i] = u2d(get64(m.pt, i));
}

}  // extern "C"
