`timescale 1ns / 1ps

module UART_Periph (
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
    // External Signals 
    input  logic        RsRx,
    output logic        RsTx
);

  logic wr, full, rd, empty;
  logic [7:0] wdata, rdata;


  UART_TOP U_UART_TOP (
      .clk(PCLK),
      .reset(PRESET),
      .RsTx(RsTx),
      .RsRx(RsRx),
      .wdata(wdata),
      .wr(wr),
      .full(full),
      .rdata(rdata),
      .rd(rd),
      .empty(empty)
  );

  APB_SlaveIntrf_UART U_APB_SLAVEIntrf_UART (
      .*,
      .wdata(wdata),
      .wr(wr),
      .full(full),
      .rdata(rdata),
      .rd(rd),
      .empty(empty)
  );

  module APB_SlaveIntrf_UART (
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
      //fifo tx
      output logic [ 7:0] wdata,
      output logic        wr,
      input  logic        full,
      //fiforx
      input        [ 7:0] rdata,
      output              rd,
      input               empty

  );

    logic [31:0] cr, odr, idr;  //CR1, CR2, CR3, ODR, IDR

    assign wdata = odr[7:0];  //이거좀걸림

    assign wr = (PSEL && PENABLE && PWRITE && (PADDR[3:2] == 2'd1)) && !full;
    assign rd = (PSEL && PENABLE && !PWRITE && (PADDR[3:2] == 2'd2)) && !empty;

    //   assign PREADY = 1'b1;

    always_ff @(posedge PCLK, posedge PRESET) begin
      if (PRESET) begin
        cr <= 0;
        odr <= 0;
        idr <= 0;
        PRDATA <= 0;
      end else begin
        PREADY <= 1'b0;
        if (PSEL & PENABLE) begin
          PREADY <= 1'b1;
          if (PWRITE) begin
            case (PADDR[3:2])
              2'd0: cr <= PWDATA;
              2'd1: odr <= PWDATA;
              2'd2: idr <= PWDATA;
            endcase
          end else begin
            //쓰지 않을 때
            case (PADDR[3:2])
              2'd0: PRDATA <= {30'b0, empty, full};
              2'd1: PRDATA <= odr;
              2'd2: PRDATA <= {24'b0, rdata};
            endcase
          end
        end
      end
    end
  endmodule

endmodule
