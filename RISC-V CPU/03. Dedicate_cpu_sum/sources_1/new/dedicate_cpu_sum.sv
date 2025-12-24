`timescale 1ns / 1ps

module dedicate_cpu_sum(
    input        clk,
    input        reset,
    output [7:0] out
);

    wire a_src_sel, a_load, sum_src_sel,
         sum_load, alu_src_sel, ale10, out_load;

    datapath u_datapath(
        // input        clk,
        // input        reset,
        // input        a_src_sel,
        // input        sum_src_sel,
        // input        a_load,
        // input        sum_load,
        // input        alu_src_sel,
        // input        out_load,

        // output       ale10,
        .*,
        .out(out)
    );

    control_unit u_control_unit(
        .*
    );
endmodule