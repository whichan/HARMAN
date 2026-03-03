`timescale 1ns / 1ps

module top(
    input clk,
    input reset,
    input RsRx,
    output [15:0] led
    );

    wire [7:0] w_wr_data;
    wire w_rd_en, w_wr_en;
    wire [7:0] w_rd_data;
    wire w_full, w_empty;
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
        .led(led)
    );
    
endmodule