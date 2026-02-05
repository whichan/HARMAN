`timescale 1ns / 1ps

module MCU (
    input logic clk,
    input logic reset
);
  //  ROM signals
  logic [31:0] instrMemAddr;
  logic [31:0] instrCode;
  logic        PCLK;
  logic        PRESET;
  // APB Interface Signals
  logic [31:0] PADDR;
  logic        PWRITE;
  logic        PENABLE;
  logic [31:0] PWDATA;
  logic        PSEL_RAM;
  logic        PSEL_SLAVE1;
  logic        PSEL_SLAVE2;
  logic        PSEL_SLAVE3;
  logic [31:0] PRDATA_RAM;
  logic [31:0] PRDATA_SLAVE1;
  logic [31:0] PRDATA_SLAVE2;
  logic [31:0] PRDATA_SLAVE3;
  logic        PREADY_RAM;
  logic        PREADY_SLAVE1;
  logic        PREADY_SLAVE2;
  logic        PREADY_SLAVE3;
  // Internal Interface Signals
  logic        transfer;
  logic        ready;
  logic        write;
  logic [31:0] addr;
  logic [31:0] wdata;
  logic [31:0] rdata;

  assign PCLK   = clk;
  assign PRESET = reset;

  ROM U_ROM (
      .addr(instrMemAddr),
      .data(instrCode)
  );

  CPU_RV32I U_RV32I_CORE (
      .clk         (clk),
      .reset       (reset),
      .instrCode   (instrCode),
      .instrMemAddr(instrMemAddr),
      .busWe       (write),
      .busAddr     (addr),
      .busWData    (wdata),
      .busRData    (rdata),
      .transfer    (transfer),
      .ready       (ready)
  );

  APB_Master U_APB_MASTER (
      .*,
      // APB Interface Signals
      .PSEL0  (PSEL_RAM),
      .PSEL1  (PSEL_SLAVE1),
      .PSEL2  (PSEL_SLAVE2),
      .PSEL3  (PSEL_SLAVE3),
      .PRDATA0(PRDATA_RAM),
      .PRDATA1(PRDATA_SLAVE1),
      .PRDATA2(PRDATA_SLAVE2),
      .PRDATA3(PRDATA_SLAVE3),
      .PREADY0(PREADY_RAM),
      .PREADY1(PREADY_SLAVE1),
      .PREADY2(PREADY_SLAVE2),
      .PREADY3(PREADY_SLAVE3)
      // Internal Interface Signals

  );

  APB_RAM U_APB_RAM (
      .*,
      .PSEL  (PSEL_RAM),
      .PRDATA(PRDATA_RAM),
      .PREADY(PREADY_RAM)
  );

  APB_Slave U_APB_Slave1 (
      // global signals
      .*,
      .PSEL  (PSEL_SLAVE1),
      .PRDATA(PRDATA_SLAVE1),
      .PREADY(PREADY_SLAVE1)
  );

  APB_Slave U_APB_Slave2 (
      // global signals
      .*,
      .PSEL  (PSEL_SLAVE2),
      .PRDATA(PRDATA_SLAVE2),
      .PREADY(PREADY_SLAVE2)
  );

  APB_Slave U_APB_Slave3 (
      // global signals
      .*,
      .PSEL  (PSEL_SLAVE3),
      .PRDATA(PRDATA_SLAVE3),
      .PREADY(PREADY_SLAVE3)
  );

  // RAM U_RAM (
  //     .clk  (clk),
  //     .we   (busWe),
  //     .addr (busAddr[9:0]),
  //     .wdata(busWData),
  //     .rdata(busRData)
  // );

endmodule
