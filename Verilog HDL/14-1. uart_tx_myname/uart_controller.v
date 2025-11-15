`timescale 1ns / 1ps

module uart_controller(
    input clk,
    input reset,
    input [7:0] send_data,
    input rx,
    output [7:0] rx_data,
    output rx_done,
    output tx
    );

    wire w_tick_1hz;
    wire w_tx_busy, w_tx_done, w_tx_start;
    wire [7:0] w_tx_data;

    tick_generator  #(
        .INPUT_FREQ(100_000_000),
        .TICK_Hz(1)
    ) u_tick_1hz(
        .clk(clk),
        .reset(reset),
        .tick(w_tick_1hz)
    );

    data_sender u_data_sender(
        .clk(clk),
        .reset(reset),
        .send_data(8'h30),
        .start_trigger(w_tick_1hz),
        .tx_busy(w_tx_busy),
        .tx_done(w_tx_done),
        .tx_data(w_tx_data),
        .tx_start(w_tx_start)
    );

    uart_tx u_uart_tx(
        .clk(clk),
        .reset(reset),
        .tx_data(w_tx_data),
        .tx_start(w_tx_start), 
        .tx(tx),
        .tx_busy(w_tx_busy),
        .tx_done(w_tx_done)
    );

    /*uart_rx u_uart_rx(
        
    );*/


endmodule
