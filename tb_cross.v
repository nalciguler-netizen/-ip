`timescale 1ns/1ps
module tb_cross;
    reg [63:0] mem [0:200000];
    reg [191:0] a, b, e;
    wire [191:0] y;
    integer n, i, fails;
    vec3_cross dut (a, b, y);
    initial begin
        $readmemh("cross.hex", mem);
        n = mem[0]; fails = 0;
        for (i = 0; i < n; i = i + 1) begin
            a = {mem[3+9*i], mem[2+9*i], mem[1+9*i]};
            b = {mem[6+9*i], mem[5+9*i], mem[4+9*i]};
            e = {mem[9+9*i], mem[8+9*i], mem[7+9*i]};
            #1;
            if (y !== e) begin
                fails = fails + 1;
                if (fails <= 5) $display("FAIL cross #%0d got=%h exp=%h", i, y, e);
            end
        end
        if (fails == 0) $display("PASS tb_cross %0d tests", n);
        else            $display("FAIL tb_cross %0d of %0d", fails, n);
        $finish;
    end
endmodule
