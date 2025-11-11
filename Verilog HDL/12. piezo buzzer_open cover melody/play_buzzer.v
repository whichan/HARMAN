`timescale 1ns / 1ps

module play_buzzer(
    input clk,
    input reset,
    input btnL,
    input btnR,
    output reg buzzer
    );

    //========== btn rising edge 감지 ==========//
    reg r_prev_btnL = 0;
    reg r_prev_btnR = 0;
    
    always @(posedge clk) begin
        r_prev_btnL <= btnL;
        r_prev_btnR <= btnR;
    end

    wire w_btnL_pressed = (btnL && !r_prev_btnL);
    wire w_btnR_pressed = (btnR && !r_prev_btnR);

    
    //========== btnL: 1kHz, 2kHz, 3kHz, 4kHz ==========//

    reg r_playingL = 0; //재생 중인지?(재생 중일 때 버튼을 누르는 것과 재생 중이 아닐 때 버튼을 눌렀을 경우 수행하는 동작이 다름)
    reg [$clog2(328_000_000)-1:0] r_timeL = 0; //시간 재는 카운터
                                              //총 70ms*4 + 3s = 3.28s
    reg [$clog2(100_000_000/(2*1000))-1:0] r_freq_cntL = 0; //소리 만드는 카운터
    //1kHz일 때 비트수가 제일 많이 필요하므로 1kHz를 기준으로 맞춤
    reg r_soundL = 0; //소리 ON/OFF


    //시간 구간
    parameter L_1khz = 7_000_000; //0~7M: 70ms
    parameter L_2khz = 14_000_000; //7M~14M: 70ms
    parameter L_3khz = 21_000_000; //14M~21M: 70ms
    parameter L_4khz = 28_000_000; //21M~28M: 70ms
    parameter L_SILENT = 328_000_000; //28M~328M: 3s, 무음

    always @(posedge clk or posedge reset) begin
        if(reset) begin //reset=1
            r_playingL <= 0;
            r_timeL <= 0;
            r_freq_cntL <= 0;
            r_soundL <= 0;
        end else begin //reset=0
            if(w_btnL_pressed) begin//만약 btnL을 누르면
                r_playingL <= ~r_playingL;
                r_timeL <= 0;
                r_freq_cntL <= 0;
            end

            if(r_playingL) begin //만약 play 중이라면
                if(r_timeL >= L_SILENT)
                    r_timeL <= 0;
                else
                    r_timeL <= r_timeL + 1;


                // =====1kHz 구간=====//
                if(r_timeL < L_1khz) begin
                    if(r_freq_cntL >= 49_999) begin
                        r_freq_cntL <= 0;
                        r_soundL <= ~r_soundL;
                    end else begin
                        r_freq_cntL <= r_freq_cntL + 1;
                    end
                end

                //===== 2khz 구간 =====//
                else if(r_timeL < L_2khz) begin
                    if(r_freq_cntL >= 24_999) begin
                        r_freq_cntL <= 0;
                        r_soundL <= ~r_soundL;
                    end else begin
                        r_freq_cntL <= r_freq_cntL + 1;
                    end
                end


                //===== 3khz 구간 =====//
                else if(r_timeL < L_3khz) begin
                    if(r_freq_cntL >= 16_666) begin
                        r_freq_cntL <= 0;
                        r_soundL <= ~r_soundL;
                    end else begin
                        r_freq_cntL <= r_freq_cntL + 1;
                    end
                end


                //===== 4khz 구간 =====//
                else if(r_timeL < L_4khz) begin
                    if(r_freq_cntL >= 12_499) begin
                        r_freq_cntL <= 0;
                        r_soundL <= ~r_soundL;
                    end else begin
                        r_freq_cntL <= r_freq_cntL + 1;
                    end
                end

                //===== 무음 구간 =====//
                else if (r_timeL < L_SILENT) begin
                    r_soundL <= 0;
                end

                else begin
                    r_playingL <= 0;
                    r_timeL <= 0;
                    r_freq_cntL <= 0;
                    r_soundL <= 0;
                end
            end
        end
    end


    //========== btnR: 261Hz, 329Hz, 392Hz, 554Hz ==========//

    reg r_playingR = 0; //재생 중인지?(재생 중일 때 버튼을 누르는 것과 재생 중이 아닐 때 버튼을 눌렀을 경우 수행하는 동작이 다름)
    reg [$clog2(328_000_000)-1:0] r_timeR = 0; //시간 재는 카운터
                                              //총 70ms*4 + 3s = 3.28s
    reg [$clog2(100_000_000/(2*261))-1:0] r_freq_cntR = 0; //소리 만드는 카운터
    //1kHz일 때 비트수가 제일 많이 필요하므로 1kHz를 기준으로 맞춤
    reg r_soundR = 0; //소리 ON/OFF

    parameter R_261hz = 7_000_000; //0~7M: 70ms
    parameter R_329hz = 14_000_000; //7M~14M: 70ms
    parameter R_392hz = 21_000_000; //14M~21M: 70ms
    parameter R_554hz = 28_000_000; //21M~28M: 70ms
    parameter R_SILENT = 328_000_000; //28M~328M: 3s, 무음


    always @(posedge clk or posedge reset) begin
        if(reset) begin //reset=1
            r_playingR <= 0;
            r_timeR <= 0;
            r_freq_cntR <= 0;
            r_soundR <= 0;
        end else begin //reset=0
            if(w_btnR_pressed) begin//만약 btnL을 누르면
                r_playingR <= ~r_playingR;
                r_timeR <= 0;
                r_freq_cntR <= 0;
            end

            if(r_playingR) begin //만약 play 중이라면
                if(r_timeR >= R_SILENT)
                    r_timeR <= 0;
                else
                    r_timeR <= r_timeR + 1;


                // =====261Hz 구간=====//
                if(r_timeR < R_261hz) begin
                    if(r_freq_cntR >= 49_999) begin
                        r_freq_cntR <= 0;
                        r_soundR <= ~r_soundR;
                    end else begin
                        r_freq_cntR <= r_freq_cntR + 1;
                    end
                end

                //===== 329hz 구간 =====//
                else if(r_timeR < R_329hz) begin
                    if(r_freq_cntR >= 24_999) begin
                        r_freq_cntR <= 0;
                        r_soundR <= ~r_soundR;
                    end else begin
                        r_freq_cntR <= r_freq_cntR + 1;
                    end
                end


                //===== 392hz 구간 =====//
                else if(r_timeR < R_392hz) begin
                    if(r_freq_cntR >= 16_666) begin
                        r_freq_cntR <= 0;
                        r_soundR <= ~r_soundR;
                    end else begin
                        r_freq_cntR <= r_freq_cntR + 1;
                    end
                end


                //===== 554hz 구간 =====//
                else if(r_timeR < R_554hz) begin
                    if(r_freq_cntR >= 12_499) begin
                        r_freq_cntR <= 0;
                        r_soundR <= ~r_soundR;
                    end else begin
                        r_freq_cntR <= r_freq_cntR + 1;
                    end
                end

                //===== 무음 구간 =====//
                else if (r_timeR < R_SILENT) begin
                    r_soundR <= 0;
                end

                else begin
                    r_playingR <= 0;
                    r_timeR <= 0;
                    r_freq_cntR <= 0;
                    r_soundR <= 0;
                end
            end
        end
    end

always @(*) begin
    buzzer = r_soundL | r_soundR;
end

endmodule