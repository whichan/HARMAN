// `timescale 1ns / 1ps

// module uart_controller(
//     input clk,
//     input reset,

//     input [7:0] rx_data,
//     input rx_done,
    
//     output logic uart_run_stop,
//     output logic uart_mode,
//     output logic uart_clear,
//     output logic uart_status,

//     // set 1234 추가
//     output logic [13:0] set_value, //0~9999
//     output logic set_en //set 명령어 완료 pulse
//     );
    
//     localparam ASCII_r = 8'h72; localparam ASCII_R = 8'h52;
//     localparam ASCII_m = 8'h6D; localparam ASCII_M = 8'h4D;
//     localparam ASCII_c = 8'h63; localparam ASCII_C = 8'h43;
//     localparam ASCII_s = 8'h73; localparam ASCII_S = 8'h53;

//     //set 명령어 추가
//     localparam ASCII_SLASH = 8'h2F; // '/'
//     localparam ASCII_e     = 8'h65; // 'e'
//     localparam ASCII_t     = 8'h74; // 't'
//     localparam ASCII_SPACE = 8'h20; // ' '
//     localparam ASCII_0     = 8'h30;
//     localparam ASCII_9     = 8'h39;
//     localparam ASCII_CR    = 8'h0D; // Carriage Return (Enter)
//     localparam ASCII_LF    = 8'h0A; // Line Feed (Enter)

//     typedef enum logic [2:0] {
//         IDLE, 
//         CHECK_S,    
//         CHECK_E, 
//         CHECK_T, 
//         SKIP_SPACE, 
//         GET_NUM
//         } state_t;

//     state_t state;
//     logic [13:0] temp_num;

//     // Clear는 Pulse
//     //assign uart_clear = rx_done && (rx_data == ASCII_C || rx_data == ASCII_c);
//     assign uart_clear  = (state == IDLE) && rx_done && (rx_data == ASCII_C || rx_data == ASCII_c);

//     // status는 pulse
//     //assign uart_status = rx_done && (rx_data == ASCII_S || rx_data == ASCII_s);
//     assign uart_status = (state == IDLE) && rx_done && (rx_data == ASCII_S || rx_data == ASCII_s);


//     // Run/Stop
//     always_ff @( posedge clk or posedge reset ) begin
//         if(reset) begin
//             uart_run_stop <= 0;
//         end else begin
//             if(rx_done && (rx_data == ASCII_R || rx_data == ASCII_r)) begin
//                 uart_run_stop <= ~uart_run_stop;
//             end
//         end
//     end

//     // Mode
//     always_ff @( posedge clk or posedge reset ) begin
//         if(reset) begin
//             uart_mode <= 0;
//         end else begin
//             if(rx_done && (rx_data == ASCII_M || rx_data == ASCII_m)) begin
//                 uart_mode <= ~uart_mode;
//             end
//         end
//     end

//     // typedef enum logic [2:0] {
//     //     IDLE, 
//     //     CHECK_S, 
//     //     CHECK_E, 
//     //     CHECK_T, 
//     //     SKIP_SPACE, 
//     //     GET_NUM
//     //     } state_t;


//         always_ff @(posedge clk or posedge reset) begin
//         if (reset) begin
//             state     <= IDLE;
//             set_value <= 0;
//             set_en    <= 0;
//             temp_num  <= 0;
//         end else begin
//             // Pulse 신호 초기화 (1클럭 뒤 자동으로 꺼짐)
//             set_en <= 0;

//             if (rx_done) begin // 데이터가 들어왔을 때만 동작
//                 case (state)
//                     IDLE: begin
//                         // '/' 문자가 들어오면 파싱 시작
//                         if (rx_data == ASCII_SLASH) begin
//                             state <= CHECK_S;
//                         end
//                     end

//                     CHECK_S: begin
//                         // 's' 가 들어왔는지?
//                         if (rx_data == ASCII_s || rx_data == ASCII_S) state <= CHECK_E;
//                         else if (rx_data == ASCII_SLASH) state <= CHECK_S; // 연속 '/' 입력 대비
//                         else state <= IDLE;
//                     end

//                     CHECK_E: begin
//                         // 'e' 가 들어왔는지?
//                         if (rx_data == ASCII_e) state <= CHECK_T;
//                         else state <= IDLE;
//                     end

//                     CHECK_T: begin
//                         // 't' 가 들어왔는지?
//                         if (rx_data == ASCII_t) state <= SKIP_SPACE;
//                         else state <= IDLE;
//                     end

//                     SKIP_SPACE: begin
//                         // 공백(' ') 처리. 공백이 여러 개여도 넘어갈지, 하나만 체크할지 결정.
//                         // 여기선 공백이 들어오면 바로 숫자 모드로 넘어감
//                         if (rx_data == ASCII_SPACE) begin
//                             state    <= GET_NUM;
//                             temp_num <= 0; // 숫자 누적 변수 초기화
//                         end else begin
//                             state <= IDLE;
//                         end
//                     end

//                     GET_NUM: begin
//                         // 1. 숫자가 들어온 경우 ('0' ~ '9')
//                         if (rx_data >= ASCII_0 && rx_data <= ASCII_9) begin
//                             // 자릿수 올림 (기존값 * 10 + 입력값)
//                             // 예: 1 -> 12 -> 123 -> 1234
//                             temp_num <= (temp_num * 10) + (rx_data - ASCII_0);
//                         end 
//                         // 2. 입력 종료 (Enter 또는 공백) -> 값 전송!
//                         else if (rx_data == ASCII_CR || rx_data == ASCII_LF || rx_data == ASCII_SPACE) begin
//                             set_value <= temp_num; // 최종 계산된 값 출력
//                             set_en    <= 1;        // "값 가져가라!" 신호 발생
//                             state     <= IDLE;     // 처음으로 복귀
//                         end
//                         // 3. 그 외 이상한 문자 -> 취소
//                         else begin
//                             state <= IDLE;
//                         end
//                     end
                    
//                     default: state <= IDLE;
//                 endcase
//             end
//         end
//     end

// endmodule

`timescale 1ns / 1ps

module uart_controller(
    input clk,
    input reset,
    input [7:0] rx_data,
    input rx_done,
 
    output logic uart_run_stop,
    output logic uart_mode,
    output logic uart_clear,
    output logic uart_status,
    // set 1234 추가
    output logic [13:0] set_value, //0~9999
    output logic set_en //set 명령어 완료 pulse
    );
 
    localparam ASCII_r = 8'h72; localparam ASCII_R = 8'h52;
    localparam ASCII_m = 8'h6D; localparam ASCII_M = 8'h4D;
    localparam ASCII_c = 8'h63; localparam ASCII_C = 8'h43;
    localparam ASCII_s = 8'h73; localparam ASCII_S = 8'h53;

    localparam ASCII_SLASH = 8'h2F; // '/'
    localparam ASCII_SPACE = 8'h20; // ' '
    localparam ASCII_CR = 8'h0D; //Enter
    localparam ASCII_LF = 8'h0A; //Enter

    //상태 정의
    typedef enum logic [2:0] {
        IDLE,
        CHECK_S,
        CHECK_E,
        CHECK_T,
        SKIP_SPACE,
        GET_NUM
    } state_t;

    state_t state;
    logic [13:0] temp_num;

    always_ff @( posedge clk or posedge reset ) begin : blockName
        if(reset) begin
            state <= IDLE;
            uart_run_stop <= 0;
            uart_mode <= 0;
            uart_clear <= 0;
            uart_status <= 0;
            set_value <= 0;
            set_en <= 0;
            temp_num <= 0;
        end else begin
            uart_clear <= 0;
            uart_status <= 0;
            set_en <= 0;

            if(rx_done) begin
                case(state)
                    //IDLE 상태에서만 'r', 'm', 'c', 's'가 동작
                    IDLE: begin
                        case(rx_data)
                            ASCII_SLASH: state <= CHECK_S;
                            "r", "R": uart_run_stop <= ~uart_run_stop; //run_stop 토글
                            "m", "M": uart_mode <= ~uart_mode; //mode 토글
                            "c", "C": uart_clear <= 1'b1; //clear 펄스
                            "s", "S": uart_status <= 1'b1; //status 펄스
                            default: state <= IDLE;
                        endcase
                    end

                    //명령어 처리 구간
                    CHECK_S: begin
                        if(rx_data == "s" || rx_data == "S") state <= CHECK_E;
                        else if(rx_data == ASCII_SLASH) state <= CHECK_S;
                        else state <= IDLE; // /다음에 다른문자 입력하면 IDLE로
                    end

                    CHECK_E: begin
                        if (rx_data == "e" || rx_data == "E") state <= CHECK_T;
                        else state <= IDLE; //  /s 다음에 다른 문자 입력하면 IDLE로
                    end

                    CHECK_T: begin
                        if(rx_data == "t" || rx_data == "T") state <= SKIP_SPACE;
                        else state <= IDLE; //  /se 다음에 다른 문자 입력하면 IDLE로
                    end
                    
                    SKIP_SPACE: begin
                        if(rx_data == ASCII_SPACE) begin
                            state <= GET_NUM;
                            temp_num <= 0;
                        end else begin
                            state <= IDLE;
                        end
                    end

                    GET_NUM: begin
                        if(rx_data >= "0" && rx_data <= "9") begin
                            temp_num <= (temp_num)*10 + (rx_data-"0"); //새로운 숫자가 들어올 때마다 기존에 있던 숫자를 왼쪽으로 한자릿수 민다
                                                                       //문자에서 "0"을 빼면 실제 숫자가 됨
                        end else if(rx_data == ASCII_CR || rx_data == ASCII_LF || rx_data == ASCII_SPACE) begin
                            set_value <= temp_num; //'send' 누르면 set_value로 값 반영됨
                            set_en <= 1'b1; //동시에 set_en 1
                            state <= IDLE;
                        end else begin
                            state <= IDLE;
                        end
                    end
                    default: state <= IDLE;
                endcase
            end
        end
    end
endmodule