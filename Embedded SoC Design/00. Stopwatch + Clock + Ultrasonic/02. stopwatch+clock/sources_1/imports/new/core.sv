`timescale 1ns / 1ps

module clock_core (
    input  logic       clk,
    input  logic       reset,
    output logic [6:0] msec,
    output logic [5:0] sec,
    output logic [5:0] min,
    output logic [5:0] hour
);

    logic tick_100hz, ms_tick, sec_tick, min_tick;

    clk_div_100hz U_ClkDiv_100Hz (
        .clk  (clk),
        .reset(reset),
        .o_clk(tick_100hz)
    );

    time_counter #(
        .MAX_COUNT(100),
        .WIDTH(7)
    ) U_MSEC (
        .clk   (clk),
        .reset (reset),
        .i_tick(tick_100hz),
        .q     (msec),
        .o_tick(ms_tick)
    );

    time_counter #(
        .MAX_COUNT(60),
        .WIDTH(6)
    ) U_SEC (
        .clk   (clk),
        .reset (reset),
        .i_tick(ms_tick),
        .q     (sec),
        .o_tick(sec_tick)
    );

    time_counter #(
        .MAX_COUNT(60),
        .WIDTH(6)
    ) U_MIN (
        .clk   (clk),
        .reset (reset),
        .i_tick(sec_tick),
        .q     (min),
        .o_tick(min_tick)
    );

    time_counter #(
        .MAX_COUNT(24),
        .WIDTH(6)
    ) U_HOUR (
        .clk   (clk),
        .reset (reset),
        .i_tick(min_tick),
        .q     (hour),
        .o_tick()
    );

endmodule

module time_counter #(
    parameter MAX_COUNT = 60,
    parameter WIDTH = 6
) (
    input  logic               clk,
    input  logic               reset,
    input  logic               i_tick,
    output logic [WIDTH - 1:0] q,
    output logic               o_tick
);
    assign o_tick = (q == MAX_COUNT - 1) && i_tick;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            q <= 0;
        end else begin
            if (i_tick) begin
                if (q == MAX_COUNT - 1) begin
                    q <= 0;
                end else begin
                    q <= q + 1;
                end
            end
        end
    end
endmodule

module clk_div_100hz (
    input  logic clk,
    input  logic reset,
    output logic o_clk
);
    logic [$clog2(1_000_000)-1 : 0] div_counter;

    assign o_clk = (div_counter == 1_000_000 - 1);
    //assign o_clk = (div_counter == 100 - 1);

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            div_counter <= 0;
        end else begin
            if (div_counter == 1_000_000 - 1) begin
            //if (div_counter == 100 - 1) begin
                div_counter <= 0;
            end else begin
                div_counter <= div_counter + 1;
            end
        end
    end
endmodule