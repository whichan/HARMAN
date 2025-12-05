`timescale 1ns / 1ps

module top(
    input clk,
    input reset,
    input clear,
    input run_stop,
    input mode,

    input RsRx,
    output RsTx,

    output logic [7:0] fnd_data,
    output logic [3:0] fnd_com
    );

    wire w_mode, w_run_stop, w_clear;
    wire w_debounced_clear, w_debounced_run_stop, w_debounced_mode;

    wire w_total_clear, w_total_run_stop, w_total_mode;
    wire w_uart_clear, w_uart_run_stop, w_uart_mode;
    wire [7:0] w_rx_data;
    wire w_rx_done;


    assign w_total_clear = (w_debounced_clear |  w_uart_clear);
    assign w_total_run_stop = w_debounced_run_stop | w_uart_run_stop;
    assign w_total_mode = w_debounced_mode | w_uart_mode;

    uart_top u_uart_top(
        .clk(clk),
        .reset(reset),

    //tx
        .tx_data(),
        .tx_start(),
        .RsTx(),
        .tx_busy(),

    //rx
        .data_out(w_rx_data),
        .rx_done(w_rx_done),
        .RsRx(RsRx) 
    );

    uart_controller u_uart_controller(
        .clk(clk),
        .reset(reset),
        .rx_data(w_rx_data),
        .rx_done(w_rx_done),
    
        .uart_run_stop(w_uart_run_stop),
        .uart_clear(w_uart_clear),
        .uart_mode(w_uart_mode)
    );

    btn_debounce u_btn_clear(
        .clk(clk),
        .reset(reset),
        .i_btn(clear),
        .o_btn(w_debounced_clear)
    );

    btn_debounce u_btn_run_stop(
        .clk(clk),
        .reset(reset),
        .i_btn(run_stop),
        .o_btn(w_debounced_run_stop)
    );

    btn_debounce u_btn_mode(
        .clk(clk),
        .reset(reset),
        .i_btn(mode),
        .o_btn(w_debounced_mode)
    );

    top_10000_counter u_top_10000_counter(
        .clk(clk),
        .reset(reset),
        .clear(w_clear),
        .run_stop(w_run_stop),
        .mode(w_mode),
        .fnd_data(fnd_data),
        .fnd_com(fnd_com)
    );

    command_controller u_command_controller(
        .clk(clk),
        .reset(reset),
        .mode(w_total_mode),
        .run_stop(w_total_run_stop),
        .clear(w_total_clear),
    
        .o_mode(w_mode),
        .o_run_stop(w_run_stop),
        .o_clear(w_clear)
    );

endmodule