`timescale 1ns / 1ps

module stopwatch_core(
    input              clk, 
    input              reset,
    input              run,
    input              clear,
    output logic [6:0] msec,
    output logic [5:0] sec,
    output logic [5:0] min,
    output logic [5:0] hour
    );

    logic tick_100hz, ms_tick, sec_tick, min_tick, hour_tick;

    clock_div_100hz U_ClkDiv_100Hz(
        .clk(clk),
        .reset(reset),
        .en(run),
        .clear(clear),
        .o_clk(tick_100hz)
    );

    counter #(
        .MAX_COUNT(100),
        .WIDTH(7)
    )U_MSEC(
        .clk(clk),
        .reset(reset),
        .clear(clear),
        .i_tick(tick_100hz),
        .o_tick(ms_tick),
        .count(msec)
    );

    counter #(
        .MAX_COUNT(60),
        .WIDTH(6)
    )U_SEC(
        .clk(clk),
        .reset(reset),
        .clear(clear),
        .i_tick(ms_tick),
        .o_tick(sec_tick),
        .count(sec)
    );

    counter #(
        .MAX_COUNT(60),
        .WIDTH(6)
    )U_MIN(
        .clk(clk),
        .reset(reset),
        .clear(clear),
        .i_tick(sec_tick),
        .o_tick(min_tick),
        .count(min)
    );

    counter #(
        .MAX_COUNT(24),
        .WIDTH(6)
    )U_HOUR(
        .clk(clk),
        .reset(reset),
        .clear(clear),
        .i_tick(min_tick),
        .o_tick(hour_tick),
        .count(hour)
    );

    
endmodule


module clock_div_100hz(
    input        clk,
    input        reset,
    input        en,
    input        clear,
    output logic o_clk
);
    
    logic [$clog2(1_000_000)-1:0] div_counter;


    always_ff @( posedge clk or posedge reset ) begin
        if(reset) begin
            div_counter <= 0;
            o_clk <= 0;
        end else begin
            if(clear) begin
                div_counter <= 0;
                o_clk <= 0;
            end else begin
                if(en) begin
                    if(div_counter == 1_000_000-1) begin
                        div_counter <= 1'b0;
                        o_clk <= 1'b1;
                    end else begin
                        div_counter <= div_counter + 1;
                        o_clk <= 1'b0;
                    end
                end else begin
                    o_clk <= 1'b0;
                end
            end
        end
    end
endmodule

module counter #(
    parameter MAX_COUNT = 60,
    parameter WIDTH = 6
)(
    input  logic             clk,
    input  logic             reset,
    input  logic             clear,
    input  logic             i_tick,
    output logic             o_tick,
    output logic [WIDTH-1:0] count
);

    
    always_ff @( posedge clk or posedge reset ) begin
        if(reset) begin
            count <= 1'b0;
            o_tick <= 1'b0;
        end else begin
            if(clear) begin
                count <= 1'b0;
                o_tick <= 1'b0;
            end else begin
                if(i_tick) begin
                    if(count == MAX_COUNT -1) begin
                        count <= 1'b0;
                        o_tick <= 1'b1;
                    end else begin
                        count <= count + 1;
                        o_tick <= 1'b0;
                    end
                end else begin
                    o_tick <= 1'b0;
                end
            end
        end
    end
endmodule
