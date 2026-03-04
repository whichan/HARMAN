`timescale 1ns / 1ps

module gray_scale_filter (
    input  logic [11:0] i_rgb,
    output logic [11:0] o_rgb
);

  logic [11:0] gray;

  assign gray  = 51 * i_rgb[11:8] + 179 * i_rgb[7:4] + 26 * i_rgb[3:0];
  assign o_rgb = {gray[11:8], gray[11:8], gray[11:8]};

endmodule


module red_filter (
    input  logic [11:0] i_rgb,
    output logic [11:0] o_rgb
);


  assign o_rgb = {i_rgb[11:8], 4'b0, 4'b0};

endmodule

module green_filter (
    input  logic [11:0] i_rgb,
    output logic [11:0] o_rgb
);


  assign o_rgb = {4'b0, i_rgb[7:4], 4'b0};

endmodule

module blue_filter (
    input  logic [11:0] i_rgb,
    output logic [11:0] o_rgb
);

  assign o_rgb = {4'b0, 4'b0, i_rgb[3:0]};
endmodule

module negative_filter (
    input  logic [11:0] i_rgb,
    output logic [11:0] o_rgb
);

  assign o_rgb = {~i_rgb[11:8], ~i_rgb[7:4], ~i_rgb[3:0]};
endmodule
