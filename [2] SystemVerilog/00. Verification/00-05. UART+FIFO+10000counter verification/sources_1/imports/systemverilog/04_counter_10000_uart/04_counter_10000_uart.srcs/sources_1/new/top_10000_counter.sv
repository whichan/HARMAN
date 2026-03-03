`timescale 1ns / 1ps

module top_10000_counter(
    input clk,
    input reset,
    input clear,
    input mode,
    input run_stop,
    output [3:0] fnd_com,
    output [7:0] fnd_data,

    //외부 명령어로 값을 덮어쓰기 위한 포트 추가
    input [13:0] set_value,
    input set_en,

    //status용 추가
    output [13:0] current_count,
    output current_mode
    );

    wire [13:0] w_counter;

    assign current_count = w_counter;
    assign current_mode = mode;

    datapath_counter u_datapath_counter(
        .clk(clk),
        .reset(reset),
        .clear(clear),
        .run_stop(run_stop),
        .mode(mode),

        .set_value(set_value),
        .set_en(set_en),

        .counter(w_counter)
    );

    fnd_controller u_fnd_controller(
        .clk(clk),
        .reset(reset),
        .counter(w_counter),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data)
    );
    
endmodule

//Data Processing
module datapath_counter #(
    parameter SIM_MAX_COUNT = 10_000_000 //기본값(합성용)
    )(
    input clk,
    input reset,
    input clear,
    input run_stop,
    input mode,

    //추가
    input [13:0] set_value,
    input set_en,

    output [13:0] counter
);
    
    wire w_tick_10khz;

    clock_divider #(
        .MAX_COUNT(SIM_MAX_COUNT)
    ) u_clock_divider (
        .clk(clk),
        .reset(reset),
        .r_tick_10khz(w_tick_10khz)
    );

    counter_10000 u_counter_10000(
        .clk(clk),
        .reset(reset),
        .clear(clear),
        .run_stop(run_stop),
        .tick_10khz(w_tick_10khz),
        .mode(mode),

        .set_value(set_value),
        .set_en(set_en),

        .count(counter)
    );

endmodule