// Evre 3: Matematiksel egri birimi - kubik (derece 3) rasyonel B-spline (NURBS) noktasi, float64, kombinasyonel.
// Yontem: homojen koordinatlarda De Boor algoritmasi, sonra w'ye bolme.
//
// Arayuz nurbs3_eval:
//   u   : parametre; K0 <= ... ; K2 <= u < K3 olmali (K2 < K3)
//   k   : 6 dugum K0..K5 = t[i-2]..t[i+3] (aktif aralik [K2,K3)); eleman n = k[64*n +: 64]
//   cp  : 4 kontrol noktasi P[i-3]..P[i], her biri (x,y,z,w); bilesen c of nokta m = cp[64*(4*m+c) +: 64]
//   pt  : sonuc {z,y,x}; x=[63:0]
// Yuvarlama RNE, alt-normal sayilar sifira yuvarlanir (flush-to-zero).

// IEEE-754 float64 bolucu (a / b), kombinasyonel.
module fp64_div (
    input  [63:0] a,
    input  [63:0] b,
    output reg [63:0] y
);
    localparam [63:0] QNAN = 64'h7FF8000000000000;

    reg         s, a_nan, b_nan, a_inf, b_inf, a_zero, b_zero;
    reg [107:0] num, den, quo, rmd;
    reg [55:0]  q;
    reg [52:0]  mant;
    reg [53:0]  mr;
    reg         guard, sticky, inc;
    integer     e;

    always @* begin
        s      = a[63] ^ b[63];
        a_nan  = (a[62:52] == 11'h7FF) && (a[51:0] != 52'd0);
        b_nan  = (b[62:52] == 11'h7FF) && (b[51:0] != 52'd0);
        a_inf  = (a[62:52] == 11'h7FF) && (a[51:0] == 52'd0);
        b_inf  = (b[62:52] == 11'h7FF) && (b[51:0] == 52'd0);
        a_zero = (a[62:52] == 11'd0);
        b_zero = (b[62:52] == 11'd0);

        num = 108'd0; den = 108'd0; quo = 108'd0; rmd = 108'd0; q = 56'd0;
        mant = 53'd0; mr = 54'd0; guard = 1'b0; sticky = 1'b0; inc = 1'b0; e = 0;

        if (a_nan | b_nan)         y = QNAN;
        else if (a_inf & b_inf)    y = QNAN;
        else if (a_zero & b_zero)  y = QNAN;
        else if (a_inf)            y = {s, 11'h7FF, 52'd0};
        else if (b_zero)           y = {s, 11'h7FF, 52'd0};
        else if (b_inf)            y = {s, 63'd0};
        else if (a_zero)           y = {s, 63'd0};
        else begin
            num = {1'b1, a[51:0], 55'd0};
            den = {55'd0, 1'b1, b[51:0]};
            quo = num / den;
            rmd = num % den;
            q   = quo[55:0];
            e   = a[62:52];
            e   = e - b[62:52] + 1023;
            if (q[55]) begin
                mant   = q[55:3];
                guard  = q[2];
                sticky = (|q[1:0]) | (rmd != 108'd0);
            end else begin
                mant   = q[54:2];
                guard  = q[1];
                sticky = q[0] | (rmd != 108'd0);
                e      = e - 1;
            end
            inc = guard & (sticky | mant[0]);
            mr  = {1'b0, mant} + inc;
            if (mr[53]) begin
                mr = mr >> 1;
                e  = e + 1;
            end
            if (e >= 2047)     y = {s, 11'h7FF, 52'd0};
            else if (e <= 0)   y = {s, 63'd0};
            else               y = {s, e[10:0], mr[51:0]};
        end
    end
endmodule

// alfa = (u - k0) / (k1 - k0),  om = 1 - alfa
module nurbs_alpha (
    input  [63:0] u,
    input  [63:0] k0,
    input  [63:0] k1,
    output [63:0] al,
    output [63:0] om
);
    wire [63:0] num, den;
    fp64_add n (u,  {~k0[63], k0[62:0]}, num);
    fp64_add d (k1, {~k0[63], k0[62:0]}, den);
    fp64_div q (num, den, al);
    fp64_add o (64'h3FF0000000000000, {~al[63], al[62:0]}, om);
endmodule

// 4 bilesenli dogrusal ara deger: y = om*a + al*b
module nurbs_lerp4 (
    input  [255:0] a,
    input  [255:0] b,
    input  [63:0]  om,
    input  [63:0]  al,
    output [255:0] y
);
    genvar c;
    generate
        for (c = 0; c < 4; c = c + 1) begin : g
            wire [63:0] t1, t2;
            fp64_mul m1 (om, a[64*c +: 64], t1);
            fp64_mul m2 (al, b[64*c +: 64], t2);
            fp64_add ad (t1, t2, y[64*c +: 64]);
        end
    endgenerate
endmodule

module nurbs3_eval (
    input  [63:0]   u,
    input  [383:0]  k,
    input  [1023:0] cp,
    output [191:0]  pt
);
    // homojen noktalar: (x*w, y*w, z*w, w)
    wire [1023:0] dh;
    genvar m;
    generate
        for (m = 0; m < 4; m = m + 1) begin : hp
            fp64_mul mx (cp[256*m +: 64],       cp[256*m + 192 +: 64], dh[256*m +: 64]);
            fp64_mul my (cp[256*m + 64  +: 64], cp[256*m + 192 +: 64], dh[256*m + 64  +: 64]);
            fp64_mul mz (cp[256*m + 128 +: 64], cp[256*m + 192 +: 64], dh[256*m + 128 +: 64]);
            assign dh[256*m + 192 +: 64] = cp[256*m + 192 +: 64];
        end
    endgenerate
    wire [255:0] d0 = dh[255:0],   d1 = dh[511:256];
    wire [255:0] d2 = dh[767:512], d3 = dh[1023:768];

    wire [63:0] K0 = k[63:0],    K1 = k[127:64],  K2 = k[191:128];
    wire [63:0] K3 = k[255:192], K4 = k[319:256], K5 = k[383:320];

    wire [63:0] al11, om11, al21, om21, al31, om31, al22, om22, al32, om32, al33, om33;
    nurbs_alpha a11 (u, K0, K3, al11, om11);
    nurbs_alpha a21 (u, K1, K4, al21, om21);
    nurbs_alpha a31 (u, K2, K5, al31, om31);
    nurbs_alpha a22 (u, K1, K3, al22, om22);
    nurbs_alpha a32 (u, K2, K4, al32, om32);
    nurbs_alpha a33 (u, K2, K3, al33, om33);

    wire [255:0] d11, d21, d31, d22, d32, f;
    nurbs_lerp4 l11 (d0,  d1,  om11, al11, d11);
    nurbs_lerp4 l21 (d1,  d2,  om21, al21, d21);
    nurbs_lerp4 l31 (d2,  d3,  om31, al31, d31);
    nurbs_lerp4 l22 (d11, d21, om22, al22, d22);
    nurbs_lerp4 l32 (d21, d31, om32, al32, d32);
    nurbs_lerp4 l33 (d22, d32, om33, al33, f);

    fp64_div dx (f[63:0],    f[255:192], pt[63:0]);
    fp64_div dy (f[127:64],  f[255:192], pt[127:64]);
    fp64_div dz (f[191:128], f[255:192], pt[191:128]);
endmodule
