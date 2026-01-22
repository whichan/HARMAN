`timescale 1ns / 1ps

class transaction;
    rand bit mode;
    rand bit run_stop;
    rand bit clear;

    logic o_mode;
    logic o_run_stop;
    logic o_clear;

    constraint clear_dist {
        clear dist {0:=96, 1:=4};  
    }

    task print(string name);
        $display("%t: [%s], mode = %d, run_stop = %d, clear = %d", 
                    $time, name, mode, run_stop, clear);
    endtask
endclass


interface command_controller_interface;
    logic clk;
    logic reset;
    
    logic mode;
    logic run_stop;
    logic clear;
    
    logic o_mode;
    logic o_run_stop;
    logic o_clear;
endinterface //command_controller_interface


class generator;
    transaction trans;
    mailbox #(transaction) gen2drv_mbox;
    event scb2gen_next_event;

    function new(mailbox #(transaction) gen2drv_mbox,
                event scb2gen_next_event);
        this.gen2drv_mbox = gen2drv_mbox;
        this.scb2gen_next_event = scb2gen_next_event;
    endfunction

    task run(int count);
        repeat(count) begin
            trans = new();
            trans.randomize();
            gen2drv_mbox.put(trans);
            trans.print("gen");
            @(scb2gen_next_event);
        end
    endtask
endclass //generator

class driver;
    transaction trans;
    mailbox #(transaction) gen2drv_mbox;
    virtual command_controller_interface cmd_if;
    event drv2mon_next_event;

    function new(mailbox #(transaction) gen2drv_mbox, 
                virtual command_controller_interface cmd_if,
                event drv2mon_next_event);
        this.gen2drv_mbox = gen2drv_mbox;
        this.cmd_if = cmd_if;
        this.drv2mon_next_event = drv2mon_next_event;
    endfunction

    task reset();
        //초기값
        cmd_if.reset = 1'b1;
        cmd_if.mode = 1'b0;
        cmd_if.run_stop = 1'b0;
        cmd_if.clear = 1'b0;
        repeat(2) @(posedge cmd_if.clk); //리셋 2클럭 유지
        cmd_if.reset = 1'b0;
    endtask

    task run();
        forever begin
            @(posedge cmd_if.clk);
            gen2drv_mbox.get(trans);
            cmd_if.mode <= trans.mode;
            cmd_if.run_stop <= trans.run_stop;
            cmd_if.clear <= trans.clear;
            
            #1 -> drv2mon_next_event; //1ns 딜레이 후 event
            trans.print("drv");
        end
    endtask
endclass

class monitor;
    transaction trans;
    mailbox #(transaction) mon2scb_mbox;
    virtual command_controller_interface cmd_if;
    event drv2mon_next_event;

    function new(mailbox #(transaction) mon2scb_mbox,
                virtual command_controller_interface cmd_if,
                event drv2mon_next_event);
        this.mon2scb_mbox = mon2scb_mbox;
        this.cmd_if = cmd_if;
        this.drv2mon_next_event = drv2mon_next_event;
    endfunction //new()

    task run();
        forever begin
            //@(posedge cmd_if.clk);
            @(drv2mon_next_event);
            trans = new();
            trans.mode = cmd_if.mode;
            trans.run_stop = cmd_if.run_stop;
            trans.clear = cmd_if.clear;

            @(posedge cmd_if.clk);
            
            #1;
            trans.o_mode = cmd_if.o_mode;
            trans.o_run_stop = cmd_if.o_run_stop;
            trans.o_clear = cmd_if.o_clear;

            mon2scb_mbox.put(trans);
            trans.print("mon");
        end
    endtask
endclass

class scoreboard;
    transaction trans;
    mailbox #(transaction) mon2scb_mbox;
    event scb2gen_next_event;

    int total_count, pass_count, fail_count;
    
    bit ref_run; //0:IDLE, STOP, 1:동작중(UP/DOWN)
    bit ref_mode; // 0:UP, 1:DOWN
    bit ref_clear; //clear 상태인지 확인

    function new(mailbox #(transaction) mon2scb_mbox,
                event scb2gen_next_event);
        this.mon2scb_mbox = mon2scb_mbox;
        this.scb2gen_next_event = scb2gen_next_event;
        
        this.ref_run = 1'b0;
        this.ref_mode = 1'b0;
        this.ref_clear = 1'b1;
    endfunction

    task run();
        logic exp_mode;
        forever begin

            mon2scb_mbox.get(trans);
            total_count++;
            
            //=====Golden Model=====//
            if(trans.clear) begin
                //clear 신호가 오면 무조건 초기화
                ref_run = 0;
                ref_mode = 0;
                ref_clear = 1;
            end else begin
                // clear 입력 0
                if(ref_clear == 1) begin
                    // 만약 현재 IDLE 상태라면
                    // run_stop 신호가 와야만 IDLE을 탈출
                    if(trans.run_stop) begin
                        ref_clear = 0; //IDLE 탈출
                        ref_run = 1;
                        ref_mode = trans.mode;
                    end
                end else begin
                    //현재 IDLE 아니고 stop or run
                    //이미 탈출했으므로 ref_clear = 0 유지
                    
                    if(ref_run == 0) begin
                        //현재 멈춰있는 상황
                        //run_stop 신호가 들어오면 동작 시작
                        if(trans.run_stop) begin
                            ref_run = 1;
                            ref_mode = trans.mode; //입력된 모드로 설정
                        end
                    end else begin
                        //현대 동작 중인 상황(up or down)
                        if(!trans.run_stop) begin
                            //run_stop 신호가 꺼지면 멈춤
                            ref_run = 0;
                        end else if(trans.mode != ref_mode) begin
                            //동작 중인데 모드가 바뀌었다면
                            ref_mode = trans.mode; //모드 변경
                        end
                    end
                end
            end
            
            //=====비교(RTL출력 vs 내 예측값)=====//
            
            // 나의 예측값:
            // o_run_stop은 내가 추적한 ref_run과 같아야함
            // o_mode는 내가 추적한 ref_mode와 같아야함
            // o_clear는 ref_clear와 같아야함

            // RTL의 o_clear 동작 특성:IDLE일때만 1
            
            
            //만약 clear 상태(IDLE)라면 저장된 모드가 뭐든 간에 출력은 무조거너 0
            //아니라면 저장된 ref_mode가 그대로 출력
            if(ref_clear == 1'b1) begin
                exp_mode = 1'b0;
            end else begin
                exp_mode = ref_mode;
            end



            if (trans.o_mode === exp_mode && 
                trans.o_run_stop === ref_run &&
                trans.o_clear === ref_clear) begin
                
                $display("[PASS] Run:%b Mode:%b Clear:%b", ref_run, ref_mode, ref_clear);
                pass_count++;
            end else begin
                $error("[FAIL] Expected(Run,Mode,Clr): %b,%b,%b | Actual: %b,%b,%b", 
                        ref_run, ref_mode, ref_clear,
                        trans.o_run_stop, trans.o_mode, trans.o_clear);
                fail_count++;
            end
            ->scb2gen_next_event;
        end
    endtask
endclass


class environment;
    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;

    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;

    virtual command_controller_interface cmd_if;

    event drv2mon_next_event;
    event scb2gen_next_event;

    function new(virtual command_controller_interface cmd_if);
        gen2drv_mbox = new();
        mon2scb_mbox = new();

        gen = new(gen2drv_mbox, scb2gen_next_event);
        drv = new(gen2drv_mbox, cmd_if, drv2mon_next_event);
        mon = new(mon2scb_mbox, cmd_if, drv2mon_next_event);
        scb = new(mon2scb_mbox, scb2gen_next_event);

        this.cmd_if = cmd_if;
    endfunction

    task run();
        drv.reset();
        @(posedge cmd_if.clk);
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
    endtask //report

endclass



module tb_command_controller_verification();

    command_controller_interface cmd_if();
    environment env;
    
    command_controller dut(
        .clk(cmd_if.clk),
        .reset(cmd_if.reset),
        .mode(cmd_if.mode),
        .run_stop(cmd_if.run_stop),
        .clear(cmd_if.clear),
        .o_mode(cmd_if.o_mode),
        .o_run_stop(cmd_if.o_run_stop),
        .o_clear(cmd_if.o_clear)
    );

    always #5 cmd_if.clk = ~cmd_if.clk;

    initial begin
        cmd_if.clk = 0;
        env = new(cmd_if);
        env.run();
        #10;
        $stop;
    end
endmodule