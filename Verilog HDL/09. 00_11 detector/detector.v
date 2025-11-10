`timescale 1ns / 1ps

module detector(
    input clk,
    input reset, //btnC
    input btnU,
    input btnD,
    output [15:0] led //00이면 led[15] ON, 11이면 led[14] ON, 아닌 경우는 둘다 OFF
                      //led[0]~led[6] 까지 shift
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

    assign led[6:0] = shift_reg[6:0];

    //----------[[FSM]]----------//
    //00,11 detector

    parameter IDLE = 3'b000;
    parameter DETECT_0 = 3'b001;
    parameter DETECT_1 = 3'b010;
    parameter DETECT_00 = 3'b100;
    parameter DETECT_11 = 3'b101;

    reg [2:0] state_current;
    reg [2:0] state_next;
    
    //-----[always block 1]-----//
    always @(posedge clk or posedge reset) begin
        if(reset)
        state_current <= IDLE;
        else
        state_current <= state_next;
    end

    //-----[always block 2]: 현재 상태와 현재 입력에 의해 다음 상태 결정-----//
    always @(*) begin
        state_next = state_current;
        
        if(pressed_btnU) begin
            case (state_current)
                IDLE: state_next = DETECT_1;
                DETECT_0: state_next = DETECT_1;
                DETECT_1: state_next = DETECT_11;
                DETECT_00: state_next = DETECT_1;
                DETECT_11: state_next = DETECT_11;
                default: state_next = IDLE;
            endcase
        end else if(pressed_btnD) begin
            case (state_current)
                IDLE: state_next = DETECT_0;
                DETECT_0: state_next = DETECT_00;
                DETECT_1: state_next = DETECT_0;
                DETECT_00: state_next = DETECT_00;
                DETECT_11: state_next = DETECT_0;
                default: state_next = IDLE;
            endcase   
        end
    end

    //현재 상태에 따라 출력 결정-----//
    assign led[15] = (state_current == DETECT_00);
    assign led[14] = (state_current == DETECT_11);

    assign led[13:7] = 7'b0; //사용하지 않는 led는 0으로
    
endmodule