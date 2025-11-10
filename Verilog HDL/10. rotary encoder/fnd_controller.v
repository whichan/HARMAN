`timescale 1ns / 1ps

module fnd_controller(
    input clk,
    input reset,
    input [7:0] r_count, //0~255. LED[0] ~ LED[7]로 카운팅
    input [1:0] r_direction, //시계방향: F, 반시계방향: b
    output [3:0] an,
    output [7:0] seg
);


wire [1:0] w_sel;
wire [3:0] w_d1, w_d10, w_d100, w_d1000;

fnd_digit_select u_fnd_digit_select(
    .clk(clk),
    .reset(reset),
    .sel(w_sel)
);


bin2bcd3digit u_bin2bcd3digit(
    .r_count(r_count),
    .d1(w_d1),
    .d10(w_d10),
    .d100(w_d100)
);

fnd_display u_fnd_display(
    .clk(clk),
    .reset(reset),
    .digit_sel(w_sel),
    .d1(w_d1),
    .d10(w_d10),
    .d100(w_d100),
    .r_direction(r_direction),
    .an(an),
    .seg(seg)
);
endmodule



//----------[Module 1. 데이터 변환기]----------//
//1ms씩 sel을 변환시키는게 목적
module fnd_digit_select(
    input clk,
    input reset,
    output reg [1:0] sel //00, 01, 10, 11
);

reg [$clog2(100_000)-1:0] r_1ms_counter = 0;

always @(posedge clk or posedge reset) begin
    if(reset) begin
        r_1ms_counter <= 0;
        sel <= 0;
    end else begin
        if(r_1ms_counter == 99_999) begin
            r_1ms_counter <= 0;
            sel <= sel + 1;
        end else begin
            r_1ms_counter <= r_1ms_counter + 1;
        end
    end
end
endmodule


//----------[Module 2. 2진수 -> 10진수]----------//
module bin2bcd3digit(
    input [7:0] r_count,
    output [3:0] d1,
    output [3:0] d10,
    output [3:0] d100
);

    assign d1 = r_count % 10;
    assign d10 = (r_count/10) % 10;
    assign d100 = (r_count/100) % 10;


endmodule


//----------[Module 3. 디스플레이]----------//
module fnd_display(
    input clk, //깜박임을 구현하기 위해 새로 넣어줌
    input reset, //깜박임을 구현하기 위해 새로 넣어줌
    input [1:0] digit_sel,
    input [3:0]  d1,
    input [3:0]  d10,
    input [3:0]  d100,
    input [1:0] r_direction,
    output reg [3:0] an,
    output reg [7:0] seg 
);

    reg [3:0] bcd_data; //0~9


    //----------1초마다 깜박임----------//

    reg [$clog2(50_000_000)-1:0] r_blink_counter = 0;
    /*10ns=1, 1s=100_000_000, 0.5s=50_000_000*/
    reg r_blink_toggle;

    always @(posedge clk or posedge reset) begin
        if(reset) begin
            r_blink_counter <= 0;
            r_blink_toggle <= 0;
        end else begin
            if(r_blink_counter == 49_999_999) begin
                r_blink_counter <= 0;
                r_blink_toggle <= ~r_blink_toggle;
            end else begin
                r_blink_counter <= r_blink_counter + 1;
            end
        end
    end

    always @(*) begin
        case(digit_sel) //digit_sel에 따라 자릿수 변경
            2'b00: begin bcd_data = d1; an=4'b1110; end //bcd_data(0~9)를 1의 자리에 넣기
            2'b01: begin bcd_data = d10; an=4'b1101; end //"를 10의 자리에 넣기
            2'b10: begin bcd_data = d100; an=4'b1011; end //"를 100의 자리에 넣기

            2'b11: begin
            case (r_direction)
                2'b01: bcd_data = 4'd12; //12 -> F
                2'b10: bcd_data = 4'd13; //13 -> b
                default: bcd_data = 4'd15; //꺼짐
            endcase

            if(r_blink_toggle) //r_blink_toggle = 1 일 때 
            an=4'b1111; //1000의 자릿수 끔
            else
            an=4'b0111; //1000의 자릿수 킴
            end

            default: begin bcd_data = 4'b0000; an=4'b1111; end
        endcase
    end

    always @(*) begin //bcd_data가 0~9에 따라 그에 맞는 7segment 모양 출력
        case(bcd_data)
            4'd0: seg = 8'b11000000;  // 0
            4'd1: seg = 8'b11111001;  // 1
            4'd2: seg = 8'b10100100;  // 2
            4'd3: seg = 8'b10110000;  // 3
            4'd4: seg = 8'b10011001;  // 4
            4'd5: seg = 8'b10010010;  // 5
            4'd6: seg = 8'b10000010;  // 6
            4'd7: seg = 8'b11111000;  // 7
            4'd8: seg = 8'b10000000;  // 8
            4'd9: seg = 8'b10010000;  // 9

            4'd12: seg = 8'b10001110; //F
            4'd13: seg = 8'b10000011; //b
            default: seg = 8'b11111111;  // fnd all off
        endcase
        
    end
endmodule