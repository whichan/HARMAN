`timescale 1ns / 1ps


module btn_command_controller_minsec(
    input clk,
    input reset, //btnU
    input [2:0]btn, //btnC: 모드 바꿈   btnR: 재생
    output reg [15:0] led,  //현재 상태 표시용
    output [13:0] seg_data,  //FND에 표시할 9,999 값
    output reg switch_to_stopwatch,
    output reg dp_blink
    );


    //----------내부 레지스터----------//
    reg [$clog2(100_000_000)-1:0] r_sec_tick_counter = 0; //1초 주기를 만들기 위한 100MHz tick counter

    reg [5:0] r_sec_counter = 0; //초 카운터. 0~59
    reg [6:0] r_min_counter = 0; //분 카운터. 0~99

    //----------rising edge 감지----------//
    reg r_prev_btnC = 0;
    wire w_btnC_pressed = (btn[1] && !r_prev_btnC);
    

    //----------FSM----------//
    always @(posedge clk, posedge reset) begin
        if(reset) begin
            r_sec_tick_counter <= 0;
            r_sec_counter <= 0;
            r_min_counter <= 0;
            r_prev_btnC <= 0;
            switch_to_stopwatch <= 0;
            dp_blink <= 1'b0;
        end else begin





            r_prev_btnC <= btn[1]; //엣지 감지를 위해 이전 상태 저장
            switch_to_stopwatch <= 0;
            //-----[btnC]-----//
            if(w_btnC_pressed) begin
                switch_to_stopwatch <= 1'b1;
            end
            
            //-----카운터-----//
            if(r_sec_tick_counter == 27'd99_999_999) begin
                r_sec_tick_counter <= 0;
                if(r_sec_counter == 6'd59) begin
                    r_sec_counter <= 0;
                    if(r_min_counter == 7'd99)begin
                        r_min_counter <= 0;
                    end else begin
                    r_min_counter <= r_min_counter + 1;
                    end
                end else begin
                r_sec_counter <= r_sec_counter +1;
                end
            end else begin
                r_sec_tick_counter <= r_sec_tick_counter +1;
            end

            if(r_sec_tick_counter<27'd50_000_000) begin
                dp_blink <= 1'b1;
            end else begin
                dp_blink <= 1'b0;
            end
        end
    end
    
assign seg_data = (r_min_counter * 100) + r_sec_counter;

always @(*) begin
    led = 16'b0;
    led[12] = 1'b1;
end
endmodule
