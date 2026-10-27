// IEEE-754 cift duyarlikli (float64) carpici, kombinasyonel.
// Yuvarlama: en yakin, esitlikte cifte (RNE). Alt-normal girdi/sonuc sifira yuvarlanir (flush-to-zero).
module fp64_mul (
    input  [63:0] a,
    input  [63:0] b,
    output reg [63:0] y
);
    localparam [63:0] QNAN = 64'h7FF8000000000000;

    reg        s, a_nan, b_nan, a_inf, b_inf, a_zero, b_zero;
    reg [105:0] p;
    reg [52:0] mant;
    reg [53:0] mr;
    reg        guard, sticky, inc;
    integer    e;

    always @* begin
        s      = a[63] ^ b[63];
        a_nan  = (a[62:52] == 11'h7FF) && (a[51:0] != 52'd0);
        b_nan  = (b[62:52] == 11'h7FF) && (b[51:0] != 52'd0);
        a_inf  = (a[62:52] == 11'h7FF) && (a[51:0] == 52'd0);
        b_inf  = (b[62:52] == 11'h7FF) && (b[51:0] == 52'd0);
        a_zero = (a[62:52] == 11'd0);
        b_zero = (b[62:52] == 11'd0);

        p = 106'd0; mant = 53'd0; mr = 54'd0; guard = 1'b0; sticky = 1'b0; inc = 1'b0; e = 0;

        if (a_nan | b_nan)                       y = QNAN;
        else if ((a_inf & b_zero) | (b_inf & a_zero)) y = QNAN;
        else if (a_inf | b_inf)                  y = {s, 11'h7FF, 52'd0};
        else if (a_zero | b_zero)                y = {s, 63'd0};
        else begin
            p = {53'd0, 1'b1, a[51:0]} * {53'd0, 1'b1, b[51:0]};
            e = a[62:52];
            e = e + b[62:52] - 1023;
            if (p[105]) begin
                mant   = p[105:53];
                guard  = p[52];
                sticky = |p[51:0];
                e      = e + 1;
            end else begin
                mant   = p[104:52];
                guard  = p[51];
                sticky = |p[50:0];
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
