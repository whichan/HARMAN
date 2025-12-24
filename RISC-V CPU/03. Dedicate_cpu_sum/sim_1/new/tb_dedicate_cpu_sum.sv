`timescale 1ns / 1ps

module tb_dedicate_cpu_sum();
    logic       clk;
    logic       reset;
    logic [7:0] out;

    dedicate_cpu_sum u_dedicate_cpu_sum(
        .clk(clk),
        .reset(reset),
        .out(out)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        #0;
        reset = 1;
        #10;
        reset = 0;

        #4000;
        $stop;
    end
endmodule
