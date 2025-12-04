`timescale 1ns / 1ps

module uart_top(
    input clk,
    input reset,

    //tx
    input [7:0] tx_data,
    input tx_start,
    input RsTx,
    output tx_busy,

    //rx
    output data_out,
    output rx_done,
    input RsRx   
    );

    uart_tx u_uart_tx(
    .clk(clk),
    .reset(reset),
    .tx_data(tx_data),
    .tx_start(tx_start),
    .tx(RsTx),
    .tx_busy(tx_busy),
    .tx_done(tx_done)
    );

    uart_rx u_uart_rx(
        .clk(clk),
        .reset(reset),
        .rx(RsRx),
        .data_out(data_out),
        .rx_done(rx_done)
    );

endmodule
