`timescale 1ns / 1ps

class transaction;

    rand bit [7:0] wdata;
    rand bit wr;
    rand bit rd;
    
    logic full;
    logic empty;
    logic [7:0] rdata;

    constraint fifo {wr dist {0:/30, 1:/70};}

    task print (string name);
        $display("%t: [%s], wdata = %d, wr = %d, rd = %d, rdata = %d",
                    $time, name, wdata, wr, rd, rdata);
    endtask

endclass //transaction

interface fifo_interface;
    logic clk;
    logic reset;
    logic [7:0] wdata;
    logic [7:0] rdata;
    logic wr;
    logic rd;

    logic full;
    logic empty;
endinterface //fifo_interface

class generator;

    transaction trans;
    mailbox #(transaction) gen2drv_mbox;
    event scb2gen_next_event;
    
    function new(mailbox #(transaction) gen2drv_mbox,
                event scb2gen_next_event);
        this.gen2drv_mbox = gen2drv_mbox;
        this.scb2gen_next_event = scb2gen_next_event;
    endfunction //new()

    task run(int count); //count는 environment에서 주는 숫자대로 받음
        repeat(count) begin
            trans = new(); //택배상자 생성
            trans.randomize(); //랜덤돌리기
            gen2drv_mbox.put(trans); //mailbox에 넣기
            trans.print("gen");
            @(scb2gen_next_event); //scb가 신호를 보낼 때까지 기다리기
        end       
    endtask
endclass //generator

class driver;
    
    transaction trans;
    mailbox #(transaction) gen2drv_mbox;
    virtual fifo_interface fifo_if;
    event drv2mon_next_event;

    function new(mailbox #(transaction) gen2drv_mbox, 
                virtual fifo_interface fifo_if,
                event drv2mon_next_event);
        this.gen2drv_mbox = gen2drv_mbox;
        this.fifo_if = fifo_if;
        this.drv2mon_next_event = drv2mon_next_event;
    endfunction //new()

    task reset();
        //초기값
        fifo_if.reset = 1'b1;
        fifo_if.wr = 1'b0;
        fifo_if.rd = 1'b0;
        fifo_if.wdata = 8'h00;

        repeat(2) @(posedge fifo_if.clk); //리셋 2클럭 유지

        fifo_if.reset = 1'b0; //리셋 해제
    endtask

    task run();
        forever begin
            @(posedge fifo_if.clk); //상승엣지마다
            gen2drv_mbox.get(trans); //메일박스에서 trans 받아서
            fifo_if.wdata <= trans.wdata;
            fifo_if.wr <= trans.wr;
            fifo_if.rd <= trans.rd; //연결

            #1 -> drv2mon_next_event; //1ns 딜레이 걸어서 monitor에게 신호 주기
            trans.print("drv");
            //@(posedge fifo_if.clk);

            // fifo_if.wr <= 1'b0;
            // fifo_if.rd <= 1'b0;
        end
    endtask
endclass //driver

class monitor;
    
    transaction trans;
    mailbox #(transaction) mon2scb_mbox;
    virtual fifo_interface fifo_if;
    event drv2mon_next_event;

    function new(mailbox #(transaction) mon2scb_mbox,
                virtual fifo_interface fifo_if,
                event drv2mon_next_event);
        this.mon2scb_mbox = mon2scb_mbox;
        this.fifo_if = fifo_if;
        this.drv2mon_next_event = drv2mon_next_event;
    endfunction //new()

    task run();
        forever begin
            //@(posedge fifo_if.clk);
            @(drv2mon_next_event); //driver가 신호를 다 실었다고 알려줄 때까지 대기
            trans = new();
            trans.wr = fifo_if.wr;
            trans.rd = fifo_if.rd;
            trans.wdata = fifo_if.wdata;
            trans.rdata = fifo_if.rdata;

            trans.full = fifo_if.full;
            trans.empty = fifo_if.empty;
            
            

            mon2scb_mbox.put(trans); //데이터를 scoreboard로 가는 우편함에 넣기
            trans.print("mon");
        end
    endtask
endclass //monitor

class scoreboard;
    transaction trans;
    mailbox #(transaction) mon2scb_mbox;
    event scb2gen_next_event;

    // logic [7:0] compare_ram [0:15]; //DUT와 똑같은 크기
    // logic [3:0] wptr, rptr; //내가 직접 관리할 포인터

    bit [7:0] scb_queue [$];

    int total_count = 0;
    int pass_count = 0;
    int fail_count = 0;

    function new(mailbox #(transaction) mon2scb_mbox,
                event scb2gen_next_event);
        this.mon2scb_mbox = mon2scb_mbox;
        this.scb2gen_next_event = scb2gen_next_event;
        //포인터 초기화
        // this.wptr = 0;
        // this.rptr = 0;
    endfunction //new()

    // task run();
    //     // //1. 초기화
    //     // for(int i=0; i<16; i++) begin
    //     //     compare_ram[i] = 8'h00;
    //     // end
    //     // wptr = 0;
    //     // rptr = 0;
    //     // $display("[scb] run task start");

    //     scb_queue.delete(); //초기화: 큐 비우기
    //     $display("[scb] run task start");

    //     forever begin
    //         mon2scb_mbox.get(trans);; //모니터가 보낸 데이터를 mailbox를 통해 받기
    //         total_count++;

    //         //Read(pop) 검증 로직
    //         //rd 요청이 왔고, FIFO가 empty가 아니었다면
    //         if(trans.rd == 1'b1 && trans.empty == 1'b0) begin
    //             //비교: 내 메모리의 값 vs 하드웨어 출력값
    //             if(compare_ram[rptr]==trans.rdata) begin
    //                 $display("--->PASS!");
    //                 pass_count++;
    //             end else begin
    //                 $display("--->FAIL!");
    //                 fail_count++;
    //             end
    //             rptr++; //읽기 포인터 증가
    //         end

    //         //Write(push) 검증 로직
    //         //wr 요청이 왔고, FIFO가 꽉 차지 않았다면
    //         if(trans.wr==1'b1 && trans.full==1'b0) begin
    //             compare_ram[wptr] = trans.wdata; //내 메모리에 백업
    //             wptr++; //포인터 증가
    //         end

    //         ->scb2gen_next_event;
    //     end
    // endtask

    task run();
        scb_queue.delete(); 
        $display("[scb] run task start");

        forever begin
            mon2scb_mbox.get(trans);
            total_count++;

            // 1. Read Check
            if(trans.rd == 1'b1 && trans.empty == 1'b0) begin
                if(scb_queue.size() == 0) begin
                     $display("--->FAIL! Queue Empty Error");
                     fail_count++;
                end 
                // 변수 선언 없이 pop_front()를 바로 비교문에 사용
                // pop_front()는 값을 반환함과 동시에 큐에서 삭제합니다.
                else if(scb_queue.pop_front() == trans.rdata) begin
                    $display("--->PASS!");
                    pass_count++;
                end else begin
                    // 이미 pop이 되었으므로 기대값(Expected)은 사라져서 출력할 수 없음
                    $display("--->FAIL! Actual: %d", trans.rdata);
                    fail_count++;
                end
            end

            // 2. Write Check
            if(trans.wr==1'b1 && trans.full==1'b0) begin
                scb_queue.push_back(trans.wdata); 
            end

            ->scb2gen_next_event;
        end
    endtask

endclass //scoreboard

class environment;
    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;

    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;
    
    virtual fifo_interface fifo_if;

    event drv2mon_next_event;
    event scb2gen_next_event;

    function new(virtual fifo_interface fifo_if);
        gen2drv_mbox = new();
        mon2scb_mbox = new();

        gen = new(gen2drv_mbox, scb2gen_next_event);
        drv = new(gen2drv_mbox, fifo_if, drv2mon_next_event);
        mon = new(mon2scb_mbox,fifo_if, drv2mon_next_event);
        scb = new(mon2scb_mbox, scb2gen_next_event);

        this.fifo_if = fifo_if;
    endfunction //new()

    task run();
        drv.reset();
        @(posedge fifo_if.clk);
        fork
            gen.run(100);
            drv.run();
            scb.run();
            mon.run();
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

endclass //environment


module tb_fifo();

    fifo_interface fifo_if();
    environment env;

    fifo dut(
        .clk(fifo_if.clk),
        .reset(fifo_if.reset),
        .wdata(fifo_if.wdata),
        .rdata(fifo_if.rdata),
        .wr(fifo_if.wr),
        .rd(fifo_if.rd),
        .full(fifo_if.full),
        .empty(fifo_if.empty)
    );
    
    always #5 fifo_if.clk = ~fifo_if.clk;

    initial begin
        fifo_if.clk = 0;
        env = new(fifo_if);
        env.run();
        #10;
        $stop;
    end
endmodule