`timescale 1ns / 1ps

module shift_register(
    input clk,
    input reset, //
    input btnU, //1입력
    input btnD, //0입력
    output [7:0] led
    );

    reg [6:0] shift_reg; //7비트
    reg [6:0] next_shift_reg;
    
    reg prev_btnU;
    reg prev_btnD;

    wire pressed_btnU = btnU && !prev_btnU;
    wire pressed_btnD = btnD && !prev_btnD;

    always @(posedge clk or posedge reset) begin
        if(reset) begin
            shift_reg <= 7'b0000000;
            prev_btnU <= 1'b0;
            prev_btnD <= 1'b0;
        end else begin
            shift_reg <= next_shift_reg;
            prev_btnU <= btnU;
            prev_btnD <= btnD;
        end
    end


    always @(*) begin
        next_shift_reg = shift_reg;
        
        if(pressed_btnU) begin
            next_shift_reg = {shift_reg[5:0], 1'b1}; //하위 6비트 + 1 //ex)1'001101' 이었으면 001101만 따고, 오른쪽에 1 붙임
        end else if (pressed_btnD) begin
            next_shift_reg = {shift_reg[5:0], 1'b0}; //하위 6비트 + 0 //ex) 1'001101' 이었으면 001101만 따고, 오른쪽에 0 붙임
        end
    end
    
    assign led[7:1] = shift_reg[6:0];
    assign led[0] = (shift_reg == 7'b1010111);
endmodule
