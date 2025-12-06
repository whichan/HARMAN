`timescale 1ns / 1ps

module tb_command_controller();

    logic clk;
    logic reset;
    logic mode;
    logic run_stop;
    logic clear;

    logic o_mode;
    logic o_run_stop;
    logic o_clear;

    // DUT 인스턴스
    command_controller u_command_controller(
        .clk(clk),
        .reset(reset),
        .mode(mode),
        .run_stop(run_stop),
        .clear(clear),
        .o_mode(o_mode),
        .o_run_stop(o_run_stop),
        .o_clear(o_clear)
    );

    // 100MHz Clock (Period 10ns)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        // 0. 초기화
        reset = 1;
        mode = 0;
        run_stop = 0;
        clear = 0; 
        
        #20; // 리셋 풀기
        reset = 0;
        $display("--- Simulation Start ---");

        // ---------------------------------------------------------
        // 1. [Normal Op] IDLE -> UP 동작 확인
        // ---------------------------------------------------------
        @(posedge clk); #1; // 클럭 엣지 직후에 입력 인가
        run_stop = 1; // Run!
        mode = 0;     // Up!
        
        repeat(5) @(posedge clk); // 5클럭 동안 상태 유지
        // [예상 결과] o_run_stop=1, o_mode=0

        // ---------------------------------------------------------
        // 2. [Normal Op] 동작 중 Mode 변경 (UP -> DOWN)
        // ---------------------------------------------------------
        @(posedge clk); #1;
        mode = 1;     // Down! (run_stop은 1 유지)
        
        repeat(5) @(posedge clk);
        // [예상 결과] o_mode가 1로 바뀜

        // ---------------------------------------------------------
        // 3. [Crucial Test] STOP 상태에서의 Memory 기능 (핵심!)
        // ---------------------------------------------------------
        // 먼저 멈춥니다.
        @(posedge clk); #1;
        run_stop = 0; // Stop!
        
        repeat(3) @(posedge clk); // STOP 상태 진입 대기
        
        
        $display("[Test] STOP State: Changing input mode to 0 (Up)...");
        @(posedge clk); #1;
        mode = 0; // 입력은 Up(0)으로 바꿨음!
        
        repeat(3) @(posedge clk);
        // [Check Point 1] 
        // 입력 mode는 0이지만, 출력 o_mode는 여전히 1(Down)을 유지해야 함.
        // FSM이 직전 상태(Down)를 기억하고 있는지 확인!

        // ---------------------------------------------------------
        // 4. [Resume] 다시 Run 했을 때 모드 반영 확인
        // ---------------------------------------------------------
        @(posedge clk); #1;
        run_stop = 1; // 다시 Run! (이때 입력 mode는 0인 상태)
        
        repeat(3) @(posedge clk);
        // [예상 결과] 이제서야 o_mode가 0(Up)으로 바뀜

        // ---------------------------------------------------------
        // 5. [Crucial Test] Priority 기능 (Clear vs Run)
        // ---------------------------------------------------------
        // 현재 Run 상태입니다. (run_stop=1)
        @(posedge clk); #1;
        clear = 1; // Clear 버튼 꾹! (run_stop은 여전히 1)
        
        repeat(3) @(posedge clk);
        // [Check Point 2]
        // 입력 run_stop은 1이지만, 출력 o_run_stop은 0(IDLE)이 되어야 함.
        // Clear가 Run을 이겼는지 확인!

        // 6. 마무리
        clear = 0;
        #50;
        $display("--- Simulation Finish ---");

        #2000
        
        $finish;
    end

endmodule