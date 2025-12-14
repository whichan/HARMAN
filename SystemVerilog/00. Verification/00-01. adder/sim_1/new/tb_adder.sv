`timescale 1ns / 1ps

// random generate stimulus variable
class transaction;
    rand bit [7:0] a; // stimulus 대상이 되는 a, b를 8bit random type으로 만들기
    rand bit [7:0] b;
endclass  //transaction


interface adder_interface;
    logic [7:0] a;
    logic [7:0] b;
    logic [7:0] sum;
    logic       carry;
endinterface //adder_interface


// stimulus generation
class generator;            // 계속 데이터 만들어서 mailbox에 넣어둠. 리소스 많이 먹음 (IPC 통신)

    transaction tr;         // handler. transaction 불러오기 위한 tr 인자. 선언은 했으나 생성 전
    mailbox #(transaction) gen2drv_mbox;

    function new(mailbox #(transaction) gen2drv_mbox_if);                                           
        gen2drv_mbox = gen2drv_mbox_if;
    endfunction  //new()

    task run();
        repeat (100) begin
            // stimulus generation
            tr = new();        
            tr.randomize();
            gen2drv_mbox.put(tr);   // mailbox의 명령어 put  
            #10;
        end
    endtask  //run
endclass  //generator


class drive;                // mailbox에서 데이터 받아서 interface에 넣어줌. 처리 후 메모리 지워짐. 리소스 많이 먹음 (IPC 통신)

    transaction tr_drv;
    virtual adder_interface adder_interf_drv;
    mailbox #(transaction) gen2drv_mbox;

    function new(mailbox #(transaction) gen2drv_mbox_if,
                virtual adder_interface adder_interf);

        adder_interf_drv = adder_interf;
        gen2drv_mbox = gen2drv_mbox_if;
    endfunction

    task run ();
        forever begin    
            // drive
            gen2drv_mbox.get(tr_drv);
            adder_interf_drv.a = tr_drv.a;
            adder_interf_drv.b = tr_drv.b; 
        end
    endtask //run
endclass //drive


class environment;      // 일하라고 얘기하는 애

    //transaction tr;
    generator gen;
    drive     drv;
    mailbox #(transaction) gen2drv_mbox;    // generator to driver. 중간 버퍼 역할.

    function new(virtual adder_interface adder_if_env);     // environment 생성 시 하위 생성
        gen2drv_mbox = new();
        gen = new(gen2drv_mbox);                            // function 생성 시 생성
        drv = new(gen2drv_mbox, adder_if_env);
    endfunction

    task run ();
        fork
            // management time
            gen.run();
            drv.run();
        join_any
    endtask //run
endclass //environment


module tb_adder_verify();

    environment env;

    adder_interface adder_inter_f();  // interface : instanciation

    adder dut (
        .a(adder_inter_f.a),        // adder_inter_f에 연결
        .b(adder_inter_f.b),
        .sum(adder_inter_f.sum),
        .carry(adder_inter_f.carry)
    );

    initial begin
        env = new(adder_inter_f);
        env.run();
        #20;
        $finish;
    end

endmodule




// 분리 전

/*
    virtual adder_interface adder_gen_if;
    // 생성자. 생성될 때 새로 만들어라. 아직 생성 전. 
    function new(virtual adder_interface adder_if);  // virtual로 가상 연결. (하드웨어끼리는) virtual 없이 완전연결. 못 끊음.
                                                     // 이 경우엔 소프트웨어 - 하드웨어 연결이라 무조건 붙여야 함.
        tr = new();         // 이 클래스가 생길 때 tr을 같이 생성해라. memory에 동적 할당
        adder_gen_if = adder_if;

    endfunction  //new()

    task run();
        repeat (100) begin
            // stimulus generation
            tr.randomize();     // rand type 데이터를 랜덤수로 생성. 이미 있는 Class 가져온 것  

            // to connect interface for drive
            adder_gen_if.a = tr.a;
            adder_gen_if.b = tr.b;

            #10;    // drive
        end
    endtask  //run
*/


/*
module tb_adder_verilfi ();

    generator gen;          // handler. 

    adder_interface adder_inter_f();  // interface : instanciation

    adder dut (
        .a(adder_inter_f.a),        // adder_inter_f에 연결
        .b(adder_inter_f.b),
        .sum(adder_inter_f.sum),
        .carry(adder_inter_f.carry)
    );

    initial begin
        gen = new(adder_inter_f);
        gen.run();      // generator task run()
    end

endmodule
*/