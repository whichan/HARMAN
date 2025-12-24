`timescale 1ns / 1ps

module cpu(
    input       clk,
    input       reset,
    output [7:0] out
    );

    wire src_sel;
    wire a_load;
    wire out_sel;

    datapath u_datapath(
        .*,
        // .clk(clk),
        // .reset(reset),
        // .src_sel(src_sel),
        // .a_load(),
        // .out_sel(),
        .out(out)
    );

    control_unit u_control_unit(
        .*
        // .clk(clk),
        // .reset(reset),
        // .src_sel(),
        // .a_load(),
        // .out_sel()
    );

endmodule