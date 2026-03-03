`timescale 1ns / 1ps

class transaction;

    randc bit [3:0] addr; //16byte buffer이므로 4개의 주소 필요
    rand bit [7:0] wdata; //data는 8bit
    rand bit we;
    logic [7:0] rdata;

    constraint sram8 { /*addr inside{[0:3]};*/
                        we dist {0:/50, 1:/50};}

    task print (string name);
        $display("%t: [%s] addr = %d, wdata = %d, we = %d, rdata = %d",
                    $time, name, addr, wdata, we, rdata);
    endtask
endclass //transaction

interface ram_interface;
    logic clk;
    logic reset;
    logic [3:0] addr;
    logic [7:0] wdata;
    logic we;
    logic [7:0] rdata;
endinterface //ram_interface

class generator;
    transaction trans;
    mailbox #(transaction) gen2drv_mbox;
    event scb2gen_next_event;

    function new(mailbox #(transaction) gen2drv_mbox, event scb2gen_next_event);
        this.gen2drv_mbox = gen2drv_mbox;
        this.scb2gen_next_event = scb2gen_next_event;
    endfunction

    task run(int count);
        repeat(count) begin
            trans = new();
            trans.randomize();
            gen2drv_mbox.put(trans);
            //$display("%t: [gen] d = %d", $time, trans.d);
            trans.print("gen");
            @(scb2gen_next_event);
        end
    endtask
endclass //generator

class driver;
    transaction trans;
    mailbox #(transaction) gen2drv_mbox;
    virtual ram_interface ram_if;

    function new(mailbox #(transaction) gen2drv_mbox, 
                    virtual ram_interface ram_if);
        this.gen2drv_mbox = gen2drv_mbox;
        this.ram_if = ram_if;
    endfunction //new()

    task reset();
        ram_if.we = 0;
        // ram_if.addr = 0;
        // ram_if.wdata = 0;
        @(posedge ram_if.clk);
        $display("%t: [drv] reset", $time);
    endtask

    task run();
        forever begin
            @(negedge ram_if.clk);
            gen2drv_mbox.get(trans);
            ram_if.addr = trans.addr;
            ram_if.wdata = trans.wdata;
            ram_if.we = trans.we;
            trans.print("drv");
        end
    endtask
endclass //driver

class scoreboard;
    transaction trans;
    mailbox #(transaction) mon2scb_mbox;
    event scb2gen_next_event;

    function new(mailbox #(transaction) mon2scb_mbox, event scb2gen_next_event);
        this.mon2scb_mbox = mon2scb_mbox;
        this.scb2gen_next_event = scb2gen_next_event;
    endfunction //new()

    int total_count, pass_count, fail_count;

    task run();
        forever begin
            mon2scb_mbox.get(trans);
            trans.print("scb");
            total_count++;

            if(trans.we) begin
                if(trans.wdata == trans.rdata) begin
                    $display("\n");
                    pass_count++;
                end else begin
                    $display("--> FAIL: %x = %x", trans.wdata, trans.rdata);
                    fail_count++;
                end
            end else begin
            end
            -> scb2gen_next_event;
        end
    endtask   
endclass //scoreboard

class monitor;
    transaction trans;
    mailbox #(transaction) mon2scb_mbox;
    virtual ram_interface ram_if;

    function new(mailbox #(transaction) mon2scb_mbox,
                     virtual ram_interface ram_if);
        this.mon2scb_mbox = mon2scb_mbox;
        this.ram_if = ram_if;    
    endfunction //new()

    task run();
        forever begin
            @(posedge ram_if.clk);
            #1;
            trans = new();
            trans.wdata = ram_if.wdata;
            trans.rdata = ram_if.rdata;
            trans.we = ram_if.we;
            mon2scb_mbox.put(trans);
            trans.print("mon");
        end
    endtask
endclass //monitor



class environment;

    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;
    
    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;
    virtual ram_interface ram_if;

    event scb2gen_next_event;

    function new(virtual ram_interface ram_if);
        gen2drv_mbox = new();
        mon2scb_mbox = new();
      
        gen = new(gen2drv_mbox, scb2gen_next_event);
        drv = new(gen2drv_mbox, ram_if);
        mon = new(mon2scb_mbox, ram_if);
        scb = new(mon2scb_mbox, scb2gen_next_event);

        this.ram_if = ram_if;
    endfunction //new()

    task run();
        drv.reset();
        @(posedge ram_if.clk);
        
            fork
                gen.run(100);
                drv.run();   
                scb.run();
                mon.run(); 
            join_any
        //@(posedge ram_if.clk);
        
        #100
        report();
        $stop;
    endtask

    task report();
        $display("=========================");
        $display("=== Final Report ========");
        $display("=========================");
        $display("==== Total Test = %3d ===", scb.total_count);
        $display("==== Pass Test = %3d ===", scb.pass_count);
        $display("==== Fail Test = %3d ===", scb.fail_count);
        

        $display("=========================");
        $display("========Test Finish======");
        $display("=========================");
        $display("=========================");
    endtask //report

endclass //environment


module tb_sram();

    ram_interface ram_if();
    environment env;

    sram dut(
        .clk(ram_if.clk),
        .addr(ram_if.addr), //4byte buffer이므로 2개의 주소 필요
        .wdata(ram_if.wdata), //data는 8bit
        .we(ram_if.we),
        .rdata(ram_if.rdata)
    );

    always #5 ram_if.clk = ~ram_if.clk;

    initial begin
        ram_if.clk = 0;
        env = new(ram_if); //class
        env.run();
        #10;
        $stop;    
    end
endmodule