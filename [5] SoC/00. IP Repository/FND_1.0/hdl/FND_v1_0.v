
`timescale 1 ns / 1 ps

module FND_v1_0 #(
    // Users to add parameters here

    // User parameters ends
    // Do not modify the parameters beyond this line


    // Parameters of Axi Slave Bus Interface S00_AXI
    parameter integer C_S00_AXI_DATA_WIDTH = 32,
    parameter integer C_S00_AXI_ADDR_WIDTH = 5
) (
    // Users to add ports here
    // input  [5:0] sec,
    // input  [5:0] min,
    output [3:0] fnd_com,
    output [7:0] fnd_font,
    // User ports ends
    // Do not modify the ports beyond this line


    // Ports of Axi Slave Bus Interface S00_AXI
    input  wire                                  s00_axi_aclk,
    input  wire                                  s00_axi_aresetn,
    input  wire [    C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
    input  wire [                         2 : 0] s00_axi_awprot,
    input  wire                                  s00_axi_awvalid,
    output wire                                  s00_axi_awready,
    input  wire [    C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
    input  wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
    input  wire                                  s00_axi_wvalid,
    output wire                                  s00_axi_wready,
    output wire [                         1 : 0] s00_axi_bresp,
    output wire                                  s00_axi_bvalid,
    input  wire                                  s00_axi_bready,
    input  wire [    C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
    input  wire [                         2 : 0] s00_axi_arprot,
    input  wire                                  s00_axi_arvalid,
    output wire                                  s00_axi_arready,
    output wire [    C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
    output wire [                         1 : 0] s00_axi_rresp,
    output wire                                  s00_axi_rvalid,
    input  wire                                  s00_axi_rready
);

  wire [31:0] cr;
  wire [31:0] com;
  wire [31:0] seg1, seg2, seg3, seg4;

  // Instantiation of Axi Bus Interface S00_AXI
  FND_v1_0_S00_AXI #(
      .C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
      .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
  ) FND_v1_0_S00_AXI_inst (

      .cr           (cr),
      .com          (com[3:0]),
      .seg1         (seg1[7:0]),
      .seg2         (seg2[7:0]),
      .seg3         (seg3[7:0]),
      .seg4         (seg4[7:0]),
      .S_AXI_ACLK   (s00_axi_aclk),
      .S_AXI_ARESETN(s00_axi_aresetn),
      .S_AXI_AWADDR (s00_axi_awaddr),
      .S_AXI_AWPROT (s00_axi_awprot),
      .S_AXI_AWVALID(s00_axi_awvalid),
      .S_AXI_AWREADY(s00_axi_awready),
      .S_AXI_WDATA  (s00_axi_wdata),
      .S_AXI_WSTRB  (s00_axi_wstrb),
      .S_AXI_WVALID (s00_axi_wvalid),
      .S_AXI_WREADY (s00_axi_wready),
      .S_AXI_BRESP  (s00_axi_bresp),
      .S_AXI_BVALID (s00_axi_bvalid),
      .S_AXI_BREADY (s00_axi_bready),
      .S_AXI_ARADDR (s00_axi_araddr),
      .S_AXI_ARPROT (s00_axi_arprot),
      .S_AXI_ARVALID(s00_axi_arvalid),
      .S_AXI_ARREADY(s00_axi_arready),
      .S_AXI_RDATA  (s00_axi_rdata),
      .S_AXI_RRESP  (s00_axi_rresp),
      .S_AXI_RVALID (s00_axi_rvalid),
      .S_AXI_RREADY (s00_axi_rready)
  );

  // Add user logic here
  fndController U_FND (
      //   .clk     (s00_axi_aclk),
      //   .reset   (s00_axi_aresetn),
      .cr      (cr),
      .com     (com[3:0]),
      .seg1    (seg1[7:0]),
      .seg2    (seg2[7:0]),
      .seg3    (seg3[7:0]),
      .seg4    (seg4[7:0]),
      .fnd_com (fnd_com),
      .fnd_font(fnd_font)
  );
  // User logic ends

endmodule

module fndController (
    // input         clk,
    // input         reset,
    input  [31:0] cr,
    input  [3:0] com,
    input  [7:0] seg1,
    input  [7:0] seg2,
    input  [7:0] seg3,
    input  [7:0] seg4,
    output [3:0] fnd_com,
    output [7:0] fnd_font
);
  wire [7:0] bcd;
  assign fnd_com = com;

  mux_4x1 U_MUX_4x1 (
      .sel(com),
      .x0 (seg1),
      .x1 (seg2),
      .x2 (seg3),
      .x3 (seg4),
      .y  (bcd)
  );

  BCDtoSEG_decoder U_BCD2SEG (
      .bcd(bcd[3:0]),
      .seg(fnd_font)
  );
endmodule

module mux_4x1 (
    input      [3:0] sel,
    input      [7:0] x0,
    input      [7:0] x1,
    input      [7:0] x2,
    input      [7:0] x3,
    output reg [7:0] y
);
  always @(*) begin
    y = 8'h07;
    case (sel)
      4'b1110: y = x0;
      4'b1101: y = x1;
      4'b1011: y = x2;
      4'b0111: y = x3;
    endcase
  end
endmodule

module BCDtoSEG_decoder (
    input      [3:0] bcd,
    output reg [7:0] seg
);
  always @(bcd) begin
    seg = 8'hff;
    case (bcd)
      4'h0: seg = 8'hc0;
      4'h1: seg = 8'hf9;
      4'h2: seg = 8'ha4;
      4'h3: seg = 8'hb0;
      4'h4: seg = 8'h99;
      4'h5: seg = 8'h92;
      4'h6: seg = 8'h82;
      4'h7: seg = 8'hf8;
      4'h8: seg = 8'h80;
      4'h9: seg = 8'h90;
      4'ha: seg = 8'h88;
      4'hb: seg = 8'h83;
      4'hc: seg = 8'hc6;
      4'hd: seg = 8'ha1;
      4'he: seg = 8'h86;
      4'hf: seg = 8'h8e;
      default: seg = 8'hff;
    endcase
  end
endmodule
