`timescale 1ns / 1ps

module command_controller(
    input clk,
    input reset,
    
    // Circular Queue 인터페이스
    input [7:0] queue_data_in,
    input queue_empty,
    output reg queue_rd_en,
    
    // LED 출력
    output reg [15:0] led
);

    // 파라미터 정의
    parameter ENTER_KEY = 8'h0D; // CR (Carriage Return): 명령어 실행 신호
    parameter LINE_FEED = 8'h0A; // LF (Line Feed): 무시할 신호

    parameter S_IDLE  = 2'd0; // 대기
    parameter S_READ  = 2'd1; // 큐 읽기 요청
    parameter S_CHECK = 2'd2; // 데이터 확인 및 실행

    // 내부 레지스터
    reg [1:0] state;
    reg [7:0] buffer [0:15]; // 명령어 저장소 (최대 16글자)
    reg [3:0] ptr;           // 현재 버퍼 위치 포인터
    reg [7:0] latched_data; //데이터를 잡아둘 임시 저장소

    // =================================================
    // 동작 로직
    // =================================================
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            state       <= S_IDLE;
            queue_rd_en <= 0;
            led         <= 16'h0000; // 리셋 시 LED 전체 끄기
            ptr         <= 0; 
        end else begin
            case(state)
                
                // 1. IDLE: 큐에 데이터가 들어왔는지 감시
                S_IDLE: begin
                    queue_rd_en <= 0;
                    // 큐가 비어있지 않으면(데이터가 있으면) 읽기 상태로 이동
                    if(queue_empty == 0) begin
                        state <= S_READ;
                    end
                end

                // ------------------------------------------------
                // 2. READ: 큐에게 데이터 1개를 달라고 요청 (1클럭)
                // ------------------------------------------------
                S_READ: begin
                    queue_rd_en <= 1; // 읽기 신호 ON
                    latched_data <= queue_data_in;
                    state <= S_CHECK;
                end

                // ------------------------------------------------
                // 3. CHECK: 받은 데이터를 분석하고 처리
                // ------------------------------------------------
                S_CHECK: begin
                    queue_rd_en <= 0; 

                    // CR(0D) 또는 LF(0A) 중 무엇이 와도 실행 트리거로 인식
                    if(latched_data == ENTER_KEY || latched_data == LINE_FEED) begin
                        
                        // 버퍼에 내용이 있을 때만 실행 
                        // (0D 0A가 연속으로 올 경우, 뒤에 오는 0A는 ptr=0이므로 무시됨)
                        if (ptr > 0) begin
                            
                            // 1. ledallon
                            if(ptr==8 && 
                               buffer[0]=="l" && buffer[1]=="e" && buffer[2]=="d" && buffer[3]=="a" && 
                               buffer[4]=="l" && buffer[5]=="l" && buffer[6]=="o" && buffer[7]=="n")
                            begin
                                led <= 16'hFFFF;
                            end 
                            
                            // 2. ledalloff
                            else if(ptr==9 && 
                                    buffer[0]=="l" && buffer[1]=="e" && buffer[2]=="d" && buffer[3]=="a" && 
                                    buffer[4]=="l" && buffer[5]=="l" && buffer[6]=="o" && buffer[7]=="f" && buffer[8]=="f") 
                            begin
                                led <= 16'h0000;
                            end 
                            
                            // 3. led00on
                            else if(ptr==7 && 
                                    buffer[0]=="l" && buffer[1]=="e" && buffer[2]=="d" && buffer[3]=="0" && 
                                    buffer[4]=="0" && buffer[5]=="o" && buffer[6]=="n") 
                            begin
                                led[0] <= 1'b1;
                            end 
                            
                            // 4. led00off
                            else if(ptr==8 && 
                                    buffer[0]=="l" && buffer[1]=="e" && buffer[2]=="d" && buffer[3]=="0" && 
                                    buffer[4]=="0" && buffer[5]=="o" && buffer[6]=="f" && buffer[7]=="f") 
                            begin
                                led[0] <= 1'b0;
                            end
                            
                            // 실행 후 포인터 초기화 (다음 명령어를 위해 비움)
                            ptr <= 0; 
                        end
                    end
                    
                    // 일반 문자일 경우 버퍼에 저장
                    else begin 
                        if (ptr < 15) begin
                            buffer[ptr] <= latched_data;
                            ptr         <= ptr + 1;
                        end
                    end
                    
                    // 다음 데이터 처리를 위해 IDLE 복귀
                    state <= S_IDLE;
                end
                
                default: state <= S_IDLE;
            endcase
        end
    end
endmodule