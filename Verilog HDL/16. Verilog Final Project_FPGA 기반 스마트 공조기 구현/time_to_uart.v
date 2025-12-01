`timescale 1ns / 1ps

module time_to_uart_ds1302 (
    input i_clk,
    input i_reset,
    
    
    input [7:0] i_hour, i_min, i_sec, //ds1302_driver의 출력
    
    // Control Signals
    input i_start_trigger,  // DS1302 읽기 완료 신호
    input i_tx_done,        // UART 전송 완료 신호

    // Output
    output reg o_tx_start,  //uart_tx에 전송 시작 명령을 보내는 신호
    output reg [7:0] o_tx_byte, //uart_tx 어떤 문자를 보내는지 알려주는 신호 (ASCII Data)
    output reg o_busy //'문자열 보내는 중' 상태 플래그
);

    // ========== 1. 파라미터 정의 ========== //
    localparam S_IDLE = 0;
    localparam S_SEND = 1;
    localparam S_WAIT = 2;

    // ========== 2. 내부 레지스터 ========== //
    reg [1:0] state;
    reg [4:0] send_idx; // 몇 번째 글자를 보내고 있는지 세는 카운터 (0~9)
    //12:34:56\r\n은 총 10글자이기 때문에 넉넉하게 5비트

    // ========== 3. BCD to ASCII 함수 ========== //
    /* 0:0x30, 1:0X31...
    BCD(0~9) 앞에 3(0011)만 붙이면 ASCII코드가 됨*/
    function [7:0] b2a;
        input [3:0] bcd;
        begin
            b2a = {4'h3, bcd}; 
        end
    endfunction

    // ========== 4. Main FSM ========== //
    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            state <= S_IDLE;
            send_idx <= 0;
            o_tx_start <= 0;
            o_tx_byte <= 0;
            o_busy <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    o_tx_start <= 0;
                    send_idx <= 0;
                    o_busy <= 0;
                    
                    if (i_start_trigger) begin //ds1302가 데이터가 왔다는 신호를 보내면 
                        state <= S_SEND; //S_SEND 상태로 이동하고
                        o_busy <= 1; //'데이터를 옮기는 중' 플래그를 1로
                    end
                end

                S_SEND: begin
                    /*시간 데이터는 8비트 BCD임. (ex. 12시: 0001 0010)
                    UART는 한 번에 한 글자만 보낼 수 있으므로 상위 4비트(1)를 먼저 보내고 하위 4비트(2)를 보내야됨
                    b2a() 함수를 통해 이 숫자들을 ASCII문자 '1''2'로 변환해서 o_tx_byte에 실음
                    */
                    o_tx_start <= 1; //uart_tx에게 전송 명령
                    state <= S_WAIT; //S_WAIT상태로 이동

                    case (send_idx)
                        // 시
                        0: o_tx_byte <= b2a(i_hour[7:4]); //시의 10의자리
                        1: o_tx_byte <= b2a(i_hour[3:0]); //시의 1의자리
                        2: o_tx_byte <= ":"; 
                        // 분
                        3: o_tx_byte <= b2a(i_min[7:4]); //분의 10의자리
                        4: o_tx_byte <= b2a(i_min[3:0]); //분의 1의자리
                        5: o_tx_byte <= ":";
                        // 초
                        6: o_tx_byte <= b2a(i_sec[7:4]); //초의 10의자리
                        7: o_tx_byte <= b2a(i_sec[3:0]); //초의 1의자리
                        // End
                        8: o_tx_byte <= 8'h0D; // CR (\r)
                        9: o_tx_byte <= 8'h0A; // LF (\n)
                        default: o_tx_byte <= " ";
                    endcase
                end

                S_WAIT: begin
                    o_tx_start <= 0;
                    
                    if (i_tx_done) begin //uart_t가 다 보냈다는 신호 보내면
                        //다 보냈는지 확인
                        if (send_idx == 9) begin
                            state <= S_IDLE; //끝, 다시 S_IDLE로
                            o_busy <= 0; //바쁜 상태 종료
                        end else begin //send_idx가 아직 9가 안됐다면(아직 보내려는 글자를 다 안보냈다면)
                            send_idx <= send_idx + 1; //다음 글자 가리킴
                            state <= S_SEND; //다시 전송 상태로
                        end
                    end
                end
            endcase
        end
    end

endmodule