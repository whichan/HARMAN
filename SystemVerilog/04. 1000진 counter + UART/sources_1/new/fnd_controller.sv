`timescale 1ns / 1ps

module fnd_controller (
    input         clk,
    input         reset,
    input  [13:0] counter,
    output [ 3:0] fnd_com,
    output [ 7:0] fnd_data
);

wire [1:0] w_sel;
wire [3:0] w_bcd;
wire [3:0] w_digit_1, w_digit_10, w_digit_100, w_digit_1000;
wire w_tick;

    clock_div U_CLOCK_DIV(
        .clk(clk),
        .reset(reset),

        .tick(w_tick)
    );

    counter_4 U_COUNTER_4(
        .clk(w_tick),
        .reset(reset),

        .sel(w_sel)
    );

    //for digit select to fnd
    decoder_2X4 U_DECODER_2X4 (
        .sel(w_sel),

        .fnd_com(fnd_com)
    );

    digit_splitter  U_DS(
        .counter(counter),

        .digit_1(w_digit_1),
        .digit_10(w_digit_10),
        .digit_100(w_digit_100),
        .digit_1000(w_digit_1000)
    );

    mux_4X1 U_MUX_4X1(
        .sel(w_sel),
        .digit_1(w_digit_1),
        .digit_10(w_digit_10),
        .digit_100(w_digit_100),
        .digit_1000(w_digit_1000),

        . bcd(w_bcd)
    );

    bcd U_BCD (
        .bcd(w_bcd),
        .fnd_data(fnd_data)
    );

endmodule


module clock_div (  //400Hz Clock divider
    input        clk,
    input        reset,

    output tick
);
    localparam  MAX_COUNT = 100_000_000 / 400 ;
    reg [$clog2(MAX_COUNT)-1:0] r_counter;
    reg  r_tick;

    assign tick = r_tick;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter   <= 0;
            r_tick      <= 0;
        end else begin
            if(r_counter == MAX_COUNT -1 )begin
                r_counter   <= 0;
                r_tick      <= 1'b1;
            end else begin
                r_counter <= r_counter +1;
                r_tick <= 0;
            end
        end
    end
endmodule



//for generating 400hz sel counter
module counter_4 ( //몇번째 자리를 킬건지?
    input        clk,
    input        reset,

    output [1:0] sel
);
    reg [1:0] r_counter;
    assign sel = r_counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_counter <= 0;
        end else begin
            r_counter <= r_counter + 1;
        end
    end
    
endmodule

//for digit select to fnd
module decoder_2X4 ( 
    input   [1:0] sel,

    output  [3:0] fnd_com
);
    reg [3:0] o_fnd_com;
    assign fnd_com = o_fnd_com;

    always @(*) begin
        case (sel)
            2'b00:   o_fnd_com = 4'b1110;     //fnd com digit 1
            2'b01:   o_fnd_com = 4'b1101;     //fnd com digit 10
            2'b10:   o_fnd_com = 4'b1011;     //fnd com digit 100
            2'b11:   o_fnd_com = 4'b0111;     //fnd com digit 1000
            default: o_fnd_com = 4'b1110;
        endcase
    end
endmodule


//for digits splitting
module digit_splitter (
    input   [13:0] counter,

    output  [ 3:0] digit_1,
    output  [ 3:0] digit_10,
    output  [ 3:0] digit_100,
    output  [ 3:0] digit_1000
);
    
    assign  digit_1     = counter % 10;
    assign  digit_10    = (counter / 10) % 10;
    assign  digit_100   = (counter / 100) % 10;
    assign  digit_1000  = (counter / 1000) % 10;

endmodule


//4X1 MUX for digits selecting
module mux_4X1 (
    input [1:0] sel,
    input [3:0] digit_1,
    input [3:0] digit_10,
    input [3:0] digit_100,
    input [3:0] digit_1000,

    output [3:0] bcd
);

    reg [3:0] o_bcd;

    assign bcd = o_bcd;

    always @(*) begin
        case (sel)
            2'b00: begin    //digit_1
                o_bcd = digit_1;
            end 

            2'b01: begin    //digit_10
                o_bcd = digit_10;
            end

            2'b10: begin    //digit_100
                o_bcd = digit_100;
            end

            2'b11: begin    //digit_1000
                o_bcd = digit_1000;
            end

            default: begin
                o_bcd = digit_1;
            end
        endcase
    end

endmodule

module bcd (
    input      [3:0] bcd,
    output reg [7:0] fnd_data
);

    always @(bcd) begin
        case (bcd)
            4'h0: fnd_data = 8'hc0;  // 0
            4'h1: fnd_data = 8'hf9;  // 1
            4'h2: fnd_data = 8'ha4;  // 2
            4'h3: fnd_data = 8'hb0;
            4'h4: fnd_data = 8'h99;
            4'h5: fnd_data = 8'h92;
            4'h6: fnd_data = 8'h82;
            4'h7: fnd_data = 8'hf8;
            4'h8: fnd_data = 8'h80;
            4'h9: fnd_data = 8'h90;  // 9
            4'ha: fnd_data = 8'h88;
            4'hb: fnd_data = 8'h83;
            4'hc: fnd_data = 8'hc6;
            4'hd: fnd_data = 8'ha1;
            4'he: fnd_data = 8'h7f;  // dot display
            4'hf: fnd_data = 8'hff;  // all off
            default: fnd_data = 8'hff;
        endcase
    end

endmodule