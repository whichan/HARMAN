`timescale 1ns / 1ps

module dht11(
    input clk,      // 100MHz 시스템 클럭
    input reset,    // 리셋 신호
    inout dht_pin,  // DHT11 데이터 핀 (양방향 통신)
    input start_read, // 측정 시작 트리거 신호 (1Hz 주기)
    
    output reg [7:0] humi_INT_out,
    output reg [7:0] humi_REAL_out, 
    output reg [7:0] temp_INT_out,
    output reg [7:0] temp_REAL_out,
    output reg data_valid,  // 데이터가 정상적으로 수신되었을 때 1
    output reg error_flag   // 타임아웃이나 체크섬 에러 시 1
    );

    // 100MHz 클럭을 1us(마이크로초) 단위로 쪼개기 위한 설정
    parameter SYSTEM_CLK = 100_000_000;
    parameter MHz_1 = 1_000_000;
    parameter COUNTER = SYSTEM_CLK / MHz_1; // 100 (1us를 만들기 위해 세어야 할 클럭 수)
    
    //단위: us
    parameter ms_18 = 18_000; // 18ms = 18,000us (시작 신호 Low 구간)
    parameter us_20 = 20;     // 20us (시작 신호 후 High 대기)

    // 상태 머신 정의
    parameter S_IDLE = 3'b000;
    parameter S_START_LOW = 3'b001;
    parameter S_WAIT_PULLUP = 3'b010;
    parameter WAIT_RESPONSE_LOW = 3'b011;
    parameter WAIT_RESPONSE_HIGH = 3'b100;
    parameter READ_DATA = 3'b101;
    parameter DONE = 3'b110;

    // 내부 레지스터 선언
    reg [6:0] us_cnt;       // 1us를 만들기 위한 작은 카운터 (0~99)
    reg us_1us_clk;         // 1us마다 딱 1클럭 동안만 '1'이 되는 틱 신호
    reg io_mode;            // 1: 입력모드(High-Z), 0: 출력모드
    reg o_data;             // 출력할 데이터 값 (0 또는 1)
    reg [3:0] r_state;      // 현재 상태

    reg [17:0] state_timer_us; // 각 상태에서 시간을 재는 타이머 (단위: us)
    reg [39:0] data_buffer;    // 40비트 데이터 임시 저장소
    reg [5:0] bit_cnt;         // 몇 번째 비트를 읽고 있는지 카운트 (0~39)

    reg prev_dht11_data;       // 엣지 감지를 위해 '이전 상태'를 저장하는 변수

    // 시스템 클럭(100MHz)을 세어서 1us마다 한 번씩 신호를 줍니다.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            us_cnt <= 0;
            us_1us_clk <= 0;
        end else begin 
            if(us_cnt == COUNTER - 1) begin // 99까지 세면 (100클럭 = 1us)
                us_cnt <= 0;
                us_1us_clk <= 1; // 틱 발생
            end else begin
                us_cnt <= us_cnt + 1;
                us_1us_clk <= 0;
            end
        end
    end

    // --- [로직 2] 메인 상태 머신 (FSM) ---
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // 초기화
            io_mode <= 1; 
            o_data <= 0;
            state_timer_us <= 0;
            data_buffer <= 0;
            bit_cnt <= 0;
            
            humi_INT_out <= 0;
            humi_REAL_out <= 0;
            temp_INT_out <= 0;
            temp_REAL_out <= 0;
            data_valid <= 0;
            error_flag <= 0;
            
            r_state <= S_IDLE;
            prev_dht11_data <= 1;
        end else begin 

            // IDLE 상태가 아닐 때(동작 중일 때) 계속 시간을 잰다
            if (r_state != S_IDLE) begin
                if (us_1us_clk) begin
                    // 30ms(30,000us)가 넘어가면 강제 리셋 (Deadlock 탈출)
                    if (timeout_timer > TIMEOUT_LIMIT) begin
                        r_state <= S_IDLE;
                        error_flag <= 1; // 에러임을 알림
                        timeout_timer <= 0;
                    end else begin
                        timeout_timer <= timeout_timer + 1;
                    end
                end
            end else begin
                timeout_timer <= 0; // IDLE일 때는 0으로 대기
            end

            case (r_state) 
            // 1. 대기 상태
            S_IDLE : begin
                data_valid <= 0;
                error_flag <= 0;
                io_mode <= 1; // 입력 모드로 대기 (Pull-up 저항으로 High 유지됨)
                state_timer_us <= 0; 
                
                if(start_read) begin // 시작 신호가 오면
                    r_state <= S_START_LOW;
                    state_timer_us <= 0;
                end
            end

            // 2. 시작 신호 전송 (MCU -> DHT11)
            S_START_LOW : begin
                io_mode <= 0; // 출력 모드로 전환
                o_data <= 0;  // Low 신호 출력  
                
                if (us_1us_clk) begin // 1us마다 실행
                    if (state_timer_us >= ms_18 - 1) begin // 18ms가 지났으면
                        r_state <= S_WAIT_PULLUP; 
                        io_mode <= 1; // 다시 입력 모드로 전환 (손 뗌)
                        state_timer_us <= 0;
                    end else begin
                        state_timer_us <= state_timer_us + 1; // 시간 측정
                    end
                end
            end
              
            // 3. 대기 (Pull-up에 의해 High가 되는 구간)
            S_WAIT_PULLUP : begin
                io_mode <= 1; 
                if(us_1us_clk) begin
                    if (state_timer_us >= us_20 - 1) begin // 20~40us 기다림
                        r_state <= WAIT_RESPONSE_LOW;
                        state_timer_us <= 0;
                    end else begin 
                        state_timer_us <= state_timer_us + 1;
                    end
                end           
            end

            // 4. DHT11 응답 확인 (Low 구간 80us)
            WAIT_RESPONSE_LOW : begin
                io_mode <= 1;
                if(us_1us_clk) begin
                    if (dht_pin == 0) begin // 센서가 Low를 보내고 있으면
                        state_timer_us <= state_timer_us + 1; // 정상, 시간 잼
                    end else begin
                        // High로 올라감 (응답 끝)
                        // 최소 60us 이상 Low였는지 확인 (노이즈 필터링)
                        if (state_timer_us > 60) begin 
                            r_state <= WAIT_RESPONSE_HIGH;
                            state_timer_us <= 0;
                        end else begin 
                            // 너무 짧으면 아직 대기하거나 에러 처리 (여기선 대기)
                            state_timer_us <= 0;
                        end
                    end
                end
            end

            // 5. DHT11 응답 확인 (High 구간 80us)
            WAIT_RESPONSE_HIGH : begin
                io_mode <= 1;
                if(us_1us_clk) begin
                    if (dht_pin == 1) begin // 센서가 High를 보내고 있으면
                        state_timer_us <= state_timer_us + 1;
                    end else begin
                        // Low로 떨어짐 (이제부터 진짜 데이터 전송 시작)
                        if (state_timer_us > 60) begin
                            r_state <= READ_DATA;
                            state_timer_us <= 0;
                            bit_cnt <= 0;
                            prev_dht11_data <= 0; // 엣지 감지용 초기값 설정
                        end else begin
                            state_timer_us <= 0;
                        end
                    end
                end
            end

            READ_DATA : begin
                io_mode <= 1;
                if(us_1us_clk) begin // 1us마다 실행
                    
                    // 이전 상태 저장 (엣지 감지용)
                    // 현재 dht_pin 값을 '과거' 변수에 저장해둠
                    prev_dht11_data <= dht_pin; 

                    // 하강 엣지 감지 (Falling Edge)
                    // 아까는 1이었는데(prev==1), 지금 0이 도미(pin==0)
                    // 이 순간이 바로 '데이터 1비트의 High 구간이 끝난 시점
                    if (prev_dht11_data == 1 && dht_pin == 0) begin 
                        
                        // High 구간의 길이를 보고 0인지 1인지 판별
                        // 26~28us = '0', 70us = '1' -> 기준점 40us
                        if (state_timer_us < 40) begin 
                            data_buffer <= {data_buffer[38:0], 1'b0}; // Shift하며 0 저장
                        end else begin 
                            data_buffer <= {data_buffer[38:0], 1'b1}; // Shift하며 1 저장
                        end
                        
                        bit_cnt <= bit_cnt + 1; // 비트 수 증가
                        state_timer_us <= 0;    // 다음 비트를 위해 타이머 리셋
                    end
                    
                    // 핀이 High일 때만 시간을 잼 (데이터 길이 측정)
                    else if (dht_pin == 1) begin
                        state_timer_us <= state_timer_us + 1;
                    end
                    
                    // 핀이 Low일 때 (50us 대기 구간)는 시간을 안 잼 (0으로 유지)
                    else begin 
                        state_timer_us <= 0; 
                    end
                    
                    // 40비트 다 받았으면 종료
                    if (bit_cnt >= 40) begin
                        r_state <= DONE; 
                    end
                end
            end
                  
            // 7. 완료 및 검증
            DONE: begin 
                // 체크섬 계산: 상위 4바이트 합 == 마지막 1바이트(체크섬)
                if ((data_buffer[39:32] + data_buffer[31:24] + data_buffer[23:16] + data_buffer[15:8]) == data_buffer[7:0]) begin 
                    // 데이터 분배
                    humi_INT_out  <= data_buffer[39:32]; 
                    humi_REAL_out <= data_buffer[31:24];
                    temp_INT_out  <= data_buffer[23:16]; 
                    temp_REAL_out <= data_buffer[15:8]; 
                    
                    data_valid <= 1; // 유효 데이터 플래그 1
                    error_flag <= 0;
                end else begin
                    // 실패 (체크섬 불일치)
                    data_valid <= 0;
                    error_flag <= 1;
                end
            
                r_state <= S_IDLE; // 다음 측정을 위해 대기 상태로 복귀
            end
            endcase
        end
    end
        
    // Tri-state 버퍼 연결
    // io_mode가 1이면 입력(z), 0이면 출력(o_data)
    assign dht_pin = io_mode ? 1'bz : o_data;

endmodule