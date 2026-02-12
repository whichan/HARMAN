interface ram_if (
    input logic clk,
    input logic reset
);
  logic        we;
  logic [ 9:0] addr;
  logic [31:0] wdata;
  logic [31:0] rdata;
endinterface


class transaction;
  rand logic        we;
  rand logic [ 9:0] addr;
  rand logic [31:0] wdata;
  logic      [31:0] rdata;

  task automatic print(string name);
    $display("[%0d]: [%s] we = %0d, addr = %0h, wdata = %0h, rdata = %0h", $time, name, we, addr,
             wdata, rdata);
  endtask  //automatic

  function new();

  endfunction  //new()
endclass  //transaction


class generator;
  transaction            tr;
  event                  scb2gen_event;

  mailbox #(transaction) gen2drv_mbox;

  function new(mailbox#(transaction) gen2drv_mbox, event scb2gen_event);
    this.scb2gen_event = scb2gen_event;
    this.gen2drv_mbox  = gen2drv_mbox;
  endfunction  //new()

  task automatic run(int loop);
    repeat (loop) begin
      tr = new();
      if (!tr.randomize()) $error("Randomization failed!");
      tr.print("GEN");
      gen2drv_mbox.put(tr);
      @(scb2gen_event);
      #10;
    end
  endtask  //automatic
endclass  //generator


class driver;
  transaction            tr;
  virtual ram_if         r_if;
  //   event                  drv2gen_event;
  event                  drv2mon_event;
  mailbox #(transaction) gen2drv_mbox;

  function new(mailbox#(transaction) gen2drv_mbox, virtual ram_if r_if, event drv2gen_event);
    this.gen2drv_mbox = gen2drv_mbox;
    this.r_if = r_if;
    this.drv2mon_event = drv2mon_event;
  endfunction  //new()

  task automatic run();
    forever begin
      gen2drv_mbox.get(tr);
      r_if.we    <= tr.we;
      r_if.addr  <= tr.addr;
      r_if.wdata <= tr.wdata;
      tr.print("DRV");
      @(posedge r_if.clk);
      ->drv2mon_event;
    end
  endtask  //automatic
endclass  //driver

class monitor;
  transaction tr;
  virtual ram_if r_if;
  event drv2mon_event;
  mailbox #(transaction) mon2scb_mbox;

  function new(mailbox#(transaction) mon2scb_mbox, virtual ram_if r_if, event drv2mon_event);
    this.mon2scb_mbox = mon2scb_mbox;
    this.r_if = r_if;
    this.drv2mon_event = drv2mon_event;
  endfunction

  task automatic run();
    forever begin
      //   @(drv2mon_event);
      @(posedge r_if.clk);
      #1;  //신호가 변하고 1ns 뒤 읽음
      tr = new();
      tr.we = r_if.we;
      tr.addr = r_if.addr;
      tr.wdata = r_if.wdata;
      tr.rdata = r_if.rdata;
      mon2scb_mbox.put(tr);
      tr.print("MON");
    end
  endtask  //automatic
endclass

class scoreboard;
  transaction tr;
  event scb2gen_event;
  mailbox #(transaction) mon2scb_mbox;

  int i;
  int total_count = 0;
  int pass_count = 0;
  int fail_count = 0;

  logic [31:0] golden_mem[0:1023];

  function new(mailbox#(transaction) mon2scb_mbox, event scb2gen_event);
    this.mon2scb_mbox  = mon2scb_mbox;
    this.scb2gen_event = scb2gen_event;
  endfunction

  task automatic run();

    for (i = 0; i < 1024; i++) begin
      golden_mem[i] = 32'b0;
    end

    forever begin
      mon2scb_mbox.get(tr);
      total_count++;

      if (tr.we) begin
        golden_mem[tr.addr[9:2]] = tr.wdata;
        if (tr.rdata == golden_mem[tr.addr[9:2]]) begin
          $display("[SCB] PASS! tr.rdata = %0h, golden_mem[tr.addr[9:2]] = %0h", tr.rdata,
                   golden_mem[tr.addr[9:2]]);
          pass_count++;
        end else begin
          $display("[SCB] FAIL! tr.rdata = %0h, golden_mem[tr.addr[9:2]] = %0h", tr.rdata,
                   golden_mem[tr.addr[9:2]]);
          fail_count++;
        end
        $display("[SCB] Write Data Stored: addr = %0h, wdata = %0h", tr.addr, tr.wdata);
      end
      ->scb2gen_event;
    end
  endtask  //automatic
endclass

class environment;
  generator gen;
  driver drv;
  monitor mon;
  scoreboard scb;
  event drv2mon_event, scb2gen_event;
  mailbox #(transaction) gen2drv_mbox;
  mailbox #(transaction) mon2scb_mbox;

  function new(virtual ram_if r_if);
    gen2drv_mbox = new();
    mon2scb_mbox = new();
    gen = new(gen2drv_mbox, scb2gen_event);
    drv = new(gen2drv_mbox, r_if, drv2mon_event);
    mon = new(mon2scb_mbox, r_if, drv2mon_event);
    scb = new(mon2scb_mbox, scb2gen_event);
  endfunction  //new() 

  task automatic run();
    // drv.reset_drv();
    fork
      gen.run(20);
      drv.run();
      mon.run();
      scb.run();
    join_any

    #100;
    report();
    $finish;

  endtask  //automatic

  task report();
    $display("==============================");
    $display("======== Final Report ========");
    $display("==============================");
    $display("====== Total Test = %3d ======", scb.total_count);
    $display("====== Pass Test = %3d =======", scb.pass_count);
    $display("====== Fail Test = %3d =======", scb.fail_count);


    $display("==============================");
    $display("========= Test Finish ========");
    $display("==============================");
    $display("==============================");
  endtask  //report
endclass  //environment


module tb_riscv ();

  logic clk;
  logic reset;

  ram_if r_if (
      clk,
      reset
  );
  environment env;

  always #5 clk = ~clk;

  RAM dut (
      .clk(r_if.clk),
      .we(r_if.we),
      .addr(r_if.addr),
      .wdata(r_if.wdata),
      .rdata(r_if.rdata)
  );


  initial begin
    $fsdbDumpfile("build/wave.fsdb");
    $fsdbDumpvars(0);
  end

  initial begin
    clk = 0;
    env = new(r_if);
    env.run();
    $finish;
  end
endmodule
