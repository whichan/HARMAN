module vga_overlay (  //clk port
    input  logic                       clk,
    input  logic                       reset,
    input  logic [$clog2(320*240)-1:0] addr,
    input  logic [                9:0] x_pixel,
    input  logic [                9:0] y_pixel,
    input  logic [                9:0] obj_x_1,
    input  logic [                9:0] obj_y_1,
    input  logic                       out_valid_1,
    input  logic [                9:0] obj_x_2,
    input  logic [                9:0] obj_y_2,
    input  logic                       out_valid_2,
    input  logic [                9:0] obj_x_3,
    input  logic [                9:0] obj_y_3,
    input  logic                       out_valid_3,
    input  logic [                9:0] obj_x_4,
    input  logic [                9:0] obj_y_4,
    input  logic                       out_valid_4,
    input  logic [                9:0] obj_x_5,
    input  logic [                9:0] obj_y_5,
    input  logic                       out_valid_5,
    input  logic [                9:0] obj_x_6,
    input  logic [                9:0] obj_y_6,
    input  logic                       out_valid_6,
    output logic [               15:0] data
);
  localparam SPRITE_W = 64;
  localparam HALF = 32;

  logic [15:0] data_bg;
  // red
  logic signed [11:0] dx_1, dy_1;
  logic signed [11:0] sprite_x_1, sprite_y_1;
  logic sprite_valid_1;
  logic [15:0] data_fighter_1;
  logic [$clog2(64*64)-1:0] addr_fighter_1;

  assign dx_1 = $signed({2'b0, x_pixel}) - $signed({1'b0, obj_x_1, 1'b0});
  assign dy_1 = $signed({2'b0, y_pixel}) - $signed({1'b0, obj_y_1, 1'b0});
  assign sprite_x_1 = dx_1 + HALF;
  assign sprite_y_1 = dy_1 + HALF;
  assign sprite_valid_1 = (sprite_x_1 >= 0) &&(sprite_x_1 < SPRITE_W) && (sprite_y_1 >= 0) &&(sprite_y_1 < SPRITE_W);
  assign addr_fighter_1 = sprite_y_1[5:0] * SPRITE_W + sprite_x_1[5:0];

  logic signed [11:0] dx_2, dy_2;
  logic signed [11:0] sprite_x_2, sprite_y_2;
  logic sprite_valid_2;
  logic [15:0] data_fighter_2;
  logic [$clog2(64*64)-1:0] addr_fighter_2;

  assign dx_2 = $signed({2'b0, x_pixel}) - $signed({1'b0, obj_x_2, 1'b0});
  assign dy_2 = $signed({2'b0, y_pixel}) - $signed({1'b0, obj_y_2, 1'b0});
  assign sprite_x_2 = dx_2 + HALF;
  assign sprite_y_2 = dy_2 + HALF;
  assign sprite_valid_2 = (sprite_x_2 >= 0) &&(sprite_x_2 < SPRITE_W) && (sprite_y_2 >= 0) &&(sprite_y_2 < SPRITE_W);
  assign addr_fighter_2 = sprite_y_2[5:0] * SPRITE_W + sprite_x_2[5:0];

  // green
  logic signed [11:0] dx_3, dy_3;
  logic signed [11:0] sprite_x_3, sprite_y_3;
  logic sprite_valid_3;
  logic [15:0] data_fighter_3;
  logic [$clog2(64*64)-1:0] addr_fighter_3;

  assign dx_3 = $signed({2'b0, x_pixel}) - $signed({1'b0, obj_x_3, 1'b0});
  assign dy_3 = $signed({2'b0, y_pixel}) - $signed({1'b0, obj_y_3, 1'b0});
  assign sprite_x_3 = dx_3 + HALF;
  assign sprite_y_3 = dy_3 + HALF;
  assign sprite_valid_3 = (sprite_x_3 >= 0) &&(sprite_x_3 < SPRITE_W) && (sprite_y_3 >= 0) &&(sprite_y_3 < SPRITE_W);
  assign addr_fighter_3 = sprite_y_3[5:0] * SPRITE_W + sprite_x_3[5:0];

  logic signed [11:0] dx_4, dy_4;
  logic signed [11:0] sprite_x_4, sprite_y_4;
  logic sprite_valid_4;
  logic [15:0] data_fighter_4;
  logic [$clog2(64*64)-1:0] addr_fighter_4;

  assign dx_4 = $signed({2'b0, x_pixel}) - $signed({1'b0, obj_x_4, 1'b0});
  assign dy_4 = $signed({2'b0, y_pixel}) - $signed({1'b0, obj_y_4, 1'b0});
  assign sprite_x_4 = dx_4 + HALF;
  assign sprite_y_4 = dy_4 + HALF;
  assign sprite_valid_4 = (sprite_x_4 >= 0) &&(sprite_x_4 < SPRITE_W) && (sprite_y_4 >= 0) &&(sprite_y_4 < SPRITE_W);
  assign addr_fighter_4 = sprite_y_4[5:0] * SPRITE_W + sprite_x_4[5:0];

  // blue
  logic signed [11:0] dx_5, dy_5;
  logic signed [11:0] sprite_x_5, sprite_y_5;
  logic sprite_valid_5;
  logic [15:0] data_fighter_5;
  logic [$clog2(64*64)-1:0] addr_fighter_5;

  assign dx_5 = $signed({2'b0, x_pixel}) - $signed({1'b0, obj_x_5, 1'b0});
  assign dy_5 = $signed({2'b0, y_pixel}) - $signed({1'b0, obj_y_5, 1'b0});
  assign sprite_x_5 = dx_5 + HALF;
  assign sprite_y_5 = dy_5 + HALF;
  assign sprite_valid_5 = (sprite_x_5 >= 0) &&(sprite_x_5 < SPRITE_W) && (sprite_y_5 >= 0) &&(sprite_y_5 < SPRITE_W);
  assign addr_fighter_5 = sprite_y_5[5:0] * SPRITE_W + sprite_x_5[5:0];

  logic signed [11:0] dx_6, dy_6;
  logic signed [11:0] sprite_x_6, sprite_y_6;
  logic sprite_valid_6;
  logic [15:0] data_fighter_6;
  logic [$clog2(64*64)-1:0] addr_fighter_6;

  assign dx_6 = $signed({2'b0, x_pixel}) - $signed({1'b0, obj_x_6, 1'b0});
  assign dy_6 = $signed({2'b0, y_pixel}) - $signed({1'b0, obj_y_6, 1'b0});
  assign sprite_x_6 = dx_6 + HALF;
  assign sprite_y_6 = dy_6 + HALF;
  assign sprite_valid_6 = (sprite_x_6 >= 0) &&(sprite_x_6 < SPRITE_W) && (sprite_y_6 >= 0) &&(sprite_y_6 < SPRITE_W);
  assign addr_fighter_6 = sprite_y_6[5:0] * SPRITE_W + sprite_x_6[5:0];

  background U_BACK (
      .addr(addr),
      .data(data_bg)
  );

  red U_RED_1 (
      .clk (clk),
      .addr(addr_fighter_1),
      .data(data_fighter_1)
  );
  red U_RED_2 (
      .clk (clk),
      .addr(addr_fighter_2),
      .data(data_fighter_2)
  );

  green U_GREEN_1 (
      .clk (clk),
      .addr(addr_fighter_3),
      .data(data_fighter_3)
  );
  green U_GREEN_2 (
      .clk (clk),
      .addr(addr_fighter_4),
      .data(data_fighter_4)
  );

  blue U_BLUE_1 (
      .clk (clk),
      .addr(addr_fighter_5),
      .data(data_fighter_5)
  );
  blue U_BLUE_2 (
      .clk (clk),
      .addr(addr_fighter_6),
      .data(data_fighter_6)
  );

  logic ex_valid_1, ex_valid_2, ex_valid_3, ex_valid_4, ex_valid_5, ex_valid_6;

  valid U_VALID (
      .clk      (clk),
      .reset    (reset),
      .i_valid_1(out_valid_1),
      .i_valid_2(out_valid_2),
      .i_valid_3(out_valid_3),
      .i_valid_4(out_valid_4),
      .i_valid_5(out_valid_5),
      .i_valid_6(out_valid_6),
      .o_valid_1(ex_valid_1),
      .o_valid_2(ex_valid_2),
      .o_valid_3(ex_valid_3),
      .o_valid_4(ex_valid_4),
      .o_valid_5(ex_valid_5),
      .o_valid_6(ex_valid_6)
  );

  always_comb begin
    if (ex_valid_1 && sprite_valid_1 && (data_fighter_1 != 16'h0000)) begin
      data = data_fighter_1;
    end else if (ex_valid_2 && sprite_valid_2 && (data_fighter_2 != 16'h0000)) begin
      data = data_fighter_2;
    end else if (ex_valid_3 && sprite_valid_3 && (data_fighter_3 != 16'h0000)) begin
      data = data_fighter_3;
    end else if (ex_valid_4 && sprite_valid_4 && (data_fighter_4 != 16'h0000)) begin
      data = data_fighter_4;
    end else if (ex_valid_5 && sprite_valid_5 && (data_fighter_5 != 16'h0000)) begin
      data = data_fighter_5;
    end else if (ex_valid_6 && sprite_valid_6 && (data_fighter_6 != 16'h0000)) begin
      data = data_fighter_6;
    end else begin
      data = data_bg;
    end
  end
endmodule

module red (
    input  logic                     clk,
    input  logic [$clog2(64*64)-1:0] addr,
    output logic [             15:0] data
);
  logic [15:0] mem[0:64*64-1];
  initial begin
    $readmemh("red.mem", mem);
  end

  always_ff @(posedge clk) begin
    data <= mem[addr];
  end

  //   assign data = mem[addr];
endmodule

module green (
    input  logic                     clk,
    input  logic [$clog2(64*64)-1:0] addr,
    output logic [             15:0] data
);
  logic [15:0] mem[0:64*64-1];
  initial begin
    $readmemh("green.mem", mem);
  end

  always_ff @(posedge clk) begin
    data <= mem[addr];
  end

  //   assign data = mem[addr];
endmodule

module blue (
    input  logic                     clk,
    input  logic [$clog2(64*64)-1:0] addr,
    output logic [             15:0] data
);
  logic [15:0] mem[0:64*64-1];
  initial begin
    $readmemh("blue.mem", mem);
  end

  always_ff @(posedge clk) begin
    data <= mem[addr];
  end

  //   assign data = mem[addr];
endmodule

module background (
    input  logic [$clog2(320*240)-1:0] addr,
    output logic [               15:0] data
);
  logic [15:0] mem[0:320*240-1];
  initial begin
    $readmemh("background.mem", mem);
  end
  assign data = mem[addr];
endmodule


module valid_chain (
    input  logic clk,
    input  logic reset,
    input  logic valid_i,
    output logic valid_o
);
  logic [23:0] tick_count;
  logic tick;
  always_ff @(posedge clk) begin
    if (reset) begin
      tick_count <= 0;
      tick <= 1'b0;
    end else if (tick_count >= 10_000_000) begin  // 0.1초마다 1클럭 동안 high
      tick_count <= 0;
      tick <= 1'b1;
    end else begin
      tick_count <= tick_count + 1;
      tick <= 1'b0;
    end
  end
  // --- 2. 8단 시프트 레지스터 기반 신호 연장 ---
  logic [7:0] shift_reg;
  always_ff @(posedge clk) begin
    if (reset) begin
      shift_reg <= 8'b0;
    end else if (tick) begin
      // tick이 발생할 때마다 한 칸씩 밀어냄
      // 입력이 1이면 1이 계속 채워지고, 입력이 0이 되어도 8번의 tick 동안 1이 유지됨
      shift_reg <= {shift_reg[6:0], valid_i};
    end
  end
  // 시프트 레지스터 중 하나라도 1이면 유효한 것으로 간주 (OR 연산)
  assign valid_o = |shift_reg;
endmodule

module valid (
    input  logic clk,
    input  logic reset,
    input  logic i_valid_1,
    input  logic i_valid_2,
    input  logic i_valid_3,
    input  logic i_valid_4,
    input  logic i_valid_5,
    input  logic i_valid_6,
    output logic o_valid_1,
    output logic o_valid_2,
    output logic o_valid_3,
    output logic o_valid_4,
    output logic o_valid_5,
    output logic o_valid_6
);
  valid_chain U_VC1 (
      .clk(clk),
      .reset(reset),
      .valid_i(i_valid_1),
      .valid_o(o_valid_1)
  );
  valid_chain U_VC2 (
      .clk(clk),
      .reset(reset),
      .valid_i(i_valid_2),
      .valid_o(o_valid_2)
  );
  valid_chain U_VC3 (
      .clk(clk),
      .reset(reset),
      .valid_i(i_valid_3),
      .valid_o(o_valid_3)
  );
  valid_chain U_VC4 (
      .clk(clk),
      .reset(reset),
      .valid_i(i_valid_4),
      .valid_o(o_valid_4)
  );
  valid_chain U_VC5 (
      .clk(clk),
      .reset(reset),
      .valid_i(i_valid_5),
      .valid_o(o_valid_5)
  );
  valid_chain U_VC6 (
      .clk(clk),
      .reset(reset),
      .valid_i(i_valid_6),
      .valid_o(o_valid_6)
  );
endmodule
