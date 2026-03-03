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

    //uart
    wire [7:0] w_rx_data;
    wire w_rx_done;
    wire [7:0] w_tx_data;
    wire w_tx_start;
    wire w_tx_busy;
    wire w_tx_done;


    wire [13:0] w_current_count;
    wire w_current_mode;
    wire w_send_trigger;

    wire [7:0] w_monitor_data;
    wire w_monitor_valid;
    wire w_ext_tx_data, w_ext_tx_start, w_ext_tx_busy;

    wire [13:0] w_set_value;
    wire w_set_en;

    //'s'오류 수정: sender가 일하는 중인지 알려주는 wire 추가
    wire w_sender_active;

    wire [7:0] w_sender_tx_data;
    wire w_sender_tx_start;
    wire w_sender_tx_busy;
    wire w_sender_tx_done;

    uart_loopback u_uart_loopback(
        .clk(clk),
        .reset(reset),
        
        .RsTx(RsTx),
        .RsRx(RsRx),
        
        .monitor_data(w_monitor_data),
        .monitor_valid(w_monitor_valid),

        .ext_tx_data(w_sender_tx_data),
        .ext_tx_start(w_sender_tx_start),
        .ext_tx_busy(w_sender_tx_busy),

        .sender_active(w_sender_active)
    );

    // uart_top u_uart_top(
    //     .clk(clk),
    //     .reset(reset),

    // //tx
    //     .tx_data(w_tx_data),
    //     .tx_start(w_tx_start),
    //     .RsTx(RsTx),
    //     .tx_busy(w_tx_busy),
    //     .tx_done(w_tx_done),
    // //rx
    //     .data_out(w_rx_data),
    //     .rx_done(w_rx_done),
    //     .RsRx(RsRx) 
    // );

    uart_controller u_uart_controller(
        .clk(clk),
        .reset(reset),
        .rx_data(w_monitor_data),
        .rx_done(w_monitor_valid),
    
        .uart_run_stop(w_uart_run_stop),
        .uart_clear(w_uart_clear),
        .uart_mode(w_uart_mode),
        .uart_status(w_send_trigger),

        .set_value(w_set_value), //0~9999
        .set_en(w_set_en) //set 명령어 완료 pulse
    );

    data_sender u_data_sender(
        .clk(clk),
        .reset(reset),
        .start_trigger(w_send_trigger),
        .current_cnt(w_current_count),  // 0~9999
        .current_mode(w_current_mode), // 0: down, 1: up
        //.tx_done(w_tx_done),
        .tx_busy(w_sender_tx_busy),

        .tx_start(w_sender_tx_start),
        .tx_data(w_sender_tx_data),
        .busy(w_sender_active)
    );

    btn_debounce u_btn_debounce_clear(
        .clk(clk),
        .reset(reset),
        .i_btn(clear),
        .o_btn_pulse(w_debounced_clear),
        .o_btn_toggle()
    );

    btn_debounce u_btn_debounce_run_stop(
        .clk(clk),
        .reset(reset),
        .i_btn(run_stop),
        .o_btn_pulse(),
        .o_btn_toggle(w_debounced_run_stop)
    );

    btn_debounce u_btn_debounce_mode(
        .clk(clk),
        .reset(reset),
        .i_btn(mode),
        .o_btn_pulse(),
        .o_btn_toggle(w_debounced_mode)
    );

    assign w_total_clear = w_debounced_clear |  w_uart_clear;
    assign w_total_run_stop = w_debounced_run_stop ^ w_uart_run_stop;
    assign w_total_mode = w_debounced_mode ^ w_uart_mode;

    top_10000_counter u_top_10000_counter(
        .clk(clk),
        .reset(reset),
        .clear(w_clear),
        .run_stop(w_run_stop),
        .mode(w_mode),
        .fnd_data(fnd_data),
        .fnd_com(fnd_com),

        .set_value(w_set_value),
        .set_en(w_set_en),

        .current_count(w_current_count),
        .current_mode(w_current_mode)
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