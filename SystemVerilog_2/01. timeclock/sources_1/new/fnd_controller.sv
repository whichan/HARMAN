`timescale 1ns / 1ps

module fndController (
    input  logic       clk,
    input  logic       reset,
    input  logic [5:0] msec,
    input  logic [5:0] sec,
    input  logic [5:0] min,
    input  logic [5:0] hour,
    output logic [3:0] fnd_com,
    output logic [7:0] fnd_font
);

    logic [3:0] sec_digit_1, sec_digit_10, min_digit_1, min_digit_10, hour_digit_1, hour_digit_10;
    logic [3:0] min_sec_digit;
    logic tick_1khz;
    logic [1:0] digit_sel;

    clk_div_1khz U_Clk_Div_1Khz (
        .clk      (clk),
        .reset    (reset),
        .tick_1khz(tick_1khz)
    );

    counter_2bit U_Counter_2bit (
        .clk   (clk),
        .reset (reset),
        .i_tick(tick_1khz),
        .count (digit_sel)
    );

    decoder_2x4 U_Digit_Sel (
        .x(digit_sel),
        .y(fnd_com)
    );


    digit_splitter U_SecSplitter (
        .digit   (sec),
        .digit_1 (sec_digit_1),
        .digit_10(sec_digit_10)
    );

    digit_splitter U_MinSplitter (
        .digit   (min),
        .digit_1 (min_digit_1),
        .digit_10(min_digit_10)
    );

    digit_splitter U_HourSplitter (
        .digit   (hour),
        .digit_1 (hour_digit_1),
        .digit_10(hour_digit_10)
    );


    mux_4X1 U_MinSecMux (
        .sel(digit_sel),
        .x0 (sec_digit_1),
        .x1 (sec_digit_10),
        .x2 (min_digit_1),
        .x3 (min_digit_10),
        .y  (min_sec_digit)
    );

    BCDtoSEG_decoder U_BCDtoSEG (
        .bcd(min_sec_digit),
        .seg(fnd_font)
    );
endmodule

module digit_splitter (
    input  logic [5:0] digit,
    output logic [3:0] digit_1,
    output logic [3:0] digit_10
);
    assign digit_1  = digit % 10;
    assign digit_10 = digit / 10;
endmodule

module mux_4X1 (
    input  logic [1:0] sel,
    input  logic [3:0] x0,
    input  logic [3:0] x1,
    input  logic [3:0] x2,
    input  logic [3:0] x3,
    output logic [3:0] y
);
    always_comb begin
        y = 4'b0000;
        case (sel)
            2'b00:   y = x0;
            2'b01:   y = x1;
            2'b10:   y = x2;
            2'b11:   y = x3;
            default: y = 4'b0000;
        endcase
    end
endmodule

module clk_div_1khz (
    input  logic clk,
    input  logic reset,
    output logic tick_1khz
);
    logic [$clog2(100_000)-1 : 0] div_counter;

    assign tick_1khz = (div_counter == 100_000 - 1);

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            div_counter <= 0;
        end else begin
            if (div_counter == 100_000 - 1) begin
                div_counter <= 0;
            end else begin
                div_counter <= div_counter + 1;
            end
        end
    end
endmodule

module counter_2bit (
    input logic clk,
    input logic reset,
    input logic i_tick,
    output logic [1:0] count
);
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            count <= 0;
        end else begin
            if (i_tick) begin
                count <= count + 1;
            end
        end
    end
endmodule

module decoder_2x4 (
    input  logic [1:0] x,
    output logic [3:0] y
);
    always_comb begin
        y = 4'b1111;
        case (x)
            2'b00: y = 4'b1110;
            2'b01: y = 4'b1101;
            2'b10: y = 4'b1011;
            2'b11: y = 4'b0111;
        endcase
    end
endmodule

module BCDtoSEG_decoder (
    input      [3:0] bcd,
    output reg [7:0] seg
);
    always @(bcd) begin
        seg = 8'hff;
        case (bcd)
            4'h0: seg = 8'hc0;
            4'h1: seg = 8'hf9;
            4'h2: seg = 8'ha4;
            4'h3: seg = 8'hb0;
            4'h4: seg = 8'h99;
            4'h5: seg = 8'h92;
            4'h6: seg = 8'h82;
            4'h7: seg = 8'hf8;
            4'h8: seg = 8'h80;
            4'h9: seg = 8'h90;
            4'ha: seg = 8'h88;
            4'hb: seg = 8'h83;
            4'hc: seg = 8'hc6;
            4'hd: seg = 8'ha1;
            4'he: seg = 8'h86;
            4'hf: seg = 8'h8e;
            default: seg = 8'hff;
        endcase
    end
endmodule
