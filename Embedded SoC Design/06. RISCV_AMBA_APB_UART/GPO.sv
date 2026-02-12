`timescale 1ns / 1ps

module GPO_Periph (
    // global signals
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [31:0] PADDR,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic [31:0] PWDATA,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    //External Signals
    output logic [ 3:0] gpo
);


  logic [3:0] moder;
  logic [3:0] odr;

  GPO U_GPO (.*);


  APB_SlaveIntrf_GPO U_APB_SlaveIntrf_GPO (.*);

endmodule

module GPO (

    input  logic [3:0] moder,
    input  logic [3:0] odr,
    output logic [3:0] gpo

);
  genvar i;

  generate
    for (i = 0; i < 4; i++) begin
      assign gpo[i] = moder[i] == 1 ? odr[i] : 1'bz;
    end
  endgenerate



  //assign gpo[0] = moder[0] == 1 ? odr[0] : 1'bz;
  //assign gpo[1] = moder[1] == 1 ? odr[1] : 1'bz;
  //assign gpo[2] = moder[2] == 1 ? odr[2] : 1'bz;
  //assign gpo[3] = moder[3] == 1 ? odr[3] : 1'bz;



endmodule


module APB_SlaveIntrf_GPO (
    // global signals
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [31:0] PADDR,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic [31:0] PWDATA,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    // Intrernal Signals
    output logic [ 3:0] moder,
    output logic [ 3:0] odr
);
  logic [31:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3;

  assign moder = slv_reg0[3:0];
  assign odr   = slv_reg2[3:0];

  always_ff @(posedge PCLK, posedge PRESET) begin
    if (PRESET) begin
      slv_reg0 <= 0;
      slv_reg1 <= 0;
      slv_reg2 <= 0;
      slv_reg3 <= 0;
    end else begin
      PREADY <= 1'b0;
      if (PSEL & PENABLE) begin
        PREADY <= 1'b1;
        if (PWRITE) begin
          case (PADDR[3:2])
            2'd0: slv_reg0 <= PWDATA;
            2'd1: slv_reg1 <= PWDATA;
            2'd2: slv_reg2 <= PWDATA;
            2'd3: slv_reg3 <= PWDATA;
          endcase
        end else begin
          case (PADDR[3:2])
            2'd0: PRDATA <= slv_reg0;
            2'd1: PRDATA <= slv_reg1;
            2'd2: PRDATA <= slv_reg2;
            2'd3: PRDATA <= slv_reg3;
          endcase
        end
      end
    end
  end
endmodule
