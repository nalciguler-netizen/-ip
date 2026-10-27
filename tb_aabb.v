`timescale 1ns/1ps
module tb_aabb;
    reg [63:0] mem [0:200000];
    reg [383:0] a, b;
    reg e;
    wire hit;
    integer n, i, k, fails;
    aabb_overlap dut (a, b, hit);
    initial begin
        $readmemh("aabb.hex", mem);
        n = mem[0]; fails = 0;
        for (i = 0; i < n; i = i + 1) begin
            for (k = 0; k < 6; k = k + 1) begin
                a[64*k +: 64] = mem[1 + 13*i + k];
                b[64*k +: 64] = mem[1 + 13*i + 6 + k];
            end
            e = mem[1 + 13*i + 12];
            #1;
            if (hit !== e) begin
                fails = fails + 1;
                if (fails <= 5) $display("FAIL aabb #%0d got=%b exp=%b", i, hit, e);
            end
        end
        if (fails == 0) $display("PASS tb_aabb %0d tests", n);
        else            $display("FAIL tb_aabb %0d of %0d", fails, n);
        $finish;
    end
endmodule
