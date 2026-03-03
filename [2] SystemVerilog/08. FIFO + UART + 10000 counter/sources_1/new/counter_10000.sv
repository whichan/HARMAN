`timescale 1ns / 1ps

module counter_10000(
    input clk,
    input reset,
    input clear, 
    input run_stop,  
    input tick_10khz, 
    input mode,
    
    input [13:0] set_value,
    input set_en,

    output reg [13:0] count
    );
    
    parameter MAX_CNT = 10_000;
    
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            count <= 9998;
        end 
        else if (clear) begin
            // [우선순위 2]
            count <= 0;
        end 
        else if(set_en) begin
            count <= set_value;
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