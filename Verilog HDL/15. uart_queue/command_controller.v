`timescale 1ns / 1ps

module command_controller(
    input clk,
    input reset,
    input [7:0] queue_data, //circular queue가 꺼내놓은 8비트 데이터
    input queue_empty, //circular queue가 empty일 때 받는 신호 (이 신호가 0일 때만 받아야 함)
    input tx_busy, //uart_tx가 송신 중이면 1

    output queue_rd_en,
    output reg [15:0] led
    );
    
    localparam MAX_CMD_LEN = 16;
    
endmodule
