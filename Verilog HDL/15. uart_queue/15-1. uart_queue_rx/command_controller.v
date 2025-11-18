`timescale 1ns / 1ps

module command_controller(
    input clk,
    input reset,
    input [7:0] queue_data_in,
    input queue_empty,

    output reg queue_rd_en,
    output reg [15:0] led
);
    
    parameter S_IDLE = 2'd0; //대기 상태
    parameter S_READ = 2'd1; //읽기 상태
    parameter S_CHECK = 2'd2; //확인 상태

    reg [1:0] state;
    reg [7:0] buffer [0:15]; //명령어 최대 16글자
    reg [3:0] ptr; //몇번째 칸인지 가리키는 포인터

    always @(posedge clk or posedge reset) begin
        if(reset) begin
           state <= S_IDLE;
           queue_rd_en <= 0;
           led <= 16'h0000;
           ptr <= 0; 
        end else begin
            // ===== FSM ===== //
            case(state)
                S_IDLE: begin //IDLE: 큐가 비었나 안 비었나 검사 중
                    queue_rd_en <= 0;
                    if(queue_empty == 0) begin
                        state <= S_READ; //큐에 데이터가 있으면 읽기
                    end
                end

                S_READ: begin
                    queue_rd_en <= 1;
                    state <= S_CHECK;
                end

                S_CHECK: begin //받은 데이터 확인, buffer에 저장
                    queue_rd_en <= 0;
                    state <= S_IDLE;

                    //ledallon
                    if(ptr==7 && queue_data_in=="n" && buffer[0]=="l" && buffer[1]=="e" && buffer[2]=="d" && buffer[3]=="a" && 
                       buffer[4]=="l" && buffer[5]=="l" && buffer[6]=="o") begin
                        led <= 16'hFFFF;
                        ptr <= 0;
                    end else if (ptr==8 && queue_data_in=="f" &&
                        buffer[0]=="l" && buffer[1]=="e" && buffer[2]=="d" && buffer[3]=="a" && 
                        buffer[4]=="l" && buffer[5]=="l" && buffer[6]=="o" && buffer[7]=="f") begin
                            led <= 16'h0000;
                            ptr <= 0;
                    end else if (ptr==6 && queue_data_in=="n" &&
                        buffer[0]=="l" && buffer[1]=="e" && buffer[2]=="d" && 
                        buffer[3]=="0" && buffer[4]=="0" && buffer[5]=="o") begin
                            led[0] <= 1'b1;
                            ptr <= 0;
                    end else if (ptr==7 && queue_data_in=="f" &&
                        buffer[0]=="l" && buffer[1]=="e" && buffer[2]=="d" && 
                        buffer[3]=="0" && buffer[4]=="0" && buffer[5]=="o" && buffer[6]=="f") begin
                            led[0] <= 1'b0;
                            ptr <= 0;        
                        end else begin
                            if(ptr<15) begin
                                buffer[ptr] <= queue_data_in;
                                ptr <= ptr + 1;
                            end else begin
                                ptr <= 0;
                            end
                        end
                end
            endcase
        end
    end
endmodule