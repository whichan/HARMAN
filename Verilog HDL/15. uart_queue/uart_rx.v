`timescale 1ns / 1ps

module uart_rx(
    input clk,
    input reset,
    input rx,
    output reg [7:0] data_out,
    output reg rx_done
    );
endmodule
