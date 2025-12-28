`timescale 1ns / 1ps

module dedicate_cpu_reg(
    input        clk,
    input        reset,
    output [7:0] out
    );

    wire rf_src_sel, we, out_load, ale10;
    wire [1:0] raddr1, raddr2, waddr;

    datapath_reg u_datapath_reg(
        .*,
        .out(out)
    );

    control_unit_reg u_control_unit_reg(
        .*
    );

endmodule