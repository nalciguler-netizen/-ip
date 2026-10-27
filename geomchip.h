/* geomchip: sanal cipin (Verilog) Verilator ile uretilmis C++ modeli icin C arayuzu.
 * Cipin davranisini birebir taklit eder (IEEE-754 float64, RNE; alt-normal sayilar sifira yuvarlanir).
 * Dizi duzenleri:
 *   vektor: {x,y,z}              matris: satir-oncelikli 4x4 (16 eleman)
 *   AABB:   {minx,miny,minz,maxx,maxy,maxz}
 *   NURBS:  knots[6] = t[i-2]..t[i+3] (aktif aralik [knots[2], knots[3]));
 *           cp[16]   = 4 nokta x {x,y,z,w}
 * Thread-safe DEGIL: her cagri ortak bir model orneginin uzerinde calisir. */
#ifndef GEOMCHIP_H
#define GEOMCHIP_H
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif

uint64_t chip_fp64_add_bits(uint64_t a, uint64_t b);
uint64_t chip_fp64_mul_bits(uint64_t a, uint64_t b);
uint64_t chip_fp64_div_bits(uint64_t a, uint64_t b);
double   chip_fp64_add(double a, double b);
double   chip_fp64_mul(double a, double b);
double   chip_fp64_div(double a, double b);

double   chip_vec3_dot(const double a[3], const double b[3]);
void     chip_vec3_cross(const double a[3], const double b[3], double out[3]);
void     chip_mat4_mul(const double A[16], const double B[16], double C[16]);

int      chip_aabb_overlap(const double a[6], const double b[6]);
/* q kutusunu 8 kutuya karsi test eder; sonuc bit maskesi (bit i = kutu i kesisiyor) */
uint32_t chip_aabb_multi8(const double q[6], const double boxes[48]);

void     chip_nurbs3_eval(double u, const double knots[6], const double cp[16], double out[3]);

#ifdef __cplusplus
}
#endif
#endif
