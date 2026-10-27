`timescale 1ns/1ps
module tb_mat4;
    reg [63:0] mem [0:200000];
    reg [1023:0] a, b, e;
    wire [1023:0] y;
    integer n, i, k, fails;
    mat4_mul dut (a, b, y);
    initial begin
        $readmemh("mat4.hex", mem);
        n = mem[0]; fails = 0;
        for (i = 0; i < n; i = i + 1) begin
            for (k = 0; k < 16; k = k + 1) begin
                a[64*k +: 64] = mem[1 + 48*i + k];
                b[64*k +: 64] = mem[1 + 48*i + 16 + k];
                e[64*k +: 64] = mem[1 + 48*i + 32 + k];
            end
            #1;
            if (y !== e) begin
                fails = fails + 1;
                if (fails <= 3) $display("FAIL mat4 #%0d", i);
            end
        end
        if (fails == 0) $display("PASS tb_mat4 %0d tests", n);
        else            $display("FAIL tb_mat4 %0d of %0d", fails, n);
        $finish;
    end
endmodule
