`timescale 1ns / 1ps

// LED Toggle 모듈
module led_toggle_tick(
    input i_clk,
    input i_reset,
    input i_btn_pulse,
    output reg o_led
    );
    
    always @(posedge i_clk, posedge i_reset) begin
        if(i_reset) begin
            o_led <= 1'b0;
        end
        else begin
            if(i_btn_pulse) begin
                o_led <= ~o_led;  // 토글
            end
        end
    end
    
endmodule
