`timescale 1ns / 1ps
//==============================================================================
// Module: uart_tx (Sequential 버전)
// Description: UART 송신 모듈 - 안정적인 타이밍
//==============================================================================

module uart_tx #(
    parameter BPS = 9600
) (
    input clk,
    input reset,
    input [7:0] tx_data,
    input tx_start,
    output reg tx,
    output reg tx_busy,
    output reg tx_done
);

    parameter S_IDLE       = 2'b00;
    parameter S_START_BIT  = 2'b01;
    parameter S_DATA_BITS  = 2'b10;
    parameter S_STOP_BIT   = 2'b11;

    parameter DIVIDER_CNT = 100_000_000 / BPS;

    // ========== 레지스터 선언 ========== //
    reg [1:0]  r_state;
    reg [3:0]  r_bit_cnt;
    reg [7:0]  r_data_reg;
    reg [15:0] r_baud_cnt;
    reg        r_baud_tick;

    // ========== Baud Rate Generator ========== //
    always @(posedge clk) begin
        if (reset) begin
            r_baud_cnt <= 16'd0;
            r_baud_tick <= 1'b0;
        end else begin
            if (r_baud_cnt == DIVIDER_CNT - 1) begin
                r_baud_cnt <= 16'd0;
                r_baud_tick <= 1'b1;
            end else begin
                r_baud_cnt <= r_baud_cnt + 1'b1;
                r_baud_tick <= 1'b0;
            end
        end
    end
    
    // ========== FSM (완전 Sequential) ========== //
    always @(posedge clk) begin
        if (reset) begin
            r_state <= S_IDLE;
            r_data_reg <= 8'b0;
            r_bit_cnt <= 4'b0;
            tx <= 1'b1;
            tx_busy <= 1'b0;
            tx_done <= 1'b0;
        end else begin
            // 기본값: tx_done은 1-cycle 펄스
            tx_done <= 1'b0;
            
            case (r_state)
                // ========== IDLE 상태 ========== //
                S_IDLE: begin
                    tx <= 1'b1;
                    tx_busy <= 1'b0;
                    
                    if (tx_start) begin
                        r_state <= S_START_BIT;
                        r_data_reg <= tx_data;
                        tx_busy <= 1'b1;
                        r_bit_cnt <= 4'd0;
                    end
                end

                // ========== START BIT 전송 ========== //
                S_START_BIT: begin
                    tx <= 1'b0;  // START bit (LOW)
                    
                    if (r_baud_tick) begin
                        r_state <= S_DATA_BITS;
                    end
                end

                // ========== DATA BITS 전송 (8비트) ========== //
                S_DATA_BITS: begin
                    tx <= r_data_reg[r_bit_cnt];  // LSB first
                    
                    if (r_baud_tick) begin
                        if (r_bit_cnt == 4'd7) begin
                            r_state <= S_STOP_BIT;
                        end else begin
                            r_bit_cnt <= r_bit_cnt + 1'b1;
                        end 
                    end
                end

                // ========== STOP BIT 전송 ========== //
                S_STOP_BIT: begin
                    tx <= 1'b1;  // STOP bit (HIGH)
                    // tx_busy는 계속 1 유지
                    
                    if (r_baud_tick) begin
                        r_state <= S_IDLE;
                        tx_done <= 1'b1;  // 전송 완료 펄스
                        // tx_busy는 다음 클럭에 IDLE에서 0이 됨
                        tx_busy <= 1'b0;
                    end
                end

                default: r_state <= S_IDLE;
            endcase
        end
    end

endmodule