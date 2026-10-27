`timescale 1ns/1ps
module tb_dot;
    reg [63:0] mem [0:200000];
    reg [191:0] a, b;
    reg [63:0] e;
    wire [63:0] y;
    integer n, i, fails;
    vec3_dot dut (a, b, y);
    initial begin
        $readmemh("dot.hex", mem);
        n = mem[0]; fails = 0;
        for (i = 0; i < n; i = i + 1) begin
            a = {mem[3+7*i], mem[2+7*i], mem[1+7*i]};
            b = {mem[6+7*i], mem[5+7*i], mem[4+7*i]};
            e = mem[7+7*i];
            #1;
            if (y !== e) begin
                fails = fails + 1;
                if (fails <= 5) $display("FAIL dot #%0d got=%h exp=%h", i, y, e);
            end
        end
        if (fails == 0) $display("PASS tb_dot %0d tests", n);
        else            $display("FAIL tb_dot %0d of %0d", fails, n);
        $finish;
    end
endmodule
