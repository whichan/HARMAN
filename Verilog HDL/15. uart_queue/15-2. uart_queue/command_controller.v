`timescale 1ns / 1ps

module command_controller(
    input clk,
    input reset,
    
    // Circular Queue 인터페이스
    input [7:0] queue_data_in,
    input queue_empty,
    output reg queue_rd_en,
    
    // LED 출력
    output reg [15:0] led,

    // [추가] Data Sender 인터페이스
    output reg send_trigger,    // "전송 시작해!" (Pulse)
    output reg [1:0] cmd_type,  // 0:myname, 1:upcounter, 2:help
    input sender_busy           // "나 전송 중이야 기다려"
);

    // 파라미터
    parameter ENTER_KEY = 8'h0D; 
    parameter LINE_FEED = 8'h0A; 

    parameter S_IDLE  = 2'd0; 
    parameter S_READ  = 2'd1; 
    parameter S_CHECK = 2'd2; 

    reg [1:0] state;
    reg [7:0] buffer [0:15]; 
    reg [3:0] ptr;           
    
    reg [7:0] latched_data; 

    always @(posedge clk or posedge reset) begin
        if(reset) begin
            state        <= S_IDLE;
            queue_rd_en  <= 0;
            led          <= 16'h0000;
            ptr          <= 0; 
            latched_data <= 0;
            
            // [추가] TX 관련 초기화
            send_trigger <= 0;
            cmd_type     <= 0;
        end else begin
            // 트리거는 1클럭만 유지하고 자동으로 꺼짐 (Pulse 생성)
            send_trigger <= 0; 

            case(state)
                
                // 1. IDLE: 데이터 대기
                S_IDLE: begin
                    queue_rd_en <= 0;
                    
                    // [수정] 큐에 데이터가 있고 + "전송 모듈이 놀고 있을 때(!sender_busy)"만 진행
                    // 앞선 명령어가 전송 중일 때 또 읽으면 꼬일 수 있으므로 대기함.
                    if(queue_empty == 0 && sender_busy == 0) begin
                        state <= S_READ;
                    end
                end

                // 2. READ: 데이터 캡처
                S_READ: begin
                    queue_rd_en  <= 1; 
                    latched_data <= queue_data_in; 
                    state        <= S_CHECK;
                end

                // 3. CHECK: 명령어 분석 및 실행
                S_CHECK: begin
                    queue_rd_en <= 0; 

                    if(latched_data == ENTER_KEY || latched_data == LINE_FEED) begin
                        if (ptr > 0) begin
                            
                            // --- [기존] LED 제어 명령어 ---
                            if(ptr==8 && buffer[0]=="l" && buffer[1]=="e" && buffer[2]=="d" && buffer[3]=="a" && 
                               buffer[4]=="l" && buffer[5]=="l" && buffer[6]=="o" && buffer[7]=="n")
                                led <= 16'hFFFF;
                            
                            else if(ptr==9 && buffer[0]=="l" && buffer[1]=="e" && buffer[2]=="d" && buffer[3]=="a" && 
                                    buffer[4]=="l" && buffer[5]=="l" && buffer[6]=="o" && buffer[7]=="f" && buffer[8]=="f") 
                                led <= 16'h0000;
                            
                            else if(ptr==7 && buffer[0]=="l" && buffer[1]=="e" && buffer[2]=="d" && buffer[3]=="0" && 
                                    buffer[4]=="0" && buffer[5]=="o" && buffer[6]=="n") 
                                led[0] <= 1'b1;
                            
                            else if(ptr==8 && buffer[0]=="l" && buffer[1]=="e" && buffer[2]=="d" && buffer[3]=="0" && 
                                    buffer[4]=="0" && buffer[5]=="o" && buffer[6]=="f" && buffer[7]=="f") 
                                led[0] <= 1'b0;

                            // --- [추가] TX 응답 명령어 ---
                            
                            // 5. myname (6글자) -> "Whichan" 전송
                            else if(ptr==6 && buffer[0]=="m" && buffer[1]=="y" && buffer[2]=="n" && 
                                    buffer[3]=="a" && buffer[4]=="m" && buffer[5]=="e") 
                            begin
                                cmd_type     <= 2'd0; // myname
                                send_trigger <= 1'b1; // data_sender 동작 개시!
                            end
                            
                            // 6. upcounter (9글자) -> 숫자 전송
                            else if(ptr==9 && buffer[0]=="u" && buffer[1]=="p" && buffer[2]=="c" && 
                                    buffer[3]=="o" && buffer[4]=="u" && buffer[5]=="n" && 
                                    buffer[6]=="t" && buffer[7]=="e" && buffer[8]=="r") 
                            begin
                                cmd_type     <= 2'd1; // upcounter
                                send_trigger <= 1'b1;
                            end

                            // 7. help (4글자) -> 도움말 전송
                            else if(ptr==4 && buffer[0]=="h" && buffer[1]=="e" && buffer[2]=="l" && buffer[3]=="p") 
                            begin
                                cmd_type     <= 2'd2; // help
                                send_trigger <= 1'b1;
                            end

                            ptr <= 0; 
                        end
                    end
                    else begin 
                        if (ptr < 15) begin
                            buffer[ptr] <= latched_data;
                            ptr         <= ptr + 1;
                        end
                    end
                    
                    state <= S_IDLE;
                end
                
                default: state <= S_IDLE;
            endcase
        end
    end
endmodule