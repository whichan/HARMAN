`timescale 1ns / 1ps

class transaction;
  //Internal Interface
  rand bit [31:0] addr;
  rand bit [31:0] wdata;
  rand bit        transfer;
  rand bit        write;

  //APB Interface Input(Slave 응답용)
  rand bit [31:0] PRDATA0,  PRDATA1, PRDATA2, PRDATA3;
  rand bit        PREADY0,  PREADY1, PREADY2, PREADY3;

  //decoder 범위: 1000_0xxx ~ 1000_3xxx
  constraint c_addr_range {addr inside {[32'h1000_0000 : 32'h1000_3FFF]};}
  constraint c_write_dist {
    write dist {
      1 := 90,
      0 := 10
    };
  }
  constraint c_transfer_dist {
    transfer dist {
      1 := 80,
      0 := 20
    };
  }

  constraint c_ready_dist {
    PREADY0 dist {
      1 := 80,
      0 := 20
    };
    PREADY1 dist {
      1 := 80,
      0 := 20
    };
    PREADY2 dist {
      1 := 80,
      0 := 20
    };
    PREADY3 dist {
      1 := 80,
      0 := 20
    };
  }

  function void print(string name);
    $display("[%s] Addr=%h, Data=%h, WR=%b, Trans=%b", name, addr, wdata, write, transfer);
  endfunction

endclass

interface apb_interface;
  logic        PCLK;
  logic        PRESET;
  logic [31:0] PADDR;
  logic [31:0] PWRITE;
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
  logic        transfer;
  logic        ready;
  logic        write;  //we
  logic [31:0] addr;
  logic [31:0] wdata;
  logic [31:0] rdata;
endinterface  //apb_interface

class generator;
  transaction trans;
  event scb2gen_event;
  mailbox #(transaction) gen2drv_mbox;

  function new(mailbox#(transaction) gen2drv_mbox, event scb2gen_event);
    this.gen2drv_mbox  = gen2drv_mbox;
    this.scb2gen_event = scb2gen_event;
  endfunction

  task run(int count);
    repeat (count) begin
      trans = new();
      trans.randomize();
      gen2drv_mbox.put(trans);
      trans.print("GEN");
      //   @(posedge clk);
    end
  endtask
endclass

class driver;
  transaction trans;
  mailbox #(transaction) gen2drv_mbox;
  virtual apb_interface apb_if;

  function new(mailbox#(transaction) gen2drv_mbox, virtual apb_interface apb_if);
    this.gen2drv_mbox = gen2drv_mbox;
    this.apb_if = apb_if;
  endfunction

  task automatic run();
    gen2drv_mbox.get(trans);
    @(posedge apb_if.PCLK);
    apf_if.transfer <= trans.transfer;
    apf_if.write <= trans.write;
    apf_if.addr <= addr;
    apf_if.wdata <= wdata;
    apf_if.PRDATA0 <= trans.PRDATA0;
    apf_if.PRDATA1 <= trans.PRDATA1;
    apf_if.PRDATA2 <= trans.PRDATA2;
    apf_if.PRDATA3 <= trans.PRDATA3;
    apf_if.PREADY0 <= trans.PREADY0;
    apf_if.PREADY1 <= trans.PREADY1;
    apf_if.PREADY2 <= trans.PREADY2;
    apf_if.PREADY3 <= trans.PREADY3;
  endtask
endclass

class monitor;
  transaction trans;
  virtual apb_interface apb_if;
  mailbox #(transaction) mon2scb_mbox;

  function new(mailbox#(transaction) mon2scb_mbox, virtual apb_interface apb_if);
    this.mon2scb_mbox = mon2scb_mbox;
    this.apb_if = apb_if;
  endfunction

  task run();

  endtask
endclass

class scoreboard;
  transaction trans;
  mailbox #(transaction) mon2scb_mbox;
  event scb2gen_event;

  function new(mailbox#(transaction) mon2scb_mbox, event scb2gen_event);
    this.mon2scb_mbox  = mon2scb_mbox;
    this.scb2gen_event = scb2gen_event;
  endfunction

  logic [31:0] mem[logic [31:0]];

  task run();
    if (trans.transfer) begin
      // if((PSEL0|PSEL1|PSEL2|PSEL3)& !PENABLE) begin
      if (trans.write) begin
        mem[addr] <= trans.wdata;
        //access

        if (PENABLE & PREADY) begin
          if (mem[addr] == trans.wdata) begin

          end
        end
      end`
    end
  endtask
endclass

class environment;
  generator gen;
  driver drv;
  monitor mon;
  scoboard scb;

  mailbox #(transaction) gen2drv_mbox;
  mailbox #(transaction) mon2scb_mbox;

  virtual apb_interface apb_if;

  function new(virtual apb_interface apb_if);
    gen2drv_mbox = new();
    gen = new(gen2drv_mbox, scb2gen_event);
    drv = new(gen2drv_mbox, apb_if);
    mon = new(mon2scb_mbox, apb_if);
    scb = new(mon2scb_mbox, scb2gen_event);

    this.apb_if = apb_if;
  endfunction

  task run();
    fork
      gen.run(100);
      drv.run();
      mon.run();
      scb.run();
    join_any
    $display("test finish");
    #100;
    report();
    $stop;
  endtask

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
  endtask

endclass


module tb_APB_Master ();
  apb_interface apb_if ();
  environment env;

  APB_Master DUT (.*);

  always #5 apb_if.PCLK = ~apb_if.PCLK;

  initial begin
    apb_if.PCLK = 0;
    env = new(apb_if);
    env.run();
    #10;
    $stop;
  end
endmodule
