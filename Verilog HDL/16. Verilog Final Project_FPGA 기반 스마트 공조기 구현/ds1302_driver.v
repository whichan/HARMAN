`timescale 1ns / 1ps

module ds1302_driver(
    input i_clk,          
    input i_reset,        
    input i_tick_1mhz,    // 10kHz 통신용 클럭
    input i_tick_1hz,     // 읽기 시작 트리거
    
    // [추가됨] Top 모듈에서 제어하기 위한 쓰기 인터페이스
    input i_we,                 // 1이면 Write 동작 수행 (Pulse)
    input [7:0] i_set_hour,     // 설정할 시 (BCD)
    input [7:0] i_set_min,      // 설정할 분 (BCD)
    input [7:0] i_set_sec,      // 설정할 초 (BCD)
    
    output reg o_ce, //chip enable
    output reg o_sclk, //1MHz sclk
    inout      io_data, //양방향 데이터 통신

    output reg [7:0] o_hour, o_min, o_sec, //fnd_controller, 
    output reg o_done_tick //ds1302에서 시간 데이터를 다 읽어오고, o_hour/o_min/o_sec 포트에 업데이트를 완료했을 경우 1클럭짜리 pulse 발생
);

    // ========== 1. parameter 정의 ========== //
    // Commands
    localparam CMD_BURST_READ  = 8'hBF; //데이터시트에 따라 BURST_READ = 8'hBF
    localparam CMD_BURST_WRITE = 8'hBE; //데이터시트에 따라 BUSRT_WRITE = 8'hBE
    localparam CMD_CONTROL_WR  = 8'h8E; //"

    // States
    localparam S_RESET_WAIT = 0; //FPGA 리셋 후 회로가 안정화될 때까지 잠깐 기다리는 상태
    localparam S_INIT_WP    = 1; //WP 해제 준비. CMD_CONTROL_WR(8Eh) 명령어를 ds1302로 전송하기 시작하는 단계
    localparam S_INIT_DATA  = 2; //실제 해제 수행. 8Eh 명령 뒤 00h를 전송. 이로써 WP비트가 0이 되어 Write가 가능해짐
    localparam S_INIT_GAP   = 3; //WP 해제 후 다음 명령을 보내기 전 쉬는 타임(안정성을 위해)
    localparam S_SET_CMD    = 4; //시간 설정 명령 (Write 시작 지점). CMD_BURST_WRITE(8'hBE)를 ds1302로 전송
    localparam S_SET_DATA   = 5; //코드에 정의된 초기 시간값(12:00:00)을 ds1302로 전송 
    
    localparam S_IDLE       = 6; //
    localparam S_PREPARE    = 7; //읽기 준비 단계. 통신을 시작하기 위해 CE핀을 High로 올리고, 데이터 방향(io_dir)을 출력으로 설정하는 준비 단계
    localparam S_TX_CMD     = 8; //명령어 전송. CMD_BURST_READ(8'hBF) 8비트를 한 비트씩 전송.
    localparam S_TURNAROUND = 9; //방향 전환 단계. 명령어를 다 보냈으니 이제 데이터를 받아야함.
                                 //io_dir을 0으로 바꿔서 수신모드로 변경
    localparam S_RX_DATA    = 10; //데이터 수신. ds1302가 보내주는 시/분/초 데이터를 받아 rx_buffer에 쌓음
    localparam S_FINISH     = 11; //CE핀을 Low로 내리고, 받아온 데이터를 o_hour, o_min, o_sec 포트에 업데이트 한 뒤 o_done_tick을 내보냄


    // ========== 2. 내부 레지스터 ========== //
    reg [3:0] state; //FSM 상태
    reg [6:0] bit_cnt; //7bit counter. 직렬 통신에서 지금 몇 번째 비트를 보내고(받고) 있는지 세는 카운터
                       /*Burst mode에서는 8바이트(64비트)를 연속으로 처리해야 하기 때문에 0~63까지 세려면 최소 6비트가 있어야 하며,
                       overflow를 방지하기 위해 7비트러 선언함*/
                       
    reg [7:0] tx_cmd_reg; //ds1302로 보낼 명령어 1바이트(8비트)를 잠시 담아두는 그릇
                          //명령어는 항상 8비트이기 때문에 8비트로 선언함.(ex. 8'hBF, 8'h8E)
    reg [63:0] rx_buffer; //ds1302에서 읽어온(Read) 시간 데이터를 저장하는 Shift Register.
                          //Burst Mode를 사용하면 ds1302는 sec부터 year,control 등까지 총 8개의 레지스터(8바이트)를 연속으로 보내기 때문에 64비트 필요
    
    // 64bit Burst Data [Sec][Min][Hr][Date][Mon][Day][Yr][WP]
    reg [63:0] init_data; //ds1302로 Write할 시간 데이터를 담고 있는 버퍼
                          //초기화할 때나 사용자가 시간을 수정할 때 8'hBE 명령 후 이 데이터를 실어서 뒤에 보낸다.

    reg io_dir; //io_data 통신선의 통신 방향 결정. 1: 
    reg io_out_reg; // io_data핀으로 내보낼 현재 비트 값 하나를 저장하는 레지스터.
                    // tx_cmd_reg나 init_data에서 비트를 하나 꺼내놓으면 아래 assign문에 의해 핀으로 데이터가 나감.
    reg init_done; //초기화가 끝났는지 확인하는 플래그 레지스터. 이 플래그가 '1'이 되어야만 FSM이 S_IDLE로 넘어가서 루프를 돈다.  

    assign io_data = (io_dir) ? io_out_reg : 1'bz; //io_dir=1일 때 io_out_reg가 나감, io_dir=0일 때 연결 끊김



    reg r_write_req; //i_we 신호가 잠깐 들어왔을 때 그 신호를 잡아 1로 유지하는 플래그
    reg [7:0] r_cap_hour, r_cap_min, r_cap_sec; //i_we가 들어온 그 순간의 시/분/초를 저장해두는 레지스터

    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            r_write_req <= 0;
            r_cap_hour <= 0; r_cap_min <= 0; r_cap_sec <= 0;
        end else begin
            // Top 모듈에서 Write Enable 신호가 오면 데이터와 플래그 저장
            if (i_we) begin //i_we는 매우 짧은 신호이기 때문에 FSM이 다른 일을 하고 있으면 놓칠 수도 있음. 따라서 레지스터를 통해 요청이 있었다는 사실을 1로 저장해둠
                r_write_req <= 1; 
                r_cap_hour <= i_set_hour; //순간의 시간을 레지스터에 복사해둠
                r_cap_min  <= i_set_min;
                r_cap_sec  <= i_set_sec;
            end
            // Write 명렁어를 보내기 시작(S_SET_CMD)하면 플래그 해제
            else if (state == S_SET_CMD) begin
                r_write_req <= 0; //S_IDLE에서 r_write_req가 1인 것을 발견하고 S_SET_CMD 상태로 넘어가기 때문에 r_write_req는 다시 0으로 복귀.
            end
        end
    end

    //1초 읽기 트리거 저장 로직

    //i_tick_1hz는 1초마다 10ns 동안만 1이 되는 매우 짧은 tick이기 때문에 tick이 발생할 때 FSM이 다른 일을 하고 있으면 놓칠 수 있음.
    //따라서 별도의 레지스터를 통해 tick_1hz를 저장해놓자.
    reg r_start_req; //펄스가 들어오면 1이 되고, FSM이 처리를 시작할 때까지 1을 유지함.
    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) r_start_req <= 0;
        else begin
            if (i_tick_1hz) r_start_req <= 1; 
            else if (state == S_PREPARE) r_start_req <= 0; //읽기 준비단계로 넘어가면 r_start_req는 영어로
        end
    end


    // ========== 3. Main FSM ========== //
    
    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            state       <= S_RESET_WAIT;
            o_ce        <= 0;
            o_sclk      <= 0;
            io_dir      <= 0;
            o_done_tick <= 0;
            bit_cnt     <= 0;
            init_done   <= 0;
            // 초기값 (전원 켜질 때만 사용됨)
            init_data   <= {8'h00, 8'h25, 8'h01, 8'h01, 8'h01, 8'h12, 8'h00, 8'h00}; //[WP 해제][25년][요일(1)][1월][1일][12시][0분][0초]
        end else begin
            o_done_tick <= 0; //펄스 신호는 매 클럭마다 자동으로 0으로 복귀

            if (i_tick_1mhz) begin //1MHz SCLK
                case (state)
                    // 초기화 시퀀스 (기존과 동일)
                    S_RESET_WAIT: begin //전원이 켜지자마자 바로 작동하는게 아닌 안정화를 위해 5tick(5us) 기다림
                        if (bit_cnt == 5) begin
                            bit_cnt <= 0; 
                            state <= S_INIT_WP; 
                        end else bit_cnt <= bit_cnt + 1;
                    end

                    S_INIT_WP: begin //
                        o_ce <= 1; //chip enable HIGH (모든 데이터 전송은 ce가 1이 돼야함)
                        io_dir <= 1; 
                        o_sclk <= 0;
                        io_out_reg <= CMD_CONTROL_WR[0]; //LSB부터 전송 준비
                        bit_cnt <= 0;
                        tx_cmd_reg <= CMD_CONTROL_WR; //명령: 0x8E (WP 해제 명령)
                        state <= 13; //별도의 13번 state로 (뒤에 나와있음)
                    end

                    S_INIT_DATA: begin //0x8E 명령 후에 0x00 데이터를 보내 WP 해제
                         if (o_sclk == 0) begin //sclk=0이면
                             o_sclk <= 1; //다음 클럭에서 sclk는 1로. //데이터시트에 따르면 ds1302는 sclk가 rising edge 되는 순간 데이터를 가져감
                             io_out_reg <= 0; //0000 0000 보냄
                         end else begin //현재 sclk가 1이면
                             o_sclk <= 0; //다음 클럭에서 sclk를 0으로
                             if (bit_cnt == 7) begin
                                 o_ce <= 0; //다 보냈으면 chip enable 해제
                                 bit_cnt <= 0; //카운터 초기화
                                 state <= S_INIT_GAP; //다음 단계(잠깐 쉬기)로 이동
                             end else bit_cnt <= bit_cnt + 1;
                         end
                    end

                    S_INIT_GAP: begin //쉬기
                        o_ce <= 0; 
                        state <= S_SET_CMD; 
                    end

                    S_SET_CMD: begin //Burst Write 하기 위한 명령어 전송
                        o_ce <= 1; //chip enable 1
                        io_dir <= 1; //write 동작하기 위해 방향 설정
                        o_sclk <= 0; //sclk는 0으로 초기화
                        tx_cmd_reg <= CMD_BURST_WRITE; //명령: 0x8E (Burst Write 명령)
                        io_out_reg <= CMD_BURST_WRITE[0]; //LSB부터 
                        bit_cnt <= 0; 
                        state <= 14; //명령 전송 서브루틴(14번) 이동
                    end

                    S_SET_DATA: begin //Burst Write(0x8E) 명령 이후, 실제 8바이트(64비트) 시간 데이터를 ds1302 칩에 밀어 넣음
                        if (o_sclk == 0) begin
                            o_sclk <= 1; //Rising Edge에서 ds1302가 값을 읽어감
                        end else begin
                            o_sclk <= 0; //falling edge
                            if (bit_cnt == 63) begin //만약 8바이트(64비트)가 다 전송되었으면
                                o_ce <= 0; //chip enable은 0으로
                                init_done <= 1; //초기화가 끝났는지 확인하는 데이터로, 1이 되어야 S_IDLE로 넘어감
                                state <= S_IDLE; //S_IDLE로
                            end else begin 
                                bit_cnt <= bit_cnt + 1;
                                io_out_reg <= init_data[bit_cnt + 1]; //falling edge에서 미리 bit_cnt+1 번째 데이터를 io_out_reg에 장전해둠 (setup time)
                            end
                        end 
                        if (o_sclk == 0) 
                            io_out_reg <= init_data[bit_cnt]; 
                            /*o_sclk=0일 때 o_sclk를 1로 만듦과 동시에 io_out_reg에 init_data[bit_cnt]를 한번더 할당함.
                            Rising Edge가 일어나는 순간 데이터 핀의 값은 init_data[bit_cnt]여야 한다는 것을 명시함으로써 혹시 모를 Glitch를 방지함
                            */
                    end

                    
                    S_IDLE: begin
                        o_ce <= 0; 
                        o_sclk <= 0; 
                        io_dir <= 0;
                        
                        if (init_done) begin
                            // 1순위: 쓰기 요청이 있으면 데이터를 갱신하고 쓰기 모드로 점프
                            if (r_write_req) begin
                                //캡쳐해둔 안전한 데이터를 tx buffer로 이동
                                init_data[7:0]   <= r_cap_sec;  // 초 갱신
                                init_data[15:8]  <= r_cap_min;  // 분 갱신
                                init_data[23:16] <= r_cap_hour; // 시 갱신
                                state <= S_SET_CMD; //쓰기 모드 진입
                            end
                            // 2순위: 읽기 요청
                            else if (r_start_req) begin
                                state <= S_PREPARE; //읽기 모드 진입
                                tx_cmd_reg <= CMD_BURST_READ; //명령어에 burst_read 입력
                            end
                        end
                    end

                    // 읽기 동작 (Read)
                    S_PREPARE: begin
                        o_ce <= 1; //chip enable 1
                        o_sclk <= 0; //sclk 0으로 초기화
                        io_dir <= 1; //방향 설정: FPGA -> ds1302
                        bit_cnt <= 0; //비트 카운터 초기화
                        state <= S_TX_CMD; //명령어를 보내는 상태로
                        io_out_reg <= tx_cmd_reg[0]; //첫번째 비트(LSB) 미리 장전
                    end

                    S_TX_CMD: begin //Read 명령어 보내는 상태. rising edge에서 보냄    
                        if (o_sclk == 0) o_sclk <= 1; //현재 sclk가 0이면 1로 올림 (rising edge)
                        //ds1302는 이 순간(rising edge) io_data에 있는 신호를 읽어서 레지스터로 가져감
                        else begin
                            o_sclk <= 0; //현재 sclk가 1이면 0으로 내림(falling edge)
                            if (bit_cnt == 7) begin 
                                state <= S_TURNAROUND; //다 보냈으면 방향 전환 상태로 이동
                                bit_cnt <= 0;
                            end else begin 
                                bit_cnt <= bit_cnt + 1; 
                                io_out_reg <= tx_cmd_reg[bit_cnt + 1]; //다음 비트 미리 장전(setup time)
                            end
                        end
                    end

                    S_TURNAROUND: begin
                        o_sclk <= 0; 
                        io_dir <= 0; //방향 전환 (High-Z)
                        state <= S_RX_DATA; //
                    end

                    S_RX_DATA: begin //Burst mode READ
                    //데이터시트에 따르면 read 동작 시 ds1302는 sclk의 falling edge에 데이터를 내보냄.
                    //setup time을 고려하여 rising edge(반주기 전) 일 때 rx_buffer로 데이터를 밀어넣음
                        if (o_sclk == 0) begin
                            o_sclk <= 1; //rising edge (데이터를 읽는 순간)
                            rx_buffer[bit_cnt] <= io_data; //반주기 전에 데이터를 받음
                            bit_cnt <= bit_cnt + 1;
                        end else begin
                            o_sclk <= 0; //falling edge
                            if (bit_cnt == 64) state <= S_FINISH; //만약 데이터를 다 보내면 S_FINISH로
                        end
                    end

                    S_FINISH: begin
                        o_ce <= 0; //chip enable 0
                        o_sclk <= 0;
                        o_sec  <= rx_buffer[7:0]; //초
                        o_min  <= rx_buffer[15:8]; //분
                        o_hour <= rx_buffer[23:16]; //시
                        o_done_tick <= 1; //데이터 도착 알림
                        state <= S_IDLE; //IDLE로
                    end

                    //초기화용 전용 버스
                    13: begin //S_TX_CMD와 구조가 똑같지만 끝나면 S_INIT_DATA로 감
                        if (o_sclk == 0) o_sclk <= 1;
                        else begin
                            o_sclk <= 0;
                            if (bit_cnt == 7) begin 
                                bit_cnt <= 0; state <= S_INIT_DATA; 
                            end else begin 
                                bit_cnt <= bit_cnt + 1; 
                                io_out_reg <= tx_cmd_reg[bit_cnt + 1]; 
                            end
                        end
                    end

                    14: begin // 끝나면 S_SET_DATA로 감
                        if (o_sclk == 0) o_sclk <= 1;
                        else begin
                            o_sclk <= 0;
                            if (bit_cnt == 7) begin 
                                bit_cnt <= 0; state <= S_SET_DATA; 
                            end else begin 
                                bit_cnt <= bit_cnt + 1; io_out_reg <= tx_cmd_reg[bit_cnt + 1]; 
                            end
                        end
                    end
                endcase
            end
        end
    end
endmodule