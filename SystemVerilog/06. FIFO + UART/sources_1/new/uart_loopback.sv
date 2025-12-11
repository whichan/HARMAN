`timescale 1ns / 1ps



module uart_loopback(
    input clk,
    input reset,

    //uart
    output RsTx,
    input RsRx

    );

    wire [7:0] w_rxdata;
    wire [7:0] w_txdata;
    wire w_wr;

    wire [7:0] w_wdata;
    wire w_fifotx_empty;
    wire w_tx_busy;
    wire w_fiforx_empty;
    wire w_fifotx_full;

    uart_rx u_uart_rx(
        .clk(clk),
        .reset(reset),
        .rx(RsRx),
        .data_out(w_rxdata),
        .rx_done(w_wr)
    );

    uart_tx u_uart_tx(
        //input
        .clk(clk),
        .reset(reset),
        .tx_data(w_txdata), // 보낼 데이터 (1바이트)
        .tx_start(~w_fifotx_empty),      // 전송 시작 신호 (Pulse)
        
        //output
        .tx(RsTx),            // UART TX 핀
        .tx_busy(w_tx_busy),      // 전송 중 상태 표시
        .tx_done()        // 전송 완료 신호 (Pulse)
    );

    fifo u_fifo_rx(
        .clk(clk),
        .reset(reset),
        .wr(w_wr), //push
        .rd(~w_fifotx_full), //pop
        .wdata(w_rxdata), //들어올 데이터
        .rdata(w_wdata), //나갈 데이터
        .full(),
        .empty(w_fiforx_empty)
    );

    fifo u_fifo_tx(
        .clk(clk),
        .reset(reset),
        .wr(~w_fiforx_empty), //push
        .rd(~w_tx_busy), //pop
        .wdata(w_wdata), //들어올 데이터
        .rdata(w_txdata), //나갈 데이터
        .full(w_fifotx_full),
        .empty(w_fifotx_empty)
    );

endmodule
