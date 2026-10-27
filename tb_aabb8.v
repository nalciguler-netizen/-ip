`timescale 1ns/1ps
module tb_aabb8;
    reg [63:0] mem [0:200000];
    reg [383:0] q;
    reg [3071:0] boxes;
    reg [7:0] e;
    wire [7:0] mask;
    integer n, i, k, fails;
    aabb_multi #(.N(8)) dut (q, boxes, mask);
    initial begin
        $readmemh("aabb8.hex", mem);
        n = mem[0]; fails = 0;
        for (i = 0; i < n; i = i + 1) begin
            for (k = 0; k < 6; k = k + 1)
                q[64*k +: 64] = mem[1 + 55*i + k];
            for (k = 0; k < 48; k = k + 1)
                boxes[64*k +: 64] = mem[1 + 55*i + 6 + k];
            e = mem[1 + 55*i + 54];
            #1;
            if (mask !== e) begin
                fails = fails + 1;
                if (fails <= 5) $display("FAIL aabb8 #%0d got=%b exp=%b", i, mask, e);
            end
        end
        if (fails == 0) $display("PASS tb_aabb8 %0d tests", n);
        else            $display("FAIL tb_aabb8 %0d of %0d", fails, n);
        $finish;
    end
endmodule
