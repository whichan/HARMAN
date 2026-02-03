`timescale 1ns / 1ps

module tb_APB_Master_test ();

  // global signals
  logic        PCLK;
  logic        PRESET;
  // APB Interface Signals
  logic [31:0] PADDR;
  logic        PWRITE;
  logic        PENABLE;
  logic [31:0] PWDATA;
  logic        PSEL0;
  logic        PSEL1;
  logic        PSEL2;
  logic        PSEL3;

  logic [31:0] PRDATA0;
  logic [31:0] PRDATA1;
  logic [31:0] PRDATA2;
  logic [31:0] PRDATA3;
  logic        PREADY0;
  logic        PREADY1;
  logic        PREADY2;
  logic        PREADY3;

  //Internal Interface Signal
  logic        transfer;
  logic        ready;
  logic        write;  //we
  logic [31:0] addr;
  logic [31:0] wdata;
  logic [31:0] rdata;

  APB_Master dut (

      .PCLK  (PCLK),
      .PRESET(PRESET),

      // APB Interface Signals
      .PADDR  (PADDR),
      .PWRITE (PWRITE),
      .PENABLE(PENABLE),
      .PWDATA (PWDATA),
      .PSEL0  (PSEL0),
      .PSEL1  (PSEL1),
      .PSEL2  (PSEL2),
      .PSEL3  (PSEL3),

      .PRDATA0(PRDATA0),
      .PRDATA1(PRDATA1),
      .PRDATA2(PRDATA2),
      .PRDATA3(PRDATA3),
      .PREADY0(PREADY0),
      .PREADY1(PREADY1),
      .PREADY2(PREADY2),
      .PREADY3(PREADY3),

      //Internal Interface Signal
      .transfer(transfer),
      .ready(ready),
      .write(write),     //we
      .addr(addr),
      .wdata(wdata),
      .rdata(rdata)
  );

  initial begin
    PCLK = 0;
    forever #5 PCLK = ~PCLK;
  end

  initial begin
    // 1. 초기화 및 리셋 (PRESETn은 보통 active-low지만 코드에 맞춰 active-high로 수행) [cite: 297]
    PRESET = 1;
    transfer = 0;
    write = 0;
    addr = 0;
    wdata = 0;
    PREADY0 = 1;
    PREADY1 = 1;
    PREADY2 = 1;
    PREADY3 = 1;  // 슬레이브 준비 완료 상태 가정
    #15 PRESET = 0;
    repeat (2) @(posedge PCLK);

    // 시나리오 A: RAM(Slave 0)에 데이터 쓰기
    @(posedge PCLK);
    transfer = 1;
    write    = 1;  // Write 동작 [cite: 297]
    addr     = 32'h1000_0010;  // PSEL0을 깨우는 주소
    wdata    = 32'hDEAD_BEEF;

    @(posedge PCLK);
    // 이 시점에서 마스터는 SETUP 상태 (PSEL=1, PENABLE=0) [cite: 361, 362]

    @(posedge PCLK);
    // 이 시점에서 마스터는 ACCESS 상태 (PSEL=1, PENABLE=1) [cite: 363]
    transfer = 0;  // 다음 전송이 없으면 IDLE로 가기 위해 내림 [cite: 689]

    @(posedge PCLK);
    // 전송 완료 후 IDLE 복귀 확인

    // 시나리오 B: Peripheral 1(Slave 1)에서 데이터 읽기
    @(posedge PCLK);
    transfer = 1;
    write    = 0;  // Read 동작 [cite: 297]
    addr     = 32'h1000_1004;  // PSEL1을 깨우는 주소
    PRDATA1  = 32'hCAFE_F00D;  // 슬레이브가 보내주는 데이터 가정 [cite: 302]

    wait (ready);  // 마스터의 ready(PREADY 선택됨)가 1이 될 때까지 대기
    @(posedge PCLK);
    transfer = 0;

    #50 $finish;
  end

endmodule
