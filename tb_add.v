`timescale 1ns/1ps
module tb_add;
    reg [63:0] mem [0:200000];
    reg [63:0] a, b, e;
    wire [63:0] y;
    integer n, i, fails;
    fp64_add dut (a, b, y);
    function is_nan(input [63:0] x);
        is_nan = (x[62:52] == 11'h7FF) && (x[51:0] != 52'd0);
    endfunction
    initial begin
        $readmemh("add.hex", mem);
        n = mem[0]; fails = 0;
        for (i = 0; i < n; i = i + 1) begin
            a = mem[1+3*i]; b = mem[2+3*i]; e = mem[3+3*i];
            #1;
            if (is_nan(e) ? !is_nan(y) : (y !== e)) begin
                fails = fails + 1;
                if (fails <= 5) $display("FAIL add #%0d a=%h b=%h got=%h exp=%h", i, a, b, y, e);
            end
        end
        if (fails == 0) $display("PASS tb_add %0d tests", n);
        else            $display("FAIL tb_add %0d of %0d", fails, n);
        $finish;
    end
endmodule
