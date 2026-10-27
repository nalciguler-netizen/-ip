// 3D vektor ve 4x4 matris birimleri (float64). Tum degerler duz (flat) baralarda:
//   vektor: {z,y,x} -> x=[63:0], y=[127:64], z=[191:128]
//   matris: satir-oncelikli, eleman (i,j) = [64*(4*i+j) +: 64]
// Islem sirasi referans modelle birebir ayni (FMA yok): ((p0+p1)+p2)+p3

module vec3_dot (
    input  [191:0] a,
    input  [191:0] b,
    output [63:0]  y
);
    wire [63:0] px, py, pz, s1;
    fp64_mul mx (a[63:0],    b[63:0],    px);
    fp64_mul my (a[127:64],  b[127:64],  py);
    fp64_mul mz (a[191:128], b[191:128], pz);
    fp64_add a1 (px, py, s1);
    fp64_add a2 (s1, pz, y);
endmodule

module vec3_cross (
    input  [191:0] a,
    input  [191:0] b,
    output [191:0] y
);
    wire [63:0] ax = a[63:0],   ay = a[127:64],  az = a[191:128];
    wire [63:0] bx = b[63:0],   by = b[127:64],  bz = b[191:128];
    wire [63:0] t1, t2, t3, t4, t5, t6;
    fp64_mul m1 (ay, bz, t1);
    fp64_mul m2 (az, by, t2);
    fp64_mul m3 (az, bx, t3);
    fp64_mul m4 (ax, bz, t4);
    fp64_mul m5 (ax, by, t5);
    fp64_mul m6 (ay, bx, t6);
    fp64_add s1 (t1, {~t2[63], t2[62:0]}, y[63:0]);
    fp64_add s2 (t3, {~t4[63], t4[62:0]}, y[127:64]);
    fp64_add s3 (t5, {~t6[63], t6[62:0]}, y[191:128]);
endmodule

module fp64_dot4 (
    input  [255:0] a,
    input  [255:0] b,
    output [63:0]  y
);
    wire [63:0] p0, p1, p2, p3, s1, s2;
    fp64_mul m0 (a[63:0],    b[63:0],    p0);
    fp64_mul m1 (a[127:64],  b[127:64],  p1);
    fp64_mul m2 (a[191:128], b[191:128], p2);
    fp64_mul m3 (a[255:192], b[255:192], p3);
    fp64_add a1 (p0, p1, s1);
    fp64_add a2 (s1, p2, s2);
    fp64_add a3 (s2, p3, y);
endmodule

module mat4_mul (
    input  [1023:0] a,
    input  [1023:0] b,
    output [1023:0] c
);
    genvar i, j;
    generate
        for (i = 0; i < 4; i = i + 1) begin : row
            for (j = 0; j < 4; j = j + 1) begin : col
                wire [255:0] ra = a[256*i +: 256];
                wire [255:0] cb = { b[64*(12+j) +: 64], b[64*(8+j) +: 64],
                                    b[64*(4+j)  +: 64], b[64*(0+j) +: 64] };
                fp64_dot4 u (ra, cb, c[64*(4*i+j) +: 64]);
            end
        end
    endgenerate
endmodule
