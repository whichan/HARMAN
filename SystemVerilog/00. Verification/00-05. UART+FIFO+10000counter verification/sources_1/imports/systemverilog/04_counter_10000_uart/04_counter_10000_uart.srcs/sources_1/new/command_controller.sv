`timescale 1ns / 1ps

module command_controller(
    input clk,
    input reset,
    
    input mode,
    input run_stop,
    input clear,
    
    output logic o_mode,
    output logic o_run_stop,
    output logic o_clear
    );

    typedef enum logic [1:0] {S_IDLE, S_UP, S_STOP, S_DOWN} STATE_T;
    
    STATE_T state, next_state;
    
    logic c_mode, n_mode;
    logic c_run_stop, n_run_stop;
    logic c_clear, n_clear;
    
    assign o_mode = c_mode;
    assign o_run_stop = c_run_stop;
    assign o_clear = c_clear;

    always_ff @( posedge clk or posedge reset ) begin
        if(reset) begin
            state <= S_IDLE;
            c_mode <= 0;
            c_run_stop <= 0;
            c_clear <= 1;
        end else begin
            state <= next_state;
            c_mode <= n_mode;
            c_run_stop <= n_run_stop;
            c_clear <= n_clear;
        end
    end

    always_comb begin
        next_state  = state;
        n_mode = c_mode;
        n_run_stop = c_run_stop;
        n_clear = c_clear;
        
        case(state)
            S_IDLE: begin
                n_mode = 0;
                n_run_stop = 0;
                n_clear = 1;
                if(clear) next_state = S_IDLE;
                else if(run_stop && !mode) next_state = S_UP;
                else if(run_stop && mode) next_state = S_DOWN;
                else next_state = S_IDLE;
            end

            S_UP: begin
                n_mode = 0;
                n_run_stop = 1;
                n_clear = 0;
                if(clear) next_state = S_IDLE;
                else if(run_stop && mode) next_state = S_DOWN;
                else if(!run_stop) next_state = S_STOP;
                else next_state = S_UP;
            end

            S_DOWN: begin
                n_mode = 1;
                n_run_stop = 1;
                n_clear = 0;
                if(clear) next_state = S_IDLE;
                else if(!mode && run_stop) next_state = S_UP;
                else if(!run_stop) next_state = S_STOP;
                else next_state = S_DOWN;
            end

            S_STOP: begin
                n_mode = c_mode; //기존 모드 유지: up하다 멈췄는지 down하다 멈췄는지?
                n_run_stop = 0;
                n_clear = 0;
                if(clear) next_state = S_IDLE;
                else if(run_stop && !mode) next_state = S_UP;
                else if(run_stop && mode) next_state = S_DOWN;
                else next_state = S_STOP;
            end

            default: next_state = S_IDLE;
        endcase
        
    end

endmodule

/*`timescale 1ns / 1ps

module command_controller(
    input clk,
    input reset,
    input mode,      // 1-cycle Pulse
    input run_stop,  // 1-cycle Pulse
    input clear,     // 1-cycle Pulse
    
    output logic o_mode,
    output logic o_run_stop,
    output logic o_clear
    );

    typedef enum logic [1:0] {S_IDLE, S_RUN, S_STOP} STATE_T;
    STATE_T state, next_state;
    
    // 방향(Mode)은 상태가 아니라 '설정값'이므로 따로 저장해야 합니다.
    logic r_direction; // 0: UP, 1: DOWN
    logic n_direction;

    // 출력 연결
    assign o_mode = r_direction; // 저장된 방향을 출력
    
    // FSM 상태에 따라 o_run_stop 출력 결정
    // S_RUN일 때만 1, 나머지는 0
    assign o_run_stop = (state == S_RUN); 
    
    // Clear는 IDLE 상태에서 눌렸을 때나 별도 처리 (여기서는 FSM 제어에 맡김)
    assign o_clear = (state == S_IDLE) ? clear : 1'b0; 
    // 혹은 단순하게 o_clear = clear; 로 직접 내보내도 되지만, 
    // top_counter 로직에 따라 맞춰줍니다. 기존 코드는 IDLE일 때 clear 1이었음.
    // 하지만 보통 clear 버튼을 누를 때 clear 신호가 나가는 게 맞습니다.
    // 여기서는 님이 짠 로직(IDLE일 때 n_clear=1)을 최대한 존중하되, 
    // 보통 카운터 clear는 펄스로 주는 게 맞아서 아래처럼 수정합니다.
    // -> 수정: o_clear는 그냥 clear 버튼 누르면 나가도록 단순화.


    // ====================================================
    // 1. Sequential Logic (FF)
    // ====================================================
    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            state <= S_IDLE;
            r_direction <= 0; // 기본 UP
        end else begin
            state <= next_state;
            r_direction <= n_direction;
        end
    end

    // ====================================================
    // 2. Combinational Logic (Next State & Logic)
    // ====================================================
    always_comb begin
        // Latch 방지를 위한 기본값 설정
        next_state = state;
        n_direction = r_direction; // 방향 유지

        // [Mode 버튼 처리]
        // 어떤 상태에 있든 Mode 버튼을 누르면 방향을 뒤집는다.
        // (필요하다면 IDLE이나 STOP 상태에서만 바뀌게 if문을 감싸도 됨)
        if (mode) begin
            n_direction = ~r_direction; 
        end

        // [FSM 상태 전이]
        case(state)
            S_IDLE: begin
                // o_run_stop = 0
                if(clear) begin
                    next_state = S_IDLE;
                end
                else if(run_stop) begin
                    next_state = S_RUN; // 펄스가 들어오면 RUN으로 이동
                end
            end

            S_RUN: begin
                // o_run_stop = 1 (assign 문에 의해)
                
                if(clear) begin
                    next_state = S_IDLE; // 동작 중 Clear 누르면 초기화
                end
                else if(run_stop) begin
                    next_state = S_STOP; // 펄스가 들어오면 STOP으로 이동 (Toggle)
                end
            end

            S_STOP: begin
                // o_run_stop = 0
                
                if(clear) begin
                    next_state = S_IDLE;
                end
                else if(run_stop) begin
                    next_state = S_RUN; // 펄스가 들어오면 다시 RUN (이때 방향은 r_direction 따름)
                end
            end
            
            default: next_state = S_IDLE;
        endcase
    end
    
    // o_clear 로직 별도 정리 (FSM 복잡도 줄임)
    // clear 버튼이 들어오거나, IDLE 상태 진입 시 필요하다면 처리
    // 기존 로직의 의도(IDLE에서 초기화)를 살려:
    assign o_clear = clear; 

endmodule*/