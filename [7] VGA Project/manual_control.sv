`timescale 1ns / 1ps
//=============================================================================
// manual_control — 수동 모드에서 버튼으로 좌표(0~319, 0~239) 이동
//=============================================================================
module manual_control (
    input  logic       clk,
    input  logic       reset,
    input  logic       vsync,
    input  logic       btn_left,
    input  logic       btn_right,
    input  logic       btn_up,
    input  logic       btn_down,
    output logic [8:0] manual_x,
    output logic [7:0] manual_y,
    output logic       manual_valid
);

    localparam DEBOUNCE_MAX = 20'd999_999;

    // ── 디바운싱 (4개 버튼) ──
    logic [19:0] cnt_L, cnt_R, cnt_U, cnt_D;
    logic s1_L, s2_L, st_L;
    logic s1_R, s2_R, st_R;
    logic s1_U, s2_U, st_U;
    logic s1_D, s2_D, st_D;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin s1_L<=0; s2_L<=0; cnt_L<=0; st_L<=0; end
        else begin s1_L<=btn_left; s2_L<=s1_L;
            if(s2_L!=st_L) begin if(cnt_L==DEBOUNCE_MAX) begin st_L<=s2_L; cnt_L<=0; end else cnt_L<=cnt_L+1; end else cnt_L<=0;
        end
    end
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin s1_R<=0; s2_R<=0; cnt_R<=0; st_R<=0; end
        else begin s1_R<=btn_right; s2_R<=s1_R;
            if(s2_R!=st_R) begin if(cnt_R==DEBOUNCE_MAX) begin st_R<=s2_R; cnt_R<=0; end else cnt_R<=cnt_R+1; end else cnt_R<=0;
        end
    end
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin s1_U<=0; s2_U<=0; cnt_U<=0; st_U<=0; end
        else begin s1_U<=btn_up; s2_U<=s1_U;
            if(s2_U!=st_U) begin if(cnt_U==DEBOUNCE_MAX) begin st_U<=s2_U; cnt_U<=0; end else cnt_U<=cnt_U+1; end else cnt_U<=0;
        end
    end
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin s1_D<=0; s2_D<=0; cnt_D<=0; st_D<=0; end
        else begin s1_D<=btn_down; s2_D<=s1_D;
            if(s2_D!=st_D) begin if(cnt_D==DEBOUNCE_MAX) begin st_D<=s2_D; cnt_D<=0; end else cnt_D<=cnt_D+1; end else cnt_D<=0;
        end
    end

    // ── VSYNC CDC ──
    logic vs1, vs2, vs3;
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin vs1<=0; vs2<=0; vs3<=0; end
        else begin vs1<=vsync; vs2<=vs1; vs3<=vs2; end
    end
    wire vsync_falling = !vs2 && vs3;

    // ── 좌표 이동 ──
    localparam [3:0] MOVE_SPEED = 4'd3;
    logic [8:0] mx;
    logic [7:0] my;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin mx <= 9'd160; my <= 8'd120; end
        else if (vsync_falling) begin
            if (st_L) mx <= (mx > {5'd0, MOVE_SPEED}) ? mx - {5'd0, MOVE_SPEED} : 9'd0;
            if (st_R) mx <= (mx < 9'd319 - {5'd0, MOVE_SPEED}) ? mx + {5'd0, MOVE_SPEED} : 9'd319;
            if (st_U) my <= (my > {4'd0, MOVE_SPEED}) ? my - {4'd0, MOVE_SPEED} : 8'd0;
            if (st_D) my <= (my < 8'd239 - {4'd0, MOVE_SPEED}) ? my + {4'd0, MOVE_SPEED} : 8'd239;
        end
    end

    assign manual_x = mx;
    assign manual_y = my;
    assign manual_valid = 1'b1;

endmodule