`timescale 1ns / 1ps

module top(
    input        clk,
    input        reset,
    input        mode,
    input        run_stop,
    input        clear,
    input        mode_sw,
    output [3:0] fnd_com,
    output [7:0] fnd_font,
    output       led1,
    output       led2
    );

    logic w_debounced_mode, w_debounced_run_stop, w_debounced_clear;
    logic [6:0] w_msec;
    logic [5:0] w_sec, w_min, w_hour;

    btn_debounce U_Debounced_Mode(
        .clk(clk),
        .reset(reset),
        .i_btn(mode),
        .o_btn(w_debounced_mode)
    );

    btn_debounce U_Debounced_Run_Stop(
        .clk(clk),
        .reset(reset),
        .i_btn(run_stop),
        .o_btn(w_debounced_run_stop)
    );

    btn_debounce U_Debounced_Clear(
        .clk(clk),
        .reset(reset),
        .i_btn(clear),
        .o_btn(w_debounced_clear)
    );

    core U_Core(
        .clk(clk),
        .reset(reset),
        .mode(w_debounced_mode),
        .run_stop(w_debounced_run_stop),
        .clear(w_debounced_clear),
        .o_msec(w_msec),
        .o_sec(w_sec),
        .o_min(w_min),
        .o_hour(w_hour),
        .led1(led1), 
        .led2(led2)
    );

    fndController FND_CONTROLLER(
        .clk(clk),
        .reset(reset),
        .mode_sw(mode_sw),
        .msec(w_msec),
        .sec(w_sec),
        .min(w_min),
        .hour(w_hour),
        .fnd_com(fnd_com),
        .fnd_font(fnd_font)
    );
endmodule

module btn_debounce(
    input  clk,
    input  reset,
    input  i_btn,
    output o_btn
    );

    //clk_divider
    //100MHz -> 100kHz
    parameter FCOUNT = 100_000_000/100_000;
    logic [$clog2(FCOUNT)-1:0] counter_100khz;
    logic r_clock_100khz;

    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            counter_100khz <= 0;
            r_clock_100khz <= 1'b0;
        end else begin
            if(counter_100khz == FCOUNT -1) begin
                counter_100khz <= 0;
                r_clock_100khz <= 1'b1;
            end else begin
                counter_100khz <= counter_100khz + 1;
                r_clock_100khz <= 1'b0;
            end
        end
    end

    // debounce 8FF - 8input And Gate
    logic [7:0] shift_reg; //verilog에서는 reg
                           //systemverilog에서는 reg을 logic이라 함
    
    logic debounce;

    //8 SIPO(serial input parallel output) shift register
    always_ff @(posedge r_clock_100khz or posedge reset) begin
        if(reset) begin
            shift_reg <= 8'h00;
        end else begin
            shift_reg <= {i_btn, shift_reg[7:1]};
        end
    end

    // 8input AND Gate
    assign debounce = &(shift_reg);
    

    logic edge_detect;

    // Rising Edge Detector
    always_ff @( posedge clk or posedge reset ) begin
        if(reset) begin
            edge_detect <= 1'b0;
        end else begin
            edge_detect <= debounce;
        end
    end

    assign o_btn = debounce & (~edge_detect);
    //reset은 민감하기 때문에 8개까지 동기화를 해주자
endmodule
