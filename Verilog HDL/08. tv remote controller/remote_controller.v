`timescale 1ns / 1ps


module remote_controller(
    input clk,
    input reset, //btnL
    input [2:0] btn, //btnU, btnD
    output reg [3:0] ch
    );

    //-----channel 최대 최소-----//
    parameter CH_MIN = 4'd0; //channel 0이 최소
    parameter CH_MAX = 4'd3; //channel 3이 최대

    //-----btn rising edge 감지-----//
    reg r_prev_btnU;
    reg r_prev_btnD;

    always @(posedge clk, posedge reset ) begin
        if (reset) begin
            r_prev_btnD <= 1'b0;
            r_prev_btnU <= 1'b0;
        end else begin 
            r_prev_btnD <= btn[1];
            r_prev_btnU <= btn[2];
        end
    end
    
    wire w_btnD_pressed = (btn[1] && !r_prev_btnD); //btn[1]은 btnD이고, btn[1]=0->1이 되고 !r_prev_btnD=1 (원래 1) 이니까 누르는 순간 w_btnD_pressed = 1
    wire w_btnU_pressed = (btn[2] && !r_prev_btnU);
    
    //-----FSM-----// 

    reg [3:0] ch_current; //현재 채널
    reg [3:0] ch_next; //다음 채널

    always @(posedge clk or posedge reset) begin
        if(reset) begin
            ch_current <= 4'd0; //만약 reset=1이면 모든 ch_current 다 0으로
        end else begin
            ch_current <= ch_next; //만약 reset=1이 아니라면 ch_next를 ch_current로 반영
        end
    end
    
    always @(*) begin
        ch_next = ch_current; //특별한 일이 없으면 다음상태는 현재 상태를 그대로 유지한다.
        if(w_btnU_pressed) begin
            if(ch_current >= CH_MAX)
                ch_next = CH_MIN;
            else
                ch_next = ch_current + 1'b1;
        end
        else if(w_btnD_pressed) begin
            if(ch_current <= CH_MIN)
                ch_next = CH_MAX;
            else
                ch_next = ch_current - 1'b1;
        end
    end

    //-----LED 출력-----//
    
    always @(*) begin
        case(ch_current)
            4'd0: ch=4'b0001;
            4'd1: ch=4'b0010;
            4'd2: ch=4'b0100;
            4'd3: ch=4'b1000;
            default: ch=4'b0000;
        endcase
    end

endmodule