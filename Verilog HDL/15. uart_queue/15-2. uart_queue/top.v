`timescale 1ns / 1ps

module top(
    input clk,
    input reset,
    input RsRx,
    output [15:0] led,
    output RsTx
    );

    wire [7:0] w_wr_data;
    wire w_rd_en, w_wr_en;
    wire [7:0] w_rd_data;
    wire w_full, w_empty;
    wire w_tx_start;
    wire [7:0] w_tx_data;
    wire w_tx_done, w_tx_busy;
    wire w_send_trigger, w_sender_busy;
    wire [1:0] w_cmd_type;

    wire w_tick_1hz;
    wire [15:0] w_cnt_val;

    uart_rx u_uart_rx(
        .clk(clk),
        .reset(reset),
        .rx(RsRx),
        .data_out(w_wr_data),
        .rx_done(w_wr_en)
    );

    circular_queue #(
        .DATA_WIDTH(8),
        .DEPTH(64)
    ) u_circular_queue (
        .clk(clk),
        .reset(reset),
        .wr_en(w_wr_en),
        .wr_data(w_wr_data),
        .rd_en(w_rd_en),

        .rd_data(w_rd_data),
        .full(w_full),
        .empty(w_empty)
    );

    command_controller u_command_controller(
        .clk(clk),
        .reset(reset),
        .queue_data_in(w_rd_data), //circular queue가 꺼내놓은 8비트 데이터
        .queue_empty(w_empty), //circular queue가 empty일 때 받는 신호 (이 신호가 0일 때만 받아야 함)
        //.tx_busy(), //uart_tx가 송신 중이면 1

        .queue_rd_en(w_rd_en),
        .led(led),
        .send_trigger(w_send_trigger),
        .cmd_type(w_cmd_type),
        .sender_busy(w_sender_busy)
    );


    tick_generator #(
        .INPUT_REQ(100_000_000),
        .TICK_Hz(1)
    )(
        .clk(clk),
        .reset(reset),
        .tick(w_tick_1hz)
    );
    
    up_counter u_up_counter(
        .clk(clk),
        .reset(reset),
        .trigger_1hz(w_tick_1hz),
        .count(w_cnt_val)
    );
    
    data_sender u_data_sender(
        .clk(clk),
        .reset(reset),
        .start_trigger(w_send_trigger),        // 전송 시작 신호 (Pulse or Level)
        .cmd_type(w_cmd_type),       // 0: myname, 1: upcounter, 2: help
        .i_counter_val(w_cnt_val), // 16비트 카운터 값

        .sender_busy(w_sender_busy),     // "나 전송 중이야" 플래그
    
    // UART TX Interface
        .tx_busy(w_tx_busy), // UART TX가 바쁜지 확인
        .tx_done(w_tx_done), // UART TX 전송 완료 신호 (선택적 사용)
        .tx_start(w_tx_start), // UART TX 시작 신호
        .tx_data(w_tx_data)
    );

    uart_tx u_uart_tx(
        .clk(clk),
        .reset(reset),
        .tx_data(w_tx_data),
        .tx_start(w_tx_start),
        .tx(RsTx),
        .tx_done(w_tx_done),
        .tx_busy(w_tx_busy)
    );

    

endmodule