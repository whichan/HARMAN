`timescale 1ns / 1ps

// box_constraint: 박스 할당 제약 모듈
// 규칙 1: box1은 box0이 valid일 때만 valid
// 규칙 2: box0과 box1 중심점 거리 < MIN_DIST면 box1 무효

module box_constraint (
    input  logic [8:0] in_x_min [0:1],
    input  logic [8:0] in_x_max [0:1],
    input  logic [7:0] in_y_min [0:1],
    input  logic [7:0] in_y_max [0:1],
    input  logic       in_valid [0:1],

    output logic [8:0] out_x_min [0:1],
    output logic [8:0] out_x_max [0:1],
    output logic [7:0] out_y_min [0:1],
    output logic [7:0] out_y_max [0:1],
    output logic       out_valid [0:1]
);

    // 박스 범위 겹침 검사 (x, y 둘 다 겹쳐야 겹친 것)
    logic overlap;
    assign overlap = !(in_x_max[0] < in_x_min[1]) &&
                     !(in_x_min[0] > in_x_max[1]) &&
                     !(in_y_max[0] < in_y_min[1]) &&
                     !(in_y_min[0] > in_y_max[1]);

    // box0은 그대로 통과
    assign out_x_min[0] = in_x_min[0];
    assign out_x_max[0] = in_x_max[0];
    assign out_y_min[0] = in_y_min[0];
    assign out_y_max[0] = in_y_max[0];
    assign out_valid[0] = in_valid[0];

    // box1: box0 valid이고 겹치지 않을 때만 통과
    assign out_x_min[1] = in_x_min[1];
    assign out_x_max[1] = in_x_max[1];
    assign out_y_min[1] = in_y_min[1];
    assign out_y_max[1] = in_y_max[1];
    assign out_valid[1] = in_valid[1] && in_valid[0] && !overlap;

endmodule