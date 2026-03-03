`timescale 1ns / 1ps

module command_controller(
    input clk,
    input reset,
    
    // Circular Queue Interface
    input [7:0] queue_data_in,  // 큐에서 읽은 데이터
    input queue_empty,          // 큐가 비었는지 확인
    output reg queue_rd_en,     // 큐 읽기 신호
    
    // LED Control
    output reg [15:0] led,
    
    // Data Sender Interface (온습도 값은 trigger 결정에 참고용 혹은 pass-through)
    input [7:0] i_temp_val,
    input [7:0] i_humi_val,
    input i_data_valid,
    
    output reg send_trigger,    // data_sender 시작 신호
    output reg [2:0] cmd_type,  // 0:name, 1:cnt, 2:help, 3:temp
    input sender_busy           // 전송 중인지 확인
    );

    // ====================================================
    // 상태 정의
    // ====================================================
    localparam S_IDLE       = 3'd0;
    localparam S_FETCH      = 3'd1; // 큐에서 데이터 꺼내기
    localparam S_CHECK      = 3'd2; // 명령어 비교
    localparam S_EXECUTE    = 3'd3; // 동작 수행
    localparam S_FLUSH      = 3'd4; // 오류 시 버퍼 비우기

    reg [2:0] state;
    reg [7:0] rx_buffer [0:15]; // 명령어 저장용 버퍼 (최대 16글자)
    reg [3:0] buf_idx;          // 버퍼 인덱스

    // ====================================================
    // Main FSM
    // ====================================================
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            state       <= S_IDLE;
            queue_rd_en <= 0;
            send_trigger<= 0;
            cmd_type    <= 0;
            led         <= 0;
            buf_idx     <= 0;
        end else begin
            case(state)
                // 1. 대기 상태: 큐에 데이터가 들어오면 읽기 시작
                S_IDLE: begin
                    send_trigger <= 0;
                    if(!queue_empty && !sender_busy) begin
                        queue_rd_en <= 1; // 읽기 신호 On
                        state <= S_FETCH;
                    end
                end

                // 2. 데이터 가져오기 (1클럭 딜레이 고려)
                S_FETCH: begin
                    queue_rd_en <= 0; // 읽기 신호 Off (1개만 읽음)
                    state <= S_CHECK;
                end

                // 3. 데이터 분석 및 버퍼링
                S_CHECK: begin
                    // Enter 키(CR=0x0D)가 들어오면 명령어 처리 시작
                    if(queue_data_in == 8'h0D) begin 
                        state <= S_EXECUTE;
                    end 
                    // 버퍼가 꽉 차지 않았으면 글자 담기
                    else if(buf_idx < 15) begin
                        rx_buffer[buf_idx] <= queue_data_in;
                        buf_idx <= buf_idx + 1;
                        state <= S_IDLE; // 다음 글자 받으러 감
                    end 
                    else begin
                        // 버퍼 오버플로우 -> 초기화
                        buf_idx <= 0;
                        state <= S_IDLE;
                    end
                end

                // 4. 명령어 실행 (문자열 비교)
                S_EXECUTE: begin
                    buf_idx <= 0; // 인덱스 초기화 준비
                    state <= S_IDLE;

                    // --- "led" : LED 토글 ---
                    if(rx_buffer[0]=="l" && rx_buffer[1]=="e" && rx_buffer[2]=="d") begin
                        led <= ~led; // LED 전체 반전 (또는 원하는 동작)
                    end
                    // --- "myname" : 이름 전송 (Type 0) ---
                    else if(rx_buffer[0]=="m" && rx_buffer[1]=="y" && rx_buffer[2]=="n" && rx_buffer[3]=="a" && rx_buffer[4]=="m" && rx_buffer[5]=="e") begin
                        cmd_type <= 3'd0;
                        send_trigger <= 1;
                    end
                    // --- "upcounter" : 카운터 값 전송 (Type 1) ---
                    else if(rx_buffer[0]=="u" && rx_buffer[1]=="p" && rx_buffer[2]=="c" && rx_buffer[3]=="o" && rx_buffer[4]=="u" && rx_buffer[5]=="n" && rx_buffer[6]=="t" && rx_buffer[7]=="e" && rx_buffer[8]=="r") begin
                        cmd_type <= 3'd1;
                        send_trigger <= 1;
                    end
                    // --- "temp" : 온습도 전송 (Type 3) ---
                    else if(rx_buffer[0]=="t" && rx_buffer[1]=="e" && rx_buffer[2]=="m" && rx_buffer[3]=="p") begin
                        cmd_type <= 3'd3;
                        send_trigger <= 1;
                    end
                    // --- 그 외 : Help 메시지 전송 (Type 2) ---
                    else begin
                        cmd_type <= 3'd2;
                        send_trigger <= 1;
                    end
                end
                
                default: state <= S_IDLE;
            endcase
        end
    end
endmodule