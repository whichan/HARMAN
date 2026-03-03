`timescale 1ns / 1ps



module tb_spi ();
  logic       clk;
  logic       reset;
  //internal signals
  logic       start;
  logic [7:0] tx_data;
  logic [7:0] tx_ready;
  logic [7:0] rx_data;
  logic       done;
  //external SPI signals
  logic       sclk;
  logic       cpol;
  logic       cpha;
  // logic mosi;
  // logic miso;
  logic       loop_wire;  // loopback을 위한 wire

  spi_master dut (
      .*,
      .mosi(loop_wire),
      .miso(loop_wire)
  );

  always #5 clk = ~clk;
  initial begin
    clk   = 0;
    reset = 1;
    #10;
    reset = 0;
  end

  task spi_mode(bit pol, bit pha);
    @(posedge clk);
    cpol = pol;
    cpha = pha;
    @(posedge clk);
  endtask

  task spi_write(logic [7:0] data);
    @(posedge clk);
    wait (tx_ready);
    start   = 1;
    tx_data = data;
    @(posedge clk);
    start = 0;
    wait (done);
    @(posedge clk);
  endtask

  initial begin
    repeat (5) @(posedge clk);
    spi_mode(0, 0);
    spi_write(8'haa);
    @(posedge clk);
    @(posedge clk);
    spi_mode(0, 1);
    spi_write(8'h55);
    @(posedge clk);
    @(posedge clk);
    spi_mode(1, 0);
    spi_write(8'h0f);
    @(posedge clk);
    @(posedge clk);
    spi_mode(1, 1);
    spi_write(8'hf0);
    @(posedge clk);
    @(posedge clk);
    $finish;
  end
endmodule

