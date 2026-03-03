module tb_axi_lite ();
  // Global Signal
  logic        ACLK;
  logic        ARESETn;
  // WRITE Transaction, AW Channel
  logic [ 3:0] AWADDR;
  logic        AWVALID;
  logic        AWREADY;
  // WRITE Transaction, W Channel
  logic [31:0] WDATA;
  logic        WVALID;
  logic        WREADY;
  // WRITE Transaction, B Channel
  logic [ 1:0] BRESP;
  logic        BVALID;
  logic        BREADY;

  // READ Transaction, AR Channel
  logic [ 3:0] ARADDR;
  logic        ARVALID;
  logic        ARREADY;

  // READ Transaction, R Channel
  logic [31:0] RDATA;
  logic        RVALID;
  logic        RREADY;
  logic [ 1:0] RRESP;

  // internal Signals
  // 밑의 신호들을 보내줘야함
  logic        transfer;
  logic        ready;
  logic [ 3:0] addr;
  logic [31:0] wdata;
  logic        write;
  logic [31:0] rdata;

  AXI4_lite_Master dut_master (.*);
  AXI4_lite_Slave dut_slave (.*);

  always #5 ACLK = ~ACLK;

  initial begin
    ACLK = 0;
    ARESETn = 0;
    #10;
    ARESETn = 1;
    @(posedge ACLK);
    @(posedge ACLK);
    axi_write(32'h00000000, 32'h11111111);
    axi_write(32'h00000004, 32'h22222222);
    axi_write(32'h00000008, 32'h33333333);
    axi_write(32'h0000000c, 32'h44444444);
    axi_read(32'h00000000, rdata);
    axi_read(32'h00000004, rdata);
    axi_read(32'h00000008, rdata);
    axi_read(32'h0000000c, rdata);
    @(posedge ACLK);
    @(posedge ACLK);
    @(posedge ACLK);
    $finish;
  end

  task axi_write(logic [31:0] axiAddr, logic [31:0] axiData);
    @(posedge ACLK);
    addr = axiAddr;
    wdata = axiData;
    write = 1'b1;
    transfer = 1'b1;
    @(posedge ACLK);
    transfer = 1'b0;  //한클럭 후에 transfer를 0으로
    wait (ready);  //ready가 올 때까지 기다림
    @(posedge ACLK);
  endtask

  task axi_read(logic [31:0] axiAddr, logic [31:0] axiData);
    @(posedge ACLK);
    addr = axiAddr;
    write = 1'b0;
    transfer = 1'b1;
    @(posedge ACLK);
    transfer = 1'b0;  //한클럭 후에 transfer를 0으로
    wait (ready);  //ready가 올 때까지 기다림
    @(posedge ACLK);
  endtask

endmodule
