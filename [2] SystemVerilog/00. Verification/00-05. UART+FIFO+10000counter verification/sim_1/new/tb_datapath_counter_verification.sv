`timescale 1ns / 1ps

class transaction;
    rand bit clear;
    rand bit run_stop;
    rand bit mode;
    rand bit [13:0] set_value;
    rand bit set_en;
    
    logic [13:0] counter;

    constraint r_dist {run_stop dist {1:=60, 0:=40};}
    constraint c_dist {clear dist {1:=2, 0:=98};}
    constraint m_dist {mode dist {1:= 30, 0:=70};}
    constraint set_enable_dist { set_en   dist { 1 := 2,  0 := 98 }; } // 5% 확률로만 Set
    constraint limit {set_value <= 9999;}

    task print(string name);
        $display("[%t] [%s] Run:%b Mode:%b Clear:%b | Set enable:%b Set Value:%4d | Count:%0d",
            $time, name, 
            run_stop, mode, clear, 
            set_en, set_value, 
            counter);
    endtask
endclass

interface datapath_counter_interface;
    logic clk;
    logic reset;
    logic clear;
    logic run_stop;
    logic mode;
    
    logic [13:0] set_value;
    logic set_en;
    logic [13:0] counter;
endinterface

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
endclass

class driver;
    transaction trans;
    mailbox #(transaction) gen2drv_mbox;
    virtual datapath_counter_interface dp_if;
    event drv2mon_next_event;

    function new(mailbox #(transaction) gen2drv_mbox,
                virtual datapath_counter_interface dp_if,
                event drv2mon_next_event);
        this.gen2drv_mbox = gen2drv_mbox;
        this.dp_if = dp_if;
        this.drv2mon_next_event = drv2mon_next_event;
    endfunction

    task reset();
        $display("[drv] reset");
        dp_if.reset <= 1'b1;
        dp_if.mode <= 1'b0;
        dp_if.run_stop <= 1'b0;
        dp_if.clear <= 1'b0;
        dp_if.set_value <= 0;
        dp_if.set_en <= 1'b0;
        repeat(2) @(posedge dp_if.clk);
        dp_if.reset <= 1'b0;
    endtask

    task run();
        forever begin
            gen2drv_mbox.get(trans); //mailbox에서 데이터를 꺼냄
            @(posedge dp_if.clk); //상승엣지까지 대기
            //#2;
            dp_if.mode <= trans.mode; //interface 신호에 값을 할당(drive)
            dp_if.run_stop <= trans.run_stop;
            dp_if.clear <= trans.clear;
            dp_if.set_value <= trans.set_value;
            dp_if.set_en <= trans.set_en;

            #1 -> drv2mon_next_event; //1ns 딜레이 후 event를 줘서 monitor를 깨움
            trans.print("drv");

            
            // @(posedge dp_if.clk);
            // if(trans.clear) dp_if.clear <= 0; //clear 1클럭 후 끄기
            // if(trans.setn_en) dp_if.set_en <= 0; //set_en 1클럭 후 끄기
        end
    endtask
endclass

class monitor;
    transaction trans;
    mailbox #(transaction) mon2scb_mbox;
    virtual datapath_counter_interface dp_if;
    event drv2mon_next_event;

    function new (mailbox #(transaction) mon2scb_mbox,
                virtual datapath_counter_interface dp_if,
                event drv2mon_next_event);
        this.mon2scb_mbox = mon2scb_mbox;
        this.dp_if = dp_if;
        this.drv2mon_next_event = drv2mon_next_event;
    endfunction
    
    task run();
        forever begin
            @(drv2mon_next_event);
            trans = new();
            trans.mode = dp_if.mode;
            trans.clear = dp_if.clear;
            trans.run_stop = dp_if.run_stop;
            trans.set_value = dp_if.set_value;
            trans.set_en = dp_if.set_en;
            
            @(posedge dp_if.clk);

            #1;
            trans.counter = dp_if.counter;
            
            mon2scb_mbox.put(trans);
            trans.print("mon");
        end
    endtask
endclass

// class scoreboard;
//     transaction trans;
//     mailbox #(transaction) mon2scb_mbox;
//     event scb2gen_next_event;

//     int total_count, pass_count, fail_count;

//     // Reference Model용 변수
//     int ref_count;      
//     int tick_cnt;       
    
//     // DUT 파라미터와 동일 (4)
//     const int SIM_DIV_MAX = 4; 

//     function new(mailbox #(transaction) mon2scb_mbox, event scb2gen_next_event);
//         this.mon2scb_mbox = mon2scb_mbox;
//         this.scb2gen_next_event = scb2gen_next_event;
//         ref_count = 9998; 
//         tick_cnt = 0;
//         total_count = 0; pass_count = 0; fail_count = 0;
//     endfunction

//     task run();
//         bit is_tick;
//         forever begin
//             mon2scb_mbox.get(trans);
//             total_count++;

//             // ========================================================
//             // [핵심 FIX] 강제 동기화 (Sync)
//             // DUT가 리셋 초기값(9998) 상태라면, 
//             // Scoreboard도 내부 타이머를 0으로 리셋해서 박자를 맞춥니다.
//             // ========================================================
//             if (trans.counter == 9998) begin
//                 tick_cnt = 0; 
//             end

//             // 1. 하드웨어 타이머 시뮬레이션
//             tick_cnt++; 
//             is_tick = 0;
            
//             if (tick_cnt >= SIM_DIV_MAX) begin
//                 tick_cnt = 0;
//                 is_tick = 1; 
//             end

//             // 2. 동작 예측
//             if (trans.clear) begin
//                 ref_count = 0;
//             end
//             else if (trans.set_en) begin
//                 ref_count = trans.set_value;
//             end
//             else if (is_tick && trans.run_stop) begin
//                 case (trans.mode)
//                     1'b0: begin // UP
//                         if (ref_count >= 9999) ref_count = 0;
//                         else ref_count++;
//                     end
//                     1'b1: begin // DOWN
//                         if (ref_count == 0) ref_count = 9999;
//                         else ref_count--;
//                     end
//                 endcase
//             end
            
//             // 3. 비교
//             if (ref_count == trans.counter) begin
//                 pass_count++;
//                 $display("[SCB] PASS (%0d) Value:%0d", total_count, ref_count);
//             end 
//             else begin
//                 fail_count++;
//                 $display("---------------------------------------------------");
//                 $display("[SCB] FAIL! (%0d)", total_count);
//                 $display("Expected: %0d", ref_count);
//                 $display("Actual  : %0d", trans.counter);
//                 $display("State   : Run=%b Tick=%b Clr=%b", trans.run_stop, is_tick, trans.clear);
//                 $display("---------------------------------------------------");
//             end

//             -> scb2gen_next_event;
//         end
//     endtask
// endclass

class scoreboard;
    transaction trans;
    mailbox #(transaction) mon2scb_mbox;
    event scb2gen_next_event;

    int total_count, pass_count, fail_count;
    int ref_count;
    int tick_cnt;

    const int SIM_DIV_MAX = 4;

    function new(mailbox #(transaction) mon2scb_mbox,
                event scb2gen_next_event);
        this.mon2scb_mbox = mon2scb_mbox;
        this.scb2gen_next_event = scb2gen_next_event;

        //DUT의 reset동작과 일치시킴
        ref_count = 0;
        tick_cnt = 0;
        total_count = 0; pass_count = 0; fail_count = 0;
    endfunction

    task run();
        bit is_tick;
        logic [13:0] prev_counter;

        forever begin
            mon2scb_mbox.get(trans);
            total_count++;

            //1. 하드웨어 타이머 시뮬레이션
            //DUT: 0,1,2,3(tick)
            tick_cnt++;
            is_tick = 0;
            if(tick_cnt >= SIM_DIV_MAX) begin
                tick_cnt = 0;
                is_tick = 1;
            end

            //2. 동작 예측(Reference Model)
            if(trans.clear) begin
                ref_count = 0;
            end else if (trans.set_en) begin
                ref_count = trans.set_value;
            end else if (is_tick && trans.run_stop) begin
                case(trans.mode)
                    1'b0: begin
                        if(ref_count >= 9999) ref_count = 0;
                        else ref_count++;
                    end

                    1'b1: begin
                        if(ref_count == 0) ref_count = 9999;
                        else ref_count --;
                    end
                endcase
            end

            //3. 비교
            if(ref_count == trans.counter) begin
                pass_count++;
                $display("[SCB] PASS (%0d)", total_count);
            end else begin
                fail_count++;
                $display("\n[SCB] FAIL! at Time %0t", $time);
                $display("Expected: %0d | Actual: %0d", ref_count, trans.counter);
                $display("Inputs  : Run=%b TickGen=%b Clear=%b Set=%b(%0d)\n", 
                         trans.run_stop, is_tick, trans.clear, trans.set_en, trans.set_value);
            end
            prev_counter = trans.counter;
            -> scb2gen_next_event;
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

    virtual datapath_counter_interface dp_if;

    event drv2mon_next_event;
    event scb2gen_next_event;

    function new(virtual datapath_counter_interface dp_if);
        gen2drv_mbox = new();
        mon2scb_mbox = new();

        gen = new(gen2drv_mbox, scb2gen_next_event);
        drv = new(gen2drv_mbox, dp_if, drv2mon_next_event);
        mon = new(mon2scb_mbox, dp_if, drv2mon_next_event);
        scb = new(mon2scb_mbox, scb2gen_next_event);

        this.dp_if = dp_if;
    endfunction

    task run();
        drv.reset();
        @(posedge dp_if.clk);
        fork
            gen.run(200);
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

module tb_datapath_counter_verification();

    datapath_counter_interface dp_if();
    environment env;

    datapath_counter #(
        .SIM_MAX_COUNT(4)
    ) dut(
        .clk(dp_if.clk),
        .reset(dp_if.reset),
        .clear(dp_if.clear),
        .run_stop(dp_if.run_stop),
        .mode(dp_if.mode),

        .set_value(dp_if.set_value),
        .set_en(dp_if.set_en),

        .counter(dp_if.counter)
    );

    always #5 dp_if.clk = ~dp_if.clk;

    initial begin
        dp_if.clk = 0;
        env = new(dp_if);
        env.run();
        #10;
        $stop;
    end
endmodule