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
                        r_state <= S_DATA_BITS; //baud_tick이 오면 바로 다음 상태로 넘어감
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

/*`timescale 1ns / 1ps

module uart_tx #(
    parameter CLK_FREQ = 100_000_000, // 메인 클럭 주파수 (기본값 100MHz)
    parameter BPS      = 9600         // 통신 속도 (기본값 9600)
)(
    input wire clk,
    input wire reset,
    input wire [7:0] tx_data, // 보낼 데이터 (1바이트)
    input wire tx_start,      // 전송 시작 신호 (Pulse)
    output reg tx,            // UART TX 핀
    output wire tx_busy,      // 전송 중 상태 표시
    output reg tx_done        // 전송 완료 신호 (Pulse)
);

    // BPS에 따른 비트 폭 계산
    localparam BIT_PERIOD = CLK_FREQ / BPS;

    // 상태 정의
    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    reg [1:0] state, next_state;
    reg [31:0] cnt;             // 비트 길이를 세는 카운터
    reg [2:0] bit_cnt;          // 데이터 비트(0~7)를 세는 카운터
    reg [7:0] data_reg;         // 보낼 데이터를 저장하는 레지스터

    // Busy 신호: IDLE이 아니면 바쁜 상태
    assign tx_busy = (state != IDLE);

    // 상태 머신 (State Machine)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state   <= IDLE;
            tx      <= 1'b1; // UART Idle 상태는 High
            tx_done <= 1'b0;
            cnt     <= 0;
            bit_cnt <= 0;
            data_reg <= 0;
        end else begin
            // tx_done은 1클럭만 유지하고 바로 끔
            tx_done <= 1'b0; 

            case (state)
                IDLE: begin
                    tx <= 1'b1; // 대기 상태: High 유지
                    cnt <= 0; //대기 상태에서는 무조건 cnt를 0으로
                    bit_cnt <= 0;
                    if (tx_start) begin
                        data_reg <= tx_data; // 데이터 캡처
                        state <= START;
                    end
                end

                START: begin
                    tx <= 1'b0; // Start Bit: Low
                    //상태가 변한 이후부터 count 시작
                    if (cnt < BIT_PERIOD - 1) begin
                        cnt <= cnt + 1;
                    end else begin
                        cnt <= 0;
                        state <= DATA;
                    end
                end

                DATA: begin
                    tx <= data_reg[bit_cnt]; // 데이터 비트 전송 (LSB부터)
                    if (cnt < BIT_PERIOD - 1) begin
                        cnt <= cnt + 1;
                    end else begin
                        cnt <= 0;
                        if (bit_cnt < 7) begin
                            bit_cnt <= bit_cnt + 1;
                        end else begin
                            bit_cnt <= 0;
                            state <= STOP;
                        end
                    end
                end

                STOP: begin
                    tx <= 1'b1; // Stop Bit: High
                    if (cnt < BIT_PERIOD - 1) begin
                        cnt <= cnt + 1;
                    end else begin
                        cnt <= 0;
                        tx_done <= 1'b1; // 완료 신호 발생
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule */