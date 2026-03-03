`timescale 1ns / 1ps

class transaction;

    typedef enum bit [2:0] {
        OP_R, //'r'
        OP_M, //'m'
        OP_C, //'c'
        OP_S, //'s'
        OP_SET, // '/set숫자'입력하기
        OP_NOISE // 'i'와 같은 다른 문자 입력
    } oper_e;

    rand oper_e oper; //동작 종류 (랜덤)
    rand bit [13:0] set_data; //'/set'할 때 보낼 숫자
    

    logic uart_run_stop;
    logic uart_mode;
    logic uart_clear;
    logic uart_status;

    logic [13:0] set_value;
    logic set_en;

    constraint set_d {set_data <= 9999;}
    constraint c_dist {oper dist {OP_R := 10, OP_M := 10, OP_C := 1, OP_S := 5, 
            OP_SET := 3, OP_NOISE := 3};}

    task print(string name);
        $display("[%t] [%s] OP: %s, InData: %0d | run: %b, mode: %b, clear: %b, status: %b | set_value: %0d, set_enable: %b", 
            $time,              // 현재 시간
            name,               // 누가 출력했는지 (GEN, DRV, MON 등)
            oper.name(),        // 동작 이름 (OP_R, OP_SET 등)
            set_data,           // 입력하려고 만든 숫자
            uart_run_stop,      // 현재 Run/Stop 상태
            uart_mode,          // 현재 Mode 상태
            uart_clear,         // Clear 신호 상태
            uart_status,        // Status 신호 상태
            set_value,          // 설정된 값
            set_en              // 설정 완료 신호
        );
    endtask
endclass

interface uart_controller_interface;
    logic clk;
    logic reset;
    logic [7:0] rx_data;
    logic rx_done;
 
    logic uart_run_stop;
    logic uart_mode;
    logic uart_clear;
    logic uart_status;
    // set 1234 추가
    logic [13:0] set_value; //0~9999
    logic set_en; //set 명령어 완료 pulse
endinterface

class generator;
    transaction trans;
    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) gen2scb_mbox;
    event scb2gen_next_event;

    function new(mailbox #(transaction) gen2drv_mbox,
                mailbox #(transaction) gen2scb_mbox,
                event scb2gen_next_event);
        this.gen2drv_mbox = gen2drv_mbox;
        this.gen2scb_mbox = gen2scb_mbox;
        this.scb2gen_next_event = scb2gen_next_event;
    endfunction

    task run(int count);
        repeat(count) begin
            trans = new();
            trans.randomize();
            gen2drv_mbox.put(trans);
            gen2scb_mbox.put(trans);
            trans.print("gen");
            @(scb2gen_next_event);
        end
    endtask
endclass

class driver;
    transaction trans;
    mailbox #(transaction) gen2drv_mbox;
    virtual uart_controller_interface uartctrl_if;
    event drv2mon_next_event;
    
    function new(mailbox #(transaction) gen2drv_mbox, 
                virtual uart_controller_interface uartctrl_if,
                event drv2mon_next_event);
        this.gen2drv_mbox = gen2drv_mbox;
        this.uartctrl_if = uartctrl_if;
        this.drv2mon_next_event = drv2mon_next_event;
    endfunction

    task reset();
        $display("[drv] reset");
        uartctrl_if.reset <= 1'b1;
        uartctrl_if.rx_done <= 0;
        uartctrl_if.rx_data <= 0;
        repeat (2) @(posedge uartctrl_if.clk);
        uartctrl_if.reset <= 0;
    endtask

    //문자 보내기 task(r,m,c,s)
    task drive_char(input byte data);
        @(posedge uartctrl_if.clk);
        uartctrl_if.rx_data <= data; //입력받은 인자를 넘겨주기
        uartctrl_if.rx_done <= 1; //rx_done pulse
        @(posedge uartctrl_if.clk);
        uartctrl_if.rx_done <= 0; //1클럭 뒤 rx_done = 0;
        repeat(3) @(posedge uartctrl_if.clk);
        //문자 하나 보내고 rx_done pulse
    endtask

    //문자열 보내기 task(/set xxxx)
    task drive_string(input string str);
        integer i; // 반복문용 변수 선언
        // i는 0부터 문자열 길이(str.len()) 직전까지 1씩 증가
        for (i = 0; i < str.len(); i = i + 1) begin
            drive_char(str[i]); // 한 글자씩 보냄
        end
    endtask

    task run();
        string temp_str; // 숫자를 문자로 바꿀 때 쓸 임시 변수
        forever begin
            @(posedge uartctrl_if.clk);
            gen2drv_mbox.get(trans);
            
            // 내용 확인하고 문자 보내기
            case (trans.oper)
                //단순 문자들
                transaction::OP_R:      drive_char("r");
                transaction::OP_M:      drive_char("m");
                transaction::OP_C:      drive_char("c");
                transaction::OP_S:      drive_char("s");
                transaction::OP_NOISE:  drive_char("i"); // 이상한 문자

                // /set xxxx 보내기
                transaction::OP_SET: begin
                    // 1단계: "/set " 보내기
                    drive_string("/set ");

                    // 2단계: 숫자(1234)를 문자열("1234")로 바꿔서 보내기
                    temp_str.itoa(trans.set_data); 
                    drive_string(temp_str);

                    // 3단계: 엔터(Enter, 0x0D) 보내기
                    drive_char(8'h0D); 
                end
            endcase

            // 3. 로그 찍고 끝났다고 알리기
            #1 -> drv2mon_next_event; 
            trans.print("drv");
        end
    endtask
endclass

class monitor;
    transaction trans;
    mailbox #(transaction) mon2scb_mbox;
    event drv2mon_next_event;
    virtual uart_controller_interface uartctrl_if;

    function new(mailbox #(transaction) mon2scb_mbox,
                virtual uart_controller_interface uartctrl_if,
                event drv2mon_next_event);
        this.mon2scb_mbox = mon2scb_mbox;
        this.uartctrl_if = uartctrl_if;
        this.drv2mon_next_event = drv2mon_next_event;
    endfunction

    task run();
        forever begin
            @(drv2mon_next_event);
            @(posedge uartctrl_if.clk);
            trans = new();
            //interface의 값을 읽어서 transaction에 저장
            trans.uart_run_stop = uartctrl_if.uart_run_stop;
            trans.uart_mode = uartctrl_if.uart_mode;
            trans.uart_clear = uartctrl_if.uart_clear;
            trans.uart_status = uartctrl_if.uart_status;
            trans.set_value = uartctrl_if.set_value;
            trans.set_en = uartctrl_if.set_en;
            
            mon2scb_mbox.put(trans);
            trans.print("mon");
        end
    endtask
endclass

class scoreboard;
    transaction trans;

    mailbox #(transaction) gen2scb_mbox;
    mailbox #(transaction) mon2scb_mbox;
    
    event scb2gen_next_event; // 검증 끝났다고 Gen에게 알리는 신호

    int total_count, pass_count, fail_count;

    // 소프트웨어로 똑같이 DUT 흉내
    // DUT의 레지스터 값들을 똑같이 기억하고 있어야 비교가 가능함
    bit ref_run_stop;
    bit ref_mode;
    bit ref_clear;
    bit ref_status;
    bit [13:0] ref_set_value;

    function new(mailbox #(transaction) gen2scb_mbox,
                 mailbox #(transaction) mon2scb_mbox,
                 event scb2gen_next_event);
        this.gen2scb_mbox = gen2scb_mbox;
        this.mon2scb_mbox = mon2scb_mbox;
        this.scb2gen_next_event = scb2gen_next_event;
        
        // 변수 초기화
        total_count = 0; pass_count = 0; fail_count = 0;
        ref_run_stop = 0; ref_mode = 0; ref_clear = 0; ref_status = 0;
        ref_set_value = 0;
    endfunction

    task run();
        transaction gen_trans; // 정답지
        transaction mon_trans; // 답안지
        bit mismatch;          // 틀렸는지 확인하는 플래그

        forever begin
            // 두 곳에서 mail을 다 꺼낼 때까지 기다림
            gen2scb_mbox.get(gen_trans); // Generator가 뭘 보냈는지
            mon2scb_mbox.get(mon_trans); // Monitor가 보낸 결과가 뭔지
            
            total_count++;
            mismatch = 0;

            // [Reference Model] Generator의 의도대로 내 변수(ref_) 업데이트
            // 소프트웨어로 DUT 동작을 미리 계산해보는 단계
            case (gen_trans.oper)
                transaction::OP_R:      ref_run_stop = ~ref_run_stop; // 토글
                transaction::OP_M:      ref_mode     = ~ref_mode;     // 토글
                transaction::OP_C:      ref_clear    = 1;             // Pulse (비교용)
                transaction::OP_S:      ref_status   = 1;             // Pulse
                transaction::OP_NOISE:  ; // 아무 변화 없음
                
                transaction::OP_SET: begin
                    ref_set_value = gen_trans.set_data; // 값 설정
                end
            endcase

            // [Compare] 내 계산(ref) vs 실제 회로 결과(mon) 비교
            // Pulse 신호(clear, status, set_en)는 타이밍 이슈로 단순 비교가 어려울 수 있으나,
            // 여기서는 상태값(run, mode, set_value) 위주로 비교합니다.

            if (ref_run_stop != mon_trans.uart_run_stop) begin
                $display("[SCB] FAIL! Run_Stop mismatch. Exp: %b, Act: %b", ref_run_stop, mon_trans.uart_run_stop);
                mismatch = 1;
            end
            
            if (ref_mode != mon_trans.uart_mode) begin
                $display("[SCB] FAIL! Mode mismatch. Exp: %b, Act: %b", ref_mode, mon_trans.uart_mode);
                mismatch = 1;
            end

            if (ref_set_value != mon_trans.set_value) begin
                $display("[SCB] FAIL! Set_Value mismatch. Exp: %0d, Act: %0d", ref_set_value, mon_trans.set_value);
                mismatch = 1;
            end

            // (4) 결과 집계
            if (mismatch == 0) begin
                pass_count++;
                $display("[SCB] PASS (%0d)", total_count);
            end else begin
                fail_count++;
            end

            // Pulse 신호들은 다음 비교를 위해 0으로 복귀 (DUT 동작 모사)
            ref_clear = 0;
            ref_status = 0;

            // (5) 검증 끝! 다음 거 보내라고 알림
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
    mailbox #(transaction) gen2scb_mbox;
    mailbox #(transaction) mon2scb_mbox;

    virtual uart_controller_interface uartctrl_if;

    event drv2mon_next_event;
    event scb2gen_next_event;

    function new(virtual uart_controller_interface uartctrl_if);
        gen2drv_mbox = new();
        gen2scb_mbox = new();
        mon2scb_mbox = new();

        gen = new(gen2drv_mbox,gen2scb_mbox,scb2gen_next_event);
        drv = new(gen2drv_mbox, uartctrl_if,drv2mon_next_event);
        mon = new(mon2scb_mbox,uartctrl_if,drv2mon_next_event);
        scb = new(gen2scb_mbox,mon2scb_mbox,scb2gen_next_event);

        this.uartctrl_if = uartctrl_if;
    endfunction

    task run();
        drv.reset();
        @(posedge uartctrl_if.clk);
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


module tb_uart_controller_verification();

    uart_controller_interface uartctrl_if();
    environment env;

    uart_controller dut(
        .clk(uartctrl_if.clk),
        .reset(uartctrl_if.reset),
        .rx_data(uartctrl_if.rx_data),
        .rx_done(uartctrl_if.rx_done),
        .uart_run_stop(uartctrl_if.uart_run_stop),
        .uart_mode(uartctrl_if.uart_mode),
        .uart_clear(uartctrl_if.uart_clear),
        .uart_status(uartctrl_if.uart_status),
        
        .set_value(uartctrl_if.set_value),
        .set_en(uartctrl_if.set_en) //set 명령
    );

    always #5 uartctrl_if.clk = ~uartctrl_if.clk;

    initial begin
        uartctrl_if.clk = 0;
        env = new(uartctrl_if);
        env.run();
        #10;
        $stop;
    end
endmodule