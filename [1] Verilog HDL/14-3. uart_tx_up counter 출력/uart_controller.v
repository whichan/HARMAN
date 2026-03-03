`timescale 1ns / 1ps

module uart_controller(
    input clk,
    input reset,
    input [13:0] send_data, // (사용 안 함)
    input rx,
    output tx,
    output [7:0]  rx_data, // (사용 안 함)
    output rx_done       // (사용 안 함)
    );

    wire w_tick_1Hz;             // 1Hz 틱
    wire [15:0] w_up_count_value;   // up_counter의 이진수 값
    
    wire w_tx_busy, w_tx_done, w_tx_start;
    wire [7:0] w_tx_data;

    // 1. 1Hz 틱 생성기
    tick_generator # (
        .INPUT_REQ(100_000_000),
        .TICK_Hz(1)
    ) u_tick_1Hz(
        .clk(clk),
        .reset(reset),
        .tick(w_tick_1Hz)
    ); 

    // 2. 1Hz Up Counter (신규)
    up_counter u_up_counter (
        .clk(clk),
        .reset(reset),
        .trigger_1hz(w_tick_1Hz),
        .count(w_up_count_value) // 16비트 카운터 값 출력
    );

    // 3. Data Sender (신규 FSM)
    data_sender u_data_sender(
        .clk(clk),
        .reset(reset),
        .start_trigger(w_tick_1Hz),       // 1Hz 틱을 "시작 신호"로 사용
        .i_counter_value(w_up_count_value), // 16비트 이진수 값을 입력
        .tx_busy(w_tx_busy),
        .tx_start(w_tx_start),
        .tx_data(w_tx_data)
    );

    // 4. UART 송신 모듈 (기존)
    uart_tx #( 
        .BPS(9600)
    ) u_uart_tx(
        .clk(clk),
        .reset(reset),
        .tx_data(w_tx_data),   // data_sender가 보낼 문자를 전달
        .tx_start(w_tx_start), // data_sender가 보낼 시작 신호를 전달
        .tx(tx),
        .tx_done(w_tx_done),
        .tx_busy(w_tx_busy)    // uart_tx의 상태를 data_sender에게 보고
    );
    
    // (RX는 현재 사용하지 않음)
    /*
    uart_rx u_uart_rx(
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .data_out(rx_data),
        .rx_done(rx_done)
    );
    */

endmodule