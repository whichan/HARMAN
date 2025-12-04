`timescale 1ns / 1ps

module tb_uart_tx();

    reg clk;
    reg reset;
    reg [7:0] tx_data;
    reg tx_start;
    wire tx;
    wire tx_busy;
    wire tx_done;

    uart_tx tb_u_uart_tx(
        .clk(clk),
        .reset(reset),
        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx(tx),
        .tx_busy(tx_busy),
        .tx_done(tx_done)
    );

    
endmodule
