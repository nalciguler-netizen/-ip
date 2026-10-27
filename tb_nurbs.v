`timescale 1ns/1ps
module tb_nurbs;
    reg [63:0] mem [0:200000];
    reg [63:0] u;
    reg [383:0] k;
    reg [1023:0] cp;
    reg [191:0] e;
    wire [191:0] pt;
    integer n, i, q, base, fails;
    nurbs3_eval dut (u, k, cp, pt);
    initial begin
        $readmemh("nurbs.hex", mem);
        n = mem[0]; fails = 0;
        for (i = 0; i < n; i = i + 1) begin
            base = 1 + 26*i;
            u = mem[base];
            for (q = 0; q < 6; q = q + 1)  k[64*q +: 64]  = mem[base + 1 + q];
            for (q = 0; q < 16; q = q + 1) cp[64*q +: 64] = mem[base + 7 + q];
            for (q = 0; q < 3; q = q + 1)  e[64*q +: 64]  = mem[base + 23 + q];
            #1;
            if (pt !== e) begin
                fails = fails + 1;
                if (fails <= 3) $display("FAIL nurbs #%0d got=%h exp=%h", i, pt, e);
            end
        end
        if (fails == 0) $display("PASS tb_nurbs %0d tests", n);
        else            $display("FAIL tb_nurbs %0d of %0d", fails, n);
        $finish;
    end
endmodule
