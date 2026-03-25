`timescale 1ns / 1ps

module top_VGA_OV7670 (
    input  logic       clk,
    input  logic       reset,
    //ov7670 side
    output logic       xclk,
    input  logic       pclk,
    input  logic       href,
    input  logic       vsync,
    input  logic [7:0] data,
    //vga port side
    output logic       v_sync,
    output logic       h_sync,
    output logic [3:0] port_red,
    output logic [3:0] port_green,
    output logic [3:0] port_blue,
    output logic       sioc,
    inout  logic       siod,
    //spi
    output logic       sclk,
    output logic       mosi,
    input  logic       miso,
    output logic       cs,
    //btn
    input  logic       btn_center,
    input  logic       btn_down,
    input  logic       btn_right,
    input  logic       btn_left,
    input  logic       btn_up,
    //switch
    input  logic       sw_img,
    input  logic       sw_mode
);
  localparam NUM_BOXES = 2;

  logic [                7:0] sccb_reg_addr;
  logic [                7:0] sccb_reg_data;
  logic                       sccb_start;
  logic                       sccb_busy;
  logic                       sccb_done;
  logic                       ov_reset;
  logic                       ov_pwdn;
  logic                       init_done;

  logic                       clk_100m;
  logic [                9:0] x_pixel;
  logic [                9:0] y_pixel;
  logic                       DE;  //display enable
  logic                       rclk;
  logic [$clog2(320*240)-1:0] rAddr;
  logic [               15:0] rData;
  logic                       we;
  logic [$clog2(320*240)-1:0] wAddr;
  logic [               15:0] wData;

  logic [                3:0] hsv_red;
  logic [                3:0] hsv_green;
  logic [                3:0] hsv_blue;

  logic                       is_red;
  logic                       is_green;
  logic                       is_blue;


  logic [                3:0] img_red;
  logic [                3:0] img_green;
  logic [                3:0] img_blue;

  logic [                8:0] center_red_x         [0:NUM_BOXES-1];
  logic [                7:0] center_red_y         [0:NUM_BOXES-1];
  logic [                8:0] center_green_x       [0:NUM_BOXES-1];
  logic [                7:0] center_green_y       [0:NUM_BOXES-1];
  logic [                8:0] center_blue_x        [0:NUM_BOXES-1];
  logic [                7:0] center_blue_y        [0:NUM_BOXES-1];

  // ── box_edge_img 출력 ─────────────────────────────────────────
  logic on_red_box0, on_grn_box0, on_blu_box0;
  logic on_red_box1, on_grn_box1, on_blu_box1;
  logic on_red_box, on_grn_box, on_blu_box;

  logic [                8:0] red_cst_x_max  [0:NUM_BOXES-1];
  logic [                8:0] red_cst_x_min  [0:NUM_BOXES-1];
  logic [                7:0] red_cst_y_max  [0:NUM_BOXES-1];
  logic [                7:0] red_cst_y_min  [0:NUM_BOXES-1];
  logic                       red_cst_valid  [0:NUM_BOXES-1];

  logic [                8:0] green_cst_x_max[0:NUM_BOXES-1];
  logic [                8:0] green_cst_x_min[0:NUM_BOXES-1];
  logic [                7:0] green_cst_y_max[0:NUM_BOXES-1];
  logic [                7:0] green_cst_y_min[0:NUM_BOXES-1];
  logic                       green_cst_valid[0:NUM_BOXES-1];

  logic [                8:0] blue_cst_x_max [0:NUM_BOXES-1];
  logic [                8:0] blue_cst_x_min [0:NUM_BOXES-1];
  logic [                7:0] blue_cst_y_max [0:NUM_BOXES-1];
  logic [                7:0] blue_cst_y_min [0:NUM_BOXES-1];
  logic                       blue_cst_valid [0:NUM_BOXES-1];







  logic [                8:0] spi_center_x;
  logic [                7:0] spi_center_y;
  logic                       spi_valid;

  //spi
  logic                       spi_start;
  logic [               15:0] spi_tx_data;
  logic [               15:0] spi_rx_data;
  logic                       spi_done;
  logic                       spi_tx_ready;

  logic [$clog2(320*240)-1:0] addr_up;
  logic [               15:0] data_up;
  logic [                3:0] red_img;
  logic [                3:0] green_img;
  logic [                3:0] blue_img;
  logic [                3:0] red_detect;
  logic [                3:0] green_detect;
  logic [                3:0] blue_detect;

  logic [                8:0] manual_x;
  logic [                7:0] manual_y;
  logic                       manual_valid;



  // clk
  // clk_out1__100MHz
  // clk_out2__25MHz
  clk_wiz_0 U_CLK_WIZ (
      // Clock out ports
      .clk_out1(clk_100m),  // output clk_out1
      .clk_out2(xclk),      // output clk_out2
      // Status and control signals
      .reset   (reset),     // input reset
      .locked  (locked),    // output locked
      // Clock in ports
      .clk_in1 (clk)
  );  // input clk_in1

  VGA_Decoder u_VGA_Decoder (
      .clk    (clk_100m),
      .reset  (reset),
      .pclk   (rclk),
      .h_sync (h_sync),
      .v_sync (v_sync),
      .x_pixel(x_pixel),
      .y_pixel(y_pixel),
      .DE     (DE)         //display enable
  );


  ImgMemReader #(
      .IMG_SIZE(320 * 240),
      .IMG_W(320),
      .IMG_H(240)
  ) U_ImgMemReader (
      .DE        (DE),
      .x_pixel   (x_pixel),
      .y_pixel   (y_pixel),
      .imgData   (rData),
      .addr      (rAddr),
      .port_red  (hsv_red),
      .port_green(hsv_green),
      .port_blue (hsv_blue)
  );


  Filter_top u_Filter_top (
      .DE          (DE),
      .rclk        (rclk),
      .reset       (reset),
      .x_pixel     (x_pixel),
      .y_pixel     (y_pixel),
      .hsv_red     (hsv_red),
      .hsv_green   (hsv_green),
      .hsv_blue    (hsv_blue),
      .is_red_out  (is_red),
      .is_green_out(is_green),
      .is_blue_out (is_blue)
  );

  Box_top #(
      .NUM_BOXES(2)
  ) u_Box_top (
      .DE               (DE),
      .is_red           (is_red),
      .is_green         (is_green),
      .is_blue          (is_blue),
      .rclk             (rclk),
      .reset            (reset),
      .vsync            (vsync),
      .x_pixel          (x_pixel),
      .y_pixel          (y_pixel),
      .on_blu_box0      (on_blu_box0),
      .on_blu_box1      (on_blu_box1),
      .on_grn_box0      (on_grn_box0),
      .on_grn_box1      (on_grn_box1),
      .on_red_box0      (on_red_box0),
      .on_red_box1      (on_red_box1),
      .o_red_cst_x_max  (red_cst_x_max),
      .o_red_cst_x_min  (red_cst_x_min),
      .o_red_cst_y_max  (red_cst_y_max),
      .o_red_cst_y_min  (red_cst_y_min),
      .o_red_cst_valid  (red_cst_valid),
      .o_green_cst_x_max(green_cst_x_max),
      .o_green_cst_x_min(green_cst_x_min),
      .o_green_cst_y_max(green_cst_y_max),
      .o_green_cst_y_min(green_cst_y_min),
      .o_green_cst_valid(green_cst_valid),
      .o_blue_cst_x_max (blue_cst_x_max),
      .o_blue_cst_x_min (blue_cst_x_min),
      .o_blue_cst_y_max (blue_cst_y_max),
      .o_blue_cst_y_min (blue_cst_y_min),
      .o_blue_cst_valid (blue_cst_valid)
  );
  // ── image_output ──────────────────────────────────────────────

  image_output u_image_output (
      .x_pixel    (x_pixel),
      .y_pixel    (y_pixel),
      .DE         (DE),
      .img_red    (hsv_red),
      .img_green  (hsv_green),
      .img_blue   (hsv_blue),
      .is_red     (is_red),
      .is_green   (is_green),
      .is_blue    (is_blue),
      // .on_red_box(on_red_box),
      // .on_grn_box(on_grn_box),
      // .on_blu_box(on_blu_box),
      .on_red_box0(on_red_box0),
      .on_red_box1(on_red_box1),
      .on_grn_box0(on_grn_box0),
      .on_grn_box1(on_grn_box1),
      .on_blu_box0(on_blu_box0),
      .on_blu_box1(on_blu_box1),
      .o_img_red  (red_detect),
      .o_img_green(green_detect),
      .o_img_blue (blue_detect)
  );


  FrameBuffer u_FrameBuffer (
      //write side
      .wclk (pclk),
      .we   (we),
      .wAddr(wAddr),
      .wData(wData),
      //read side
      .rclk (rclk),
      .rAddr(rAddr),
      .rData(rData)
  );

  OV7670_MemController u_OV7670_MemController (
      .pclk (pclk),
      .reset(reset),
      .href (href),
      .vsync(vsync),
      .data (data),
      .we   (we),
      .wAddr(wAddr),
      .wData(wData)
  );

  sccb_master #(
      .CLK_FREQ (100_000_000),
      .SCCB_FREQ(100_000)
  ) U_SCCB_MASTER (
      .clk     (clk_100m),
      .reset   (reset),
      .start   (sccb_start),
      .reg_addr(sccb_reg_addr),
      .reg_data(sccb_reg_data),
      .busy    (sccb_busy),
      .done    (sccb_done),
      .sioc    (sioc),
      .siod    (siod)
  );

  sccb_init_fsm U_SCCB_INIT (
      .clk          (clk_100m),
      .reset        (reset),
      .sccb_start   (sccb_start),
      .sccb_reg_addr(sccb_reg_addr),
      .sccb_reg_data(sccb_reg_data),
      .sccb_done    (sccb_done),
      .ov_reset     (ov_reset),
      .ov_pwdn      (ov_pwdn),
      .init_done    (init_done)
  );


  //   vga_overlay U_VGA_OVERLAY (
  //       .reset      (reset),
  //       .addr       (addr_up),
  //       .x_pixel    (x_pixel),
  //       .y_pixel    (y_pixel),
  //       .obj_x_1    (center_x[0]),
  //       .obj_y_1    (center_y[0]),
  //       .out_valid_1(red_cst_valid[0]),
  //       .obj_x_2    (center_x[1]),
  //       .obj_y_2    (center_y[1]),
  //       .out_valid_2(red_cst_valid[1]),
  //       .data       (data_up)
  //   );

  vga_overlay U_VGA_OVERLAY (  //clk port
      .clk        (clk_100m),
      .reset      (reset),
      .addr       (addr_up),
      .x_pixel    (x_pixel),
      .y_pixel    (y_pixel),
      //red1
      .obj_x_1    (center_red_x[0]),
      .obj_y_1    (center_red_y[0]),
      .out_valid_1(red_cst_valid[0]),
      //red2
      .obj_x_2    (center_red_x[1]),
      .obj_y_2    (center_red_y[1]),
      .out_valid_2(red_cst_valid[1]),
      //green1
      .obj_x_3    (center_green_x[0]),
      .obj_y_3    (center_green_x[0]),
      .out_valid_3(green_cst_valid[0]),
      //green2
      .obj_x_4    (center_green_x[1]),
      .obj_y_4    (center_green_y[1]),
      .out_valid_4(green_cst_valid[1]),
      //blue1
      .obj_x_5    (center_blue_x[0]),
      .obj_y_5    (center_blue_y[0]),
      .out_valid_5(blue_cst_valid[0]),
      //blue2
      .obj_x_6    (center_blue_x[1]),
      .obj_y_6    (center_blue_y[1]),
      .out_valid_6(blue_cst_valid[1]),
      //data
      .data       (data_up)
  );

  ImgMEMReader_overlay U_IMGMEMREADER_OVERLAY (
      .DE        (DE),
      .x_pixel   (x_pixel),
      .y_pixel   (y_pixel),
      .addr      (addr_up),
      .imgData   (data_up),
      .port_red  (red_img),
      .port_green(green_img),
      .port_blue (blue_img)
  );

  //   manual_control U_MANUAL_CONTROL (
  //       .clk       (clk_100m),
  //       .reset     (reset),
  //       .sw_mode   (sw_mode),
  //       .btn_left  (btn_left),
  //       .btn_right (btn_right),
  //       .btn_up    (btn_up),
  //       .btn_down  (btn_down),
  //       .btn_center(btn_center),
  //       .mode      (ctrl_mode),
  //       .left      (ctrl_left),
  //       .right     (ctrl_right),
  //       .up        (ctrl_up),
  //       .down      (ctrl_down),
  //       .fire      (ctrl_fire)
  //   );

  center U_RED_CENTER (
      .box_x_min(red_cst_x_min),
      .box_x_max(red_cst_x_max),
      .box_y_min(red_cst_y_min),
      .box_y_max(red_cst_y_max),
      .center_x (center_red_x),
      .center_y (center_red_y)
  );

  center U_GREEN_CENTER (
      .box_x_min(green_cst_x_min),
      .box_x_max(green_cst_x_max),
      .box_y_min(green_cst_y_min),
      .box_y_max(green_cst_y_max),
      .center_x (center_green_x),
      .center_y (center_green_y)
  );

  center U_BLUE_CENTER (
      .box_x_min(blue_cst_x_min),
      .box_x_max(blue_cst_x_max),
      .box_y_min(blue_cst_y_min),
      .box_y_max(blue_cst_y_max),
      .center_x (center_blue_x),
      .center_y (center_blue_y)
  );

  mux_for_spi #(
      .NUM_BOXES(2)
  ) U_MUX_FOR_SPI (
      .clk         (clk_100m),
      .reset       (reset),
      .sw_mode     (sw_mode),        // 1=자동, 0=수동
      .btn_center  (btn_center),     // 객체 전환 버튼
      .box_valid   (red_cst_valid),
      .center_x    (center_red_x),
      .center_y    (center_red_y),
      .manual_x    (manual_x),
      .manual_y    (manual_y),
      .manual_valid(manual_valid),
      .spi_center_x(spi_center_x),
      .spi_center_y(spi_center_y),
      .spi_valid   (spi_valid)
  );

  //   spi_send_fsm U_SPI_SEND_FSM (
  //       .clk         (clk_100m),
  //       .reset       (reset),
  //       .center_x    (center_x[0]),
  //       .center_y    (center_y[0]),
  //       .box_valid   (spi_valid),
  //       .vsync       (vsync),
  //       .mode        (ctrl_mode),
  //       .btn_left    (ctrl_left),
  //       .btn_right   (ctrl_right),
  //       .btn_up      (ctrl_up),
  //       .btn_down    (ctrl_down),
  //       .fire        (ctrl_fire),
  //       .spi_start   (spi_start),
  //       .spi_tx_data (spi_tx_data),
  //       .spi_done    (spi_done),
  //       .spi_tx_ready(spi_tx_ready)
  //   );

  spi_send_fsm U_SPI_SEND_FSM (
      .clk         (clk_100m),
      .reset       (reset),
      .center_x    (spi_center_x),  // ★ MUX 출력
      .center_y    (spi_center_y),  // ★ MUX 출력
      .box_valid   (spi_valid),     // ★ MUX 출력
      .vsync       (vsync),
      .spi_start   (spi_start),
      .spi_tx_data (spi_tx_data),
      .spi_done    (spi_done),
      .spi_tx_ready(spi_tx_ready)
  );

  spi_master U_SPI_MASTER (
      .clk     (clk_100m),
      .reset   (reset),
      .start   (spi_start),
      .tx_data (spi_tx_data),
      .tx_ready(spi_tx_ready),
      .rx_data (spi_rx_data),
      .done    (spi_done),
      .sclk    (sclk),
      .mosi    (mosi),
      .miso    (miso),
      .cs      (cs)
  );

  manual_control U_MANUAL_CONTROL (
      .clk         (clk_100m),
      .reset       (reset),
      .vsync       (vsync),
      .btn_left    (btn_left),
      .btn_right   (btn_right),
      .btn_up      (btn_up),
      .btn_down    (btn_down),
      .manual_x    (manual_x),
      .manual_y    (manual_y),
      .manual_valid(manual_valid)
  );

  mux_rgb U_MUX_RGB (
      .sw        (sw_img),
      .red1      (red_detect),
      .red2      (red_img),
      .green1    (green_detect),
      .green2    (green_img),
      .blue1     (blue_detect),
      .blue2     (blue_img),
      .port_red  (port_red),
      .port_green(port_green),
      .port_blue (port_blue)
  );

endmodule

module center #(
    parameter NUM_BOXES = 2
) (
    input  logic [8:0] box_x_min[0:NUM_BOXES-1],
    input  logic [8:0] box_x_max[0:NUM_BOXES-1],
    input  logic [7:0] box_y_min[0:NUM_BOXES-1],
    input  logic [7:0] box_y_max[0:NUM_BOXES-1],
    output logic [8:0] center_x [0:NUM_BOXES-1],
    output logic [7:0] center_y [0:NUM_BOXES-1]
);


  logic [9:0] cx_sum[0:NUM_BOXES-1];
  logic [8:0] cy_sum[0:NUM_BOXES-1];
  always_comb begin
    cx_sum[0]   = {1'b0, box_x_min[0]} + {1'b0, box_x_max[0]};
    cx_sum[1]   = {1'b0, box_x_min[1]} + {1'b0, box_x_max[1]};
    cy_sum[0]   = {1'b0, box_y_min[0]} + {1'b0, box_y_max[0]};
    cy_sum[1]   = {1'b0, box_y_min[1]} + {1'b0, box_y_max[1]};
    center_x[0] = cx_sum[0][9:1];
    center_x[1] = cx_sum[1][9:1];
    center_y[0] = cy_sum[0][8:1];
    center_y[1] = cy_sum[1][8:1];
  end

endmodule

`timescale 1ns / 1ps
//=============================================================================
// mux_for_spi — 모드에 따라 SPI로 보낼 좌표를 선택
//
// sw_mode=1 (자동): ColorDetector의 center_x/y[sel] 선택
//   btn_center 누를 때마다 sel이 0↔1 토글 (객체 전환)
//
// sw_mode=0 (수동): manual_control의 manual_x/y 선택
//=============================================================================
module mux_for_spi #(
    parameter NUM_BOXES = 2
) (
    input logic clk,
    input logic reset,

    // 모드 스위치
    input logic sw_mode,  // 1=자동, 0=수동

    // 객체 전환 버튼 (raw)
    input logic btn_center,

    // 자동 모드 입력 (ColorDetector 출력)
    input logic       box_valid[0:NUM_BOXES-1],
    input logic [8:0] center_x [0:NUM_BOXES-1],
    input logic [7:0] center_y [0:NUM_BOXES-1],

    // 수동 모드 입력 (manual_control 출력)
    input logic [8:0] manual_x,
    input logic [7:0] manual_y,
    input logic       manual_valid,

    // SPI로 보낼 최종 좌표
    output logic [8:0] spi_center_x,
    output logic [7:0] spi_center_y,
    output logic       spi_valid
);

  // ── btn_center 디바운싱 + 엣지 검출 ──
  localparam DEBOUNCE_MAX = 20'd999_999;
  logic [19:0] cnt_C;
  logic s1_C, s2_C, st_C, st_C_prev;

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      s1_C  <= 0;
      s2_C  <= 0;
      cnt_C <= 0;
      st_C  <= 0;
    end else begin
      s1_C <= btn_center;
      s2_C <= s1_C;
      if (s2_C != st_C) begin
        if (cnt_C == DEBOUNCE_MAX) begin
          st_C  <= s2_C;
          cnt_C <= 0;
        end else cnt_C <= cnt_C + 1;
      end else cnt_C <= 0;
    end
  end

  // 엣지 검출 (rising = 버튼 눌림)
  always_ff @(posedge clk or posedge reset) begin
    if (reset) st_C_prev <= 0;
    else st_C_prev <= st_C;
  end
  wire  btn_center_pressed = st_C && !st_C_prev;

  // ── 객체 선택 토글 (자동 모드용) ──
  logic sel;  // 0 = 객체0, 1 = 객체1

  always_ff @(posedge clk or posedge reset) begin
    if (reset) sel <= 0;
    else if (btn_center_pressed) sel <= ~sel;
  end

  // ── MUX ──
  always_comb begin
    if (sw_mode) begin
      // 자동 모드: 선택된 객체의 좌표
      spi_center_x = center_x[sel];
      spi_center_y = center_y[sel];
      spi_valid    = box_valid[sel];
    end else begin
      // 수동 모드: manual_control 좌표
      spi_center_x = manual_x;
      spi_center_y = manual_y;
      spi_valid    = manual_valid;
    end
  end

endmodule

module mux_rgb (
    input  logic       sw,
    input  logic [3:0] red1,
    input  logic [3:0] red2,
    input  logic [3:0] green1,
    input  logic [3:0] green2,
    input  logic [3:0] blue1,
    input  logic [3:0] blue2,
    output logic [3:0] port_red,
    output logic [3:0] port_green,
    output logic [3:0] port_blue
);
  assign port_red   = sw ? red1 : red2;
  assign port_green = sw ? green1 : green2;
  assign port_blue  = sw ? blue1 : blue2;

endmodule
