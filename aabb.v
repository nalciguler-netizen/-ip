// Evre 2: Uzamsal indeksleyici blogu - AABB (eksen hizali kutu) kesisim testi, float64, kombinasyonel.
// Kutu duzeni (384 bit): eleman i = [64*i +: 64]; i=0..2 -> min x,y,z ; i=3..5 -> max x,y,z
// Kapali araliklar: kenarlari degen kutular kesisir sayilir. NaN iceren karsilastirma "kesismez" verir.

// a <= b (IEEE-754 float64; +0 == -0; NaN -> 0)
module fp64_le (
    input  [63:0] a,
    input  [63:0] b,
    output        y
);
    wire a_nan     = (a[62:52] == 11'h7FF) && (a[51:0] != 52'd0);
    wire b_nan     = (b[62:52] == 11'h7FF) && (b[51:0] != 52'd0);
    wire both_zero = (a[62:0] == 63'd0) && (b[62:0] == 63'd0);
    wire sdiff     = a[63] ^ b[63];
    wire mag_le    = a[62:0] <= b[62:0];
    wire mag_ge    = a[62:0] >= b[62:0];
    assign y = (a_nan | b_nan) ? 1'b0 :
               both_zero       ? 1'b1 :
               sdiff           ? a[63] :
               a[63]           ? mag_ge : mag_le;
endmodule

module aabb_overlap (
    input  [383:0] a,
    input  [383:0] b,
    output         hit
);
    wire [2:0] c1, c2;
    genvar k;
    generate
        for (k = 0; k < 3; k = k + 1) begin : ax
            fp64_le l1 (a[64*k +: 64], b[64*(k+3) +: 64], c1[k]);   // a.min <= b.max
            fp64_le l2 (b[64*k +: 64], a[64*(k+3) +: 64], c2[k]);   // b.min <= a.max
        end
    endgenerate
    assign hit = (&c1) & (&c2);
endmodule

// Bir sorgu kutusunu N kutuya karsi ayni anda test eder; mask[i] = 1 -> kutu i kesisiyor.
module aabb_multi #(parameter N = 8) (
    input  [383:0]     q,
    input  [384*N-1:0] boxes,
    output [N-1:0]     mask
);
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : u
            aabb_overlap o (q, boxes[384*i +: 384], mask[i]);
        end
    endgenerate
endmodule
