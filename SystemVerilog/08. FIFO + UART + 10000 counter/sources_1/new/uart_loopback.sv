`timescale 1ns / 1ps

module uart_loopback(
    input clk,
    input reset,

    //uart
    output RsTx,
    input RsRx,

    //추가 선
    output [7:0] monitor_data,
    output monitor_valid,

    input [7:0] ext_tx_data,
    input ext_tx_start,
    output ext_tx_busy,

    //'s' 오류 수정
    //sender가 일하는 중인지 확인하는 입력 포트 추가
    input sender_active
    );

    wire [7:0] w_rxdata;
    wire [7:0] w_txdata;
    wire w_wr;

    wire [7:0] w_wdata;
    wire w_fifotx_empty;
    wire w_tx_busy;
    wire w_fiforx_empty;
    wire w_fifotx_full;


    //교통정리 로직
    //RX FIFO에서 데이터를 꺼내는 조건:
    //1. tx에 자리가 있고(!full)
    //2. sender가 지금 당장 보내려는게 없고(!start)
    //3. sender가 긴 문장을 보내는 중도 아니어야 함(!active)
    wire w_rx_pop;
    assign w_rx_pop = (!w_fifotx_full) && (!ext_tx_start) && (!sender_active);

    //rx -> uart_controller
    assign monitor_data = w_wdata;
    //assign monitor_valid = (!w_fiforx_empty) && (!w_fifotx_full);

    //[수정]: Monitor Valid도 실제 pop이 일어날 때만 1이 되도록 수정
    assign monitor_valid = w_rx_pop && (!w_fiforx_empty);


    //sender용
    assign ext_tx_busy = w_fifotx_full;

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
        //.rd(~w_fifotx_full), //pop

        //수정
        .rd(w_rx_pop),

        .wdata(w_rxdata), //들어올 데이터
        .rdata(w_wdata), //나갈 데이터
        .full(),
        .empty(w_fiforx_empty)
    );

    // 외부 요청(ext_tx_start)이 있으면 외부 데이터, 없으면 Loopback 데이터
    wire [7:0] w_final_tx_data = (ext_tx_start) ? ext_tx_data : w_wdata;
    
    wire w_final_wr = (ext_tx_start) ? 1'b1 : monitor_valid;

    fifo u_fifo_tx(
        .clk(clk),
        .reset(reset),
        .wr(w_final_wr && !w_fifotx_full), //push
        .rd(~w_tx_busy), //pop
        .wdata(w_final_tx_data), //들어올 데이터
        .rdata(w_txdata), //나갈 데이터
        .full(w_fifotx_full),
        .empty(w_fifotx_empty)
    );

endmodule