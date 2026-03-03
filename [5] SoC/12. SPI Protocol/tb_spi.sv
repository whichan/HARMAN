`timescale 1ns / 1ps

module tb_spi_top ();

  logic       clk;
  logic       reset;
  logic       start;
  logic [7:0] tx_data;  //cpu -> spi master -> spi slave
  logic       tx_ready;  //spi master -> cpu
  logic [7:0] rx_data;  //spi slave -> spi master -> cpu
  logic       done;  //spi master -> cpu
  logic       cpha;
  logic       cpol;
  logic [7:0] slave_tx_data;
  logic [7:0] slave_rx_data;
  logic       slave_rx_done;

  spi_top dut (.*);

  initial begin
    #0;
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    #0;
    reset = 1;
    start = 0;
    cpol = 0;
    cpha = 0;
    tx_data = 8'h00;
    #20;
    reset = 0;
    repeat (10) @(posedge clk);

    //mode=0
    run_spi_test(1'b0, 1'b0, 8'b1010_1010, 8'b1101_1011);
    //mode=1
    run_spi_test(1'b0, 1'b1, 8'b1110_1010, 8'b1100_1010);
    //mode=2
    run_spi_test(1'b1, 1'b0, 8'b1010_1010, 8'b1101_1011);
    //mode=3
    run_spi_test(1'b1, 1'b1, 8'b1010_1010, 8'b1101_1011);

  end

  task run_spi_test(input i_cpol, input i_cpha, input [7:0] m_data, input [7:0] s_data);
    //m_data: master data //s_data: slave data
    begin
      //tx_ready가 1이 되면 데이터 전송
      wait (tx_ready);
      @(posedge clk);
      cpol          = i_cpol;
      cpha          = i_cpha;
      tx_data       = m_data;
      slave_tx_data = s_data;
      start         = 1;
      @(posedge clk);
      start = 0;

      wait (done);
      $display("[Mode %0d] Master TX: %b, Slave Tx: %b || Master Rx: %b, Slave Rx: %b", {
               i_cpol, i_cpha}, m_data, s_data, rx_data, slave_rx_data);
      #100000;
    end
  endtask  //run_spi_test
endmodule
