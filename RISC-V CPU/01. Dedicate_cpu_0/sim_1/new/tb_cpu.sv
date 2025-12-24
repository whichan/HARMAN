`timescale 1ns / 1ps

module tb_cpu();

    logic      clk;
    logic      reset;
    logic [7:0] out;

    cpu u_cpu(
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

        #100;
        $stop;
    end

endmodule
