`timescale 1ns/1ps
module tb_div;
    reg [63:0] mem [0:200000];
    reg [63:0] a, b, e;
    wire [63:0] y;
    integer n, i, fails;
    fp64_div dut (a, b, y);
    function is_nan(input [63:0] x);
        is_nan = (x[62:52] == 11'h7FF) && (x[51:0] != 52'd0);
    endfunction
    initial begin
        $readmemh("div.hex", mem);
        n = mem[0]; fails = 0;
        for (i = 0; i < n; i = i + 1) begin
            a = mem[1+3*i]; b = mem[2+3*i]; e = mem[3+3*i];
            #1;
            if (is_nan(e) ? !is_nan(y) : (y !== e)) begin
                fails = fails + 1;
                if (fails <= 5) $display("FAIL div #%0d a=%h b=%h got=%h exp=%h", i, a, b, y, e);
            end
        end
        if (fails == 0) $display("PASS tb_div %0d tests", n);
        else            $display("FAIL tb_div %0d of %0d", fails, n);
        $finish;
    end
endmodule
