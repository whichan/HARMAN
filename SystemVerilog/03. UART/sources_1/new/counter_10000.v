`timescale 1ns / 1ps

module counter_10000(
    input clk,
    input reset,
    input clear, 
    input run_stop,  
    input tick_10khz, 
    input mode,
    
    output reg [$clog2(10000)-1:0] count
    );
    
    parameter MAX_CNT = 10_000;
    
    // [중요] 하나의 always 블록 안에서 모든 상황을 제어해야 합니다.
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            count <= 9998;
        end 
        else if (clear) begin
            // [우선순위 2]
            count <= 0;
        end 
        else if (tick_10khz && run_stop) begin
            // [우선순위 3]
            case(mode)
                1'b1: begin // Up Counter
                    if(count == MAX_CNT - 1) begin
                        count <= 0;
                    end else begin
                        count <= count + 1;
                    end
                end

                1'b0: begin // Down Counter

                    if(count == 0) begin
                        count <= MAX_CNT - 1; 
                    end else begin
                        count <= count - 1;
                    end
                end

                default: count <= count;
            endcase
        end
    end

endmodule