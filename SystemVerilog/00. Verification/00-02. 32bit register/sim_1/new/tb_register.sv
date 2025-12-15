`timescale 1ns / 1ps

class transaction;
    rand bit [31:0] d;
    logic [31:0] q;

    constraint reg32 {
        d inside {[100:200]}; //d의 범위는 100~200
    }
endclass //transaction

interface register_interface;
    logic clk;
    logic reset;
    logic [31:0] d;
    logic [31:0] q;
endinterface //register_interface

//generator
class generator;
    transaction trans;
    mailbox #(transaction) gen2drv_mbox;
    
    function new(mailbox #(transaction) gen2drv_mbox);
        this.gen2drv_mbox = gen2drv_mbox; //이 클래스의 mbox와 외부의 mbox를 연결
    endfunction

    task run();
        //task에서 메시지를 생성해서 gen2drv_mbox에 계속 넣어줘야함
        trans = new();
        trans.randomize();
        gen2drv_mbox.put(trans); //gen2drv_mbox 안에 trans를 putS
        $display("%t: [gen] d = %d", $time, trans.d);
    endtask //run
endclass    

class driver;
    //driver는 transaction, mbox, interface가 필요함
    
    transaction trans;
    mailbox #(transaction) gen2drv_mbox;
    virtual register_interface reg_if;

    function new(mailbox #(transaction) gen2drv_mbox, virtual register_interface reg_if);
        this.gen2drv_mbox = gen2drv_mbox;
        this.reg_if = reg_if;
    endfunction //new()

    task reset(); //task는 시간제약이 가능함
        reg_if.reset = 1;
        @(posedge reg_if.clk); //1클럭
        @(posedge reg_if.clk);
        reg_if.reset = 0;
        @(posedge reg_if.clk);
        $display("%t: [drv] reset", $time);
    endtask //reset

    task run();
        //메시지 받아서 interface로 drive 하면됨

        @(negedge reg_if.clk);
        gen2drv_mbox.get(trans);
        reg_if.d = trans.d;

        $display("%t: [drv] d = %d", $time, reg_if.d);
    endtask
endclass //driver

class monitor;
    //mailbox, interface, transaction 필요
    
    transaction trans; //handle
    mailbox #(transaction) mon2scb_mbox;
    virtual register_interface reg_if;
    
    function new(mailbox #(transaction) mon2scb_mbox, virtual register_interface reg_if);
        //밖에서 mon2scb_mbox와 reg_if
        this.mon2scb_mbox = mon2scb_mbox;
        this.reg_if = reg_if;
    endfunction //new()

    task run();
        trans = new();
        trans.d = reg_if.d; //d line을 읽음
        #1;
        trans.q = reg_if.q; //q line을 읽음
        mon2scb_mbox.put(trans);
        $display("%t: [mon] d=%d, q=%d",$time, reg_if.d, reg_if.q);
    endtask //run
endclass //monitor


class environment;
    
    generator gen;
    driver drv;
    monitor mon;
    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;
    virtual register_interface reg_if;

    //environment는 외부 interface가 필요함.
    function new(virtual register_interface reg_if);
        gen2drv_mbox = new();
        mon2scb_mbox = new();
        gen = new(gen2drv_mbox); //generator를 먼저 생성
        drv = new(gen2drv_mbox, reg_if);
        mon = new(mon2scb_mbox, reg_if);
        this.reg_if = reg_if;
    endfunction //new()
        
    task run();
        drv.reset();
        @(posedge reg_if.clk);
        //나중에 여기다가 할 일을 적으면 됨

        fork
            gen.run(); //generator의 task를 돌린다는 뜻        
            drv.run();      
            mon.run();
        join_any
            @(posedge reg_if.clk);
    endtask
endclass //environment

module tb_register();

    register_interface reg_if();
    environment env; //handler. 인자를 받아주기 위한것
                     //실제 생성은 밑의 initial 안에서 env=new();

    register dut(
        .clk(reg_if.clk),
        .reset(reg_if.reset),
        .d(reg_if.d),
        .q(reg_if.q)
    );

    always #5 reg_if.clk = ~reg_if.clk;

    initial begin
        reg_if.clk = 0;
        env = new(reg_if); //class
        env.run();
    end

endmodule