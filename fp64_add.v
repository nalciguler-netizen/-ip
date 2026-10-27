// IEEE-754 cift duyarlikli (float64) toplayici, kombinasyonel. Cikarma icin b'nin isaret bitini cevir.
// Yuvarlama: en yakin, esitlikte cifte (RNE). Alt-normal girdi/sonuc sifira yuvarlanir (flush-to-zero).
module fp64_add (
    input  [63:0] a,
    input  [63:0] b,
    output reg [63:0] y
);
    localparam [63:0] QNAN = 64'h7FF8000000000000;

    reg         a_nan, b_nan, a_inf, b_inf, a_zero, b_zero;
    reg  [63:0] hi_op, lo_op;
    reg  [55:0] m_big, m_small, shifted;
    reg  [10:0] ediff;
    reg  [5:0]  ediff_c;
    reg  [111:0] ext;
    reg         sticky, eff_sub, sgn;
    reg  [56:0] sum, nm;
    reg  [52:0] mant;
    reg  [53:0] mr;
    reg         guard, rem, inc;
    integer     i, p, lz, e;

    always @* begin
        a_nan  = (a[62:52] == 11'h7FF) && (a[51:0] != 52'd0);
        b_nan  = (b[62:52] == 11'h7FF) && (b[51:0] != 52'd0);
        a_inf  = (a[62:52] == 11'h7FF) && (a[51:0] == 52'd0);
        b_inf  = (b[62:52] == 11'h7FF) && (b[51:0] == 52'd0);
        a_zero = (a[62:52] == 11'd0);
        b_zero = (b[62:52] == 11'd0);

        hi_op = 64'd0; lo_op = 64'd0; m_big = 56'd0; m_small = 56'd0; shifted = 56'd0;
        ediff = 11'd0; ediff_c = 6'd0; ext = 112'd0; sticky = 1'b0; eff_sub = 1'b0; sgn = 1'b0;
        sum = 57'd0; nm = 57'd0; mant = 53'd0; mr = 54'd0; guard = 1'b0; rem = 1'b0; inc = 1'b0;
        p = 0; lz = 0; e = 0;

        if (a_nan | b_nan)            y = QNAN;
        else if (a_inf & b_inf)       y = (a[63] == b[63]) ? a : QNAN;
        else if (a_inf)               y = a;
        else if (b_inf)               y = b;
        else if (a_zero & b_zero)     y = {a[63] & b[63], 63'd0};
        else if (a_zero)              y = b;
        else if (b_zero)              y = a;
        else begin
            if (a[62:0] >= b[62:0]) begin hi_op = a; lo_op = b; end
            else                    begin hi_op = b; lo_op = a; end

            ediff   = hi_op[62:52] - lo_op[62:52];
            m_big   = {1'b1, hi_op[51:0],   3'b000};
            m_small = {1'b1, lo_op[51:0], 3'b000};
            ediff_c = (ediff > 11'd60) ? 6'd60 : ediff[5:0];
            ext     = {m_small, 56'd0} >> ediff_c;
            shifted = ext[111:56];
            sticky  = |ext[55:0];
            eff_sub = hi_op[63] ^ lo_op[63];
            sgn     = hi_op[63];

            if (eff_sub) sum = {1'b0, m_big} - {1'b0, shifted} - {56'd0, sticky};
            else         sum = {1'b0, m_big} + {1'b0, shifted};

            if (sum == 57'd0) begin
                y = 64'd0;
            end else begin
                for (i = 0; i < 57; i = i + 1)
                    if (sum[i]) p = i;
                lz = 56 - p;
                nm = sum << lz;
                e  = hi_op[62:52];
                e  = e + 1 - lz;
                mant  = nm[56:4];
                guard = nm[3];
                rem   = (|nm[2:0]) | sticky;
                inc   = guard & (rem | mant[0]);
                mr    = {1'b0, mant} + inc;
                if (mr[53]) begin
                    mr = mr >> 1;
                    e  = e + 1;
                end
                if (e >= 2047)     y = {sgn, 11'h7FF, 52'd0};
                else if (e <= 0)   y = {sgn, 63'd0};
                else               y = {sgn, e[10:0], mr[51:0]};
            end
        end
    end
endmodule
