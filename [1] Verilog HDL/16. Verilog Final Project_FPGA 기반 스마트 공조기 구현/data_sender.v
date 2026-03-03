`timescale 1ns / 1ps

module data_sender(
    input clk,
    input reset,
    
    // Control Interface
    input start_trigger,        
    input [2:0] cmd_type,       //  0~3까지 사용
    input [15:0] i_counter_val, 
    input [7:0] i_temp_int,     // 온도 정수부
    input [7:0] i_temp_real,     // 온도 실수부
    input [7:0] i_humi_int,     // 습도 정수부
    input [7:0] i_humi_real,     // 습도 실수부
    
    output reg sender_busy,     
    
    // UART TX Interface
    input tx_busy,              
    input tx_done,              
    output reg tx_start,        
    output reg [7:0] tx_data    
    );

    // ====================================================
    // 1. 내부 파라미터 및 레지스터 정의
    // ====================================================
    parameter S_IDLE    = 3'd0;
    parameter S_PREPARE = 3'd1; 
    parameter S_SEND    = 3'd2; 
    parameter S_WAIT    = 3'd3; 
    parameter S_NEXT    = 3'd4; 

    reg [2:0] state;
    reg [5:0] char_idx;         
    reg [5:0] msg_len;          
    
    // 값 스냅샷용
    reg [15:0] latched_counter; 
    reg [7:0] latched_temp_INT;
    reg [7:0] latched_temp_REAL;
    reg [7:0] latched_humi_INT;
    reg [7:0] latched_humi_REAL;

    
    reg r_trig_prev;
    wire w_trig_pulse;

    // ASCII 변환용 (조합 로직)
    reg [7:0] counter_digit_10000, counter_digit_1000, counter_digit_100, counter_digit_10, counter_digit_1;

    // DHT11 Temp/Humi (8비트 -> 2자리 ASCII)
    reg [7:0] temp_d1000, temp_d100, temp_d10, temp_d1; 
    reg [7:0] humi_d1000, humi_d100, humi_d10, humi_d1; 


    // ====================================================
    // 2. 상승 엣지 검출 (Rising Edge Detector)
    // ====================================================
    always @(posedge clk or posedge reset) begin
        if(reset) r_trig_prev <= 0;
        else      r_trig_prev <= start_trigger;
    end
    assign w_trig_pulse = start_trigger && !r_trig_prev;

    // ====================================================
    // 3. Binary to ASCII 변환 로직 (조합 로직)
    // ====================================================
    always @(*) begin
        // --- 1. Up Counter ---
        latched_counter = latched_counter; 
        
        counter_digit_10000 = (latched_counter / 10000) % 10 + 8'h30;
        counter_digit_1000  = (latched_counter / 1000)  % 10 + 8'h30;
        counter_digit_100   = (latched_counter / 100)   % 10 + 8'h30;
        counter_digit_10    = (latched_counter / 10)    % 10 + 8'h30;
        counter_digit_1     = (latched_counter % 10)         + 8'h30;

        // --- 2. DHT11 Temp/Humi (8비트 -> 2자리) ---
        
        // 온도
        temp_d1000  = (latched_temp_INT / 10) % 10  + 8'h30;    //정수 십 의자리        
        temp_d100 = (latched_temp_INT % 10)         + 8'h30;    //정수 일 의자리
        temp_d10  = (latched_temp_REAL / 10) % 10   + 8'h30;    //실수 십 의자리
        temp_d1 = (latched_temp_REAL & 10)          + 8'h30;    //정수 일 의자리
    
        // 습도 
        humi_d1000 = (latched_humi_INT / 10) % 10 + 8'h30;              //정수   
        humi_d100  = (latched_humi_INT % 10)       + 8'h30;
        humi_d10 = (latched_humi_REAL / 10) % 10 + 8'h30;               //실수
        humi_d1  = (latched_humi_REAL % 10)       + 8'h30;
    end

    // ====================================================
    // 4. Main FSM (Sequential Logic)
    // ====================================================
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            state           <= S_IDLE;
            sender_busy     <= 0;
            tx_start        <= 0;
            tx_data         <= 0;
            char_idx        <= 0;
            msg_len         <= 0;
            latched_counter <= 0;
            latched_temp_INT    <= 0; 
            latched_temp_REAL <=0;
            latched_humi_INT    <= 0; 
            latched_humi_REAL <=0;
        end else begin
            case(state)
                
                S_IDLE: begin
                    tx_start    <= 0;
                    sender_busy <= 0;
                    
                    if(w_trig_pulse) begin
                        sender_busy     <= 1;
                        latched_counter <= i_counter_val; 
                        latched_temp_INT    <= i_temp_int;  //  DHT11 값 캡처
                        latched_temp_REAL <= i_temp_real;//  DHT11 값 캡처
                        latched_humi_INT    <= i_humi_int;  //  DHT11 값 캡처
                        latched_humi_REAL <= i_humi_real;
                        char_idx        <= 0;
                        state           <= S_PREPARE;
                    end
                end

                S_PREPARE: begin
                    case(cmd_type)
                        3'd0: msg_len <= 9;   
                        3'd1: msg_len <= 7;   
                        3'd2: msg_len <= 37;  //  Help 메시지 길이 (CR+LF 포함)
                        3'd3: msg_len <= 15;  //  "H:XX T:YY\r\n" -> 11글자
                        default: msg_len <= 0;
                    endcase
                    state <= S_SEND;
                end

                S_SEND: begin
                    if(!tx_busy) begin
                        tx_start <= 1; 
                        
                        case(cmd_type)
                            // Type 0: myname
                            3'd0: begin
                                case(char_idx)
                                    0: tx_data <= "W"; 1: tx_data <= "h"; 2: tx_data <= "i";
                                    3: tx_data <= "c"; 4: tx_data <= "h"; 5: tx_data <= "a";
                                    6: tx_data <= "n"; 7: tx_data <= 8'h0D; 8: tx_data <= 8'h0A;
                                    default: tx_data <= " ";
                                endcase
                            end

                            // Type 1: Counter 
                            3'd1: begin
                                case(char_idx)
                                    0: tx_data <= counter_digit_10000;
                                    1: tx_data <= counter_digit_1000;
                                    2: tx_data <= counter_digit_100;
                                    3: tx_data <= counter_digit_10;
                                    4: tx_data <= counter_digit_1;
                                    5: tx_data <= 8'h0D; // CR
                                    6: tx_data <= 8'h0A; // LF
                                    default: tx_data <= " ";
                                endcase
                            end

                            // Type 2: Help Msg
                            3'd2: begin
                                // "CMD: led, myname, upcounter\r\n"
                                case(char_idx)
                                    0: tx_data <= "C"; 1: tx_data <= "M"; 2: tx_data <= "D"; 3: tx_data <= ":"; 
                                    4: tx_data <= " "; 5: tx_data <= "l"; 6: tx_data <= "e"; 7: tx_data <= "d";
                                    8: tx_data <= ","; 9: tx_data <= " "; 10:tx_data <= "m"; 11:tx_data <= "y";
                                    12:tx_data <= "n"; 13:tx_data <= "a"; 14:tx_data <= "m"; 15:tx_data <= "e";
                                    16:tx_data <= ","; 17:tx_data <= " "; 18:tx_data <= "u"; 19:tx_data <= "p";
                                    20:tx_data <= "c"; 21:tx_data <= "o"; 22:tx_data <= "u"; 23:tx_data <= "n"; 
                                    24:tx_data <= "t"; 25:tx_data <= "e"; 26:tx_data <= "r"; 27:tx_data <= 8'h0D;
                                    28:tx_data <= 8'h0A; // CR/LF
                                    29: tx_data <= " "; 30: tx_data <= " "; // 메시지 길이 37에 맞추기
                                    31: tx_data <= " "; 32: tx_data <= " ";
                                    33: tx_data <= " "; 34: tx_data <= " ";
                                    35: tx_data <= " "; 36: tx_data <= " ";
                                    default: tx_data <= " ";
                                endcase
                            end

                            // Type 3: Humi & Temp ("H:XX T:YY\r\n")
                            3'd3: begin
                                case(char_idx)
                                    // 습도 (H:XX)
                                    0: tx_data <= "H"; 1: tx_data <= ":"; 
                                    2: tx_data <= humi_d1000; 3: tx_data <= humi_d100;
                                    4: tx_data <="." ; 5: tx_data <= humi_d10;
                                    // 구분자
                                    6: tx_data <= " "; 7: tx_data <= "T"; 8: tx_data <= ":";
                                    // 온도 (T:YY)
                                    9: tx_data <= temp_d1000; 10: tx_data <= temp_d100;
                                    11: tx_data <= "."; 12: tx_data <= temp_d10;
                                    // CR/LF
                                    13: tx_data <= 8'h0D; 14: tx_data <= 8'h0A;
                                    default: tx_data <= " ";
                                endcase
                            end
                        endcase
                        
                        state <= S_WAIT;
                    end
                end
                
                S_WAIT: begin
                    tx_start <= 0; 
                    if(!tx_busy) begin 
                        state <= S_NEXT;
                    end
                end

                S_NEXT: begin
                    if(char_idx == msg_len - 1) begin
                        state       <= S_IDLE; 
                        sender_busy <= 0;      
                    end else begin
                        char_idx <= char_idx + 1;
                        state    <= S_SEND;    
                    end
                end
                
                default: state <= S_IDLE;
            endcase
        end
    end

endmodule