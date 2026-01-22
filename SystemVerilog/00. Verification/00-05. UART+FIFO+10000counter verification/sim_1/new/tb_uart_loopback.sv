// `timescale 1ns / 1ps

//      module tb_uart_loopback();

//     // 1. 신호 선언
//     reg clk;
//     reg reset;
//     reg RsRx;    // PC -> FPGA
//     wire RsTx;   // FPGA -> PC

//     wire [7:0] monitor_data;
//     wire monitor_valid;

//     reg [7:0] ext_tx_data;
//     reg ext_tx_start;
//     wire ext_tx_busy;

//     reg sender_active;

//     localparam BIT_TIME = 104167; 

//     // 3. 모듈 연결
//     uart_loopback u_uart_loopback (
//         .clk(clk),
//         .reset(reset),
//         .RsTx(RsTx),
//         .RsRx(RsRx),
//         .monitor_data(monitor_data),
//         .monitor_valid(monitor_valid),
//         .ext_tx_data(ext_tx_data),
//         .ext_tx_start(ext_tx_start),
//         .ext_tx_busy(ext_tx_busy),
//         .sender_active(sender_active)
//     );

//     task send_byte;
//         input [7:0] data;
//         integer i;
//         begin
//             // 1. Start Bit (Low)
//             RsRx = 0;
//             #(BIT_TIME); 

//             // 2. Data Bits (8bit, LSB First)
//             for (i=0; i<8; i=i+1) begin
//                 RsRx = data[i];
//                 #(BIT_TIME);
//             end

//             // 3. Stop Bit (High)
//             RsRx = 1;
//             #(BIT_TIME);
//         end
//     endtask

//     // 4. 클럭 생성 (100MHz)
//     initial begin
//         clk=0;
//         forever  #5 clk=~clk;
//     end

//     initial begin
//         #0;
//         reset = 1;
//         RsRx = 1; // Idle
//         ext_tx_start = 0;
//         ext_tx_data = 0;
//         sender_active = 0;
        
//         #10;
//         reset = 0;
//         #100;


//         // [1] 공백 (Space)
//         send_byte(" "); 
//         #(BIT_TIME * 2); // 글자 사이에 약간의 여유(Inter-byte delay)를 줌

//         // [2] /
//         send_byte("/");
//         #(BIT_TIME * 2);

//         // [3] s
//         send_byte("s");
//         #(BIT_TIME * 2);

//         // [4] e
//         send_byte("e");
//         #(BIT_TIME * 2);

//         // [5] t
//         send_byte("t");
//         #(BIT_TIME * 2);

//         // [6] 공백
//         send_byte(" ");
//         #(BIT_TIME * 2);

//         // [7] 1
//         send_byte("1");
//         #(BIT_TIME * 2);

//         // [8] 2
//         send_byte("2");
//         #(BIT_TIME * 2);

//         // [9] 3
//         send_byte("3");
//         #(BIT_TIME * 2);

//         // [10] 4
//         send_byte("4");
//         #(BIT_TIME * 2);
        
//         // 모든 데이터가 돌아오길 기다림 (넉넉하게)
//         #(BIT_TIME * 20);
//         $stop;
//     end

//     // initial begin
//     //     // 초기화
//     //     #0;
//     //     reset = 1;
//     //     RsRx = 1; 
//     //     ext_tx_start = 0;
//     //     ext_tx_data = 0;
//     //     sender_active = 0;
        
//     //     #10;
//     //     reset = 0;
//     //     #100;

//     //     // ---------------------------------------------------------
//     //     // 시나리오 1: 기본 Loopback 테스트 (작성하신 부분)
//     //     // ---------------------------------------------------------
//     //     $display("--- [Scenario 1] Normal Loopback Start ---");
//     //     send_byte("/"); 
//     //     #(BIT_TIME * 2);
//     //     send_byte("s");
//     //     #(BIT_TIME * 2);
        
//     //     // ---------------------------------------------------------
//     //     // 시나리오 2: Sender Active에 의한 Blocking 테스트 (핵심!)
//     //     // 상황: 외부 모듈(Sender)이 동작을 시작해서 Loopback을 멈춰야 함
//     //     // ---------------------------------------------------------
//     //     $display("--- [Scenario 2] Blocking Test (sender_active=1) ---");
        
//     //     sender_active = 1; // [중요] Loopback 차단 신호 인가
//     //     $display(">> Sender Active! Loopback should STOP.");

//     //     // 이 데이터('e', 't')는 RX FIFO에는 들어가지만, TX로 나오면 안 됨!
//     //     send_byte("e"); 
//     //     #(BIT_TIME * 2);
//     //     send_byte("t");
//     //     #(BIT_TIME * 2);

//     //     // 파형 확인 포인트: 여기까지 RsTx는 조용해야 합니다.

//     //     sender_active = 0; // 차단 해제
//     //     $display(">> Sender Inactive. Buffered data should come out now.");
        
//     //     // 차단이 풀리면 아까 갇혀있던 'e', 't'가 후다닥 나와야 함
//     //     #(BIT_TIME * 25); 


//     //     // ---------------------------------------------------------
//     //     // 시나리오 3: External TX 끼어들기 테스트
//     //     // 상황: Loopback 중에 긴급 외부 데이터 전송
//     //     // ---------------------------------------------------------
//     //     $display("--- [Scenario 3] External Injection Test ---");
        
//     //     // 외부 데이터 강제 주입
//     //     wait(ext_tx_busy == 0); // TX가 비어있을 때
//     //     @(posedge clk);
//     //     ext_tx_data = "X";      // 긴급 데이터 'X'
//     //     ext_tx_start = 1;
//     //     @(posedge clk);
//     //     ext_tx_start = 0;
        
//     //     #(BIT_TIME * 12); // 전송 완료 대기

//     //     $display("--- All Tests Done ---");
//     //     $stop;
//     // end

// endmodule





`timescale 1ns / 1ps

module tb_uart_loopback();

    // 1. 신호 선언
    reg clk;
    reg reset;
    reg RsRx;    // PC -> FPGA
    wire RsTx;   // FPGA -> PC

    wire [7:0] monitor_data;
    wire monitor_valid;

    reg [7:0] ext_tx_data;
    reg ext_tx_start;
    wire ext_tx_busy;

    reg sender_active;

    // 9600bps 기준 (약 104us)
    localparam BIT_TIME = 104167; 

    // 2. 모듈 연결
    uart_loopback u_uart_loopback (
        .clk(clk),
        .reset(reset),
        .RsTx(RsTx),
        .RsRx(RsRx),
        .monitor_data(monitor_data),
        .monitor_valid(monitor_valid),
        .ext_tx_data(ext_tx_data),
        .ext_tx_start(ext_tx_start),
        .ext_tx_busy(ext_tx_busy),
        .sender_active(sender_active)
    );

    // 3. Helper Task: UART 1바이트 전송
    task send_byte;
        input [7:0] data;
        integer i;
        begin
            // Start Bit (Low)
            RsRx = 0;
            #(BIT_TIME); 

            // Data Bits (LSB First)
            for (i=0; i<8; i=i+1) begin
                RsRx = data[i];
                #(BIT_TIME);
            end

            // Stop Bit (High)
            RsRx = 1;
            #(BIT_TIME);
        end
    endtask

    // 4. 클럭 생성 (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // 5. 메인 시나리오
    integer k; // for loop용 변수

    initial begin
        // 초기화
        #0;
        reset = 1;
        RsRx = 1; // Idle
        ext_tx_start = 0;
        ext_tx_data = 0;
        sender_active = 0;
        
        #10;
        reset = 0;
        #100;

        // ============================================================
        // [시나리오 1] 기본 Loopback Test ("/set 1234")
        // ============================================================
        $display("[Time: %0t] Scenario 1 Start: Basic Loopback", $time);
        
        send_byte(" "); #(BIT_TIME * 2);
        send_byte("/"); #(BIT_TIME * 2);
        send_byte("s"); #(BIT_TIME * 2);
        send_byte("e"); #(BIT_TIME * 2);
        send_byte("t"); #(BIT_TIME * 2);
        send_byte(" "); #(BIT_TIME * 2);
        send_byte("1"); #(BIT_TIME * 2);
        send_byte("2"); #(BIT_TIME * 2);
        send_byte("3"); #(BIT_TIME * 2);
        send_byte("4"); #(BIT_TIME * 2);
        
        // 데이터가 다 나올 때까지 충분히 대기
        #(BIT_TIME * 20);


        // ============================================================
        // [시나리오 2] 차단 기능 테스트 (Blocking Logic)
        // sender_active = 1 이면 UART RX로 들어온 데이터가 UART TX로 나가면 안됨 (FIFO 대기)
        // ============================================================
        $display("[Time: %0t] Scenario 2 Start: Blocking Test (sender_active=1)", $time);

        sender_active = 1; // [차단 ON]
        
        // 'B', 'L' 두 글자를 보냄 -> 하지만 TX로 나오면 안됨!
        send_byte("B"); 
        #(BIT_TIME * 2);
        send_byte("L");
        #(BIT_TIME * 2);

        // 확인 포인트: 여기서 RsTx 파형이 1(Idle)로 가만히 있어야 함
        #(BIT_TIME * 5); 

        $display("[Time: %0t] Releasing Block...", $time);
        sender_active = 0; // [차단 OFF] -> 이제 'B', 'L'이 후다닥 나와야 함
        
        #(BIT_TIME * 25); // 데이터가 나올 시간 확보


        // ============================================================
        // [시나리오 3] 외부 데이터 긴급 전송 (External Injection)
        // Loopback이 쉬고 있을 때 외부 모듈이 데이터를 강제로 보냄
        // ============================================================
        $display("[Time: %0t] Scenario 3 Start: External Injection", $time);

        wait(ext_tx_busy == 0); // TX가 사용중이 아닐 때까지 대기
        
        @(posedge clk);
        ext_tx_data = "u";  // 긴급 데이터 'u'
        ext_tx_start = 1;   // Pulse 발생
        @(posedge clk);
        ext_tx_start = 0;

        #(BIT_TIME * 12); // 전송 완료 대기


        // ============================================================
        // [시나리오 4] FIFO Overflow (Stress Test)
        // 출구를 막아놓고(Blocked), 20바이트를 연속으로 쏟아부음
        // ============================================================
        $display("[Time: %0t] Scenario 4 Start: FIFO Overflow Test", $time);

        sender_active = 1; // 다시 차단

        // 0x30('0') 부터 20개의 데이터를 연속으로 보냄
        for (k = 0; k < 20; k = k + 1) begin
            send_byte(8'h30 + k); // '0', '1', '2' ... 순서대로 전송
            // 딜레이 없이 빡빡하게 보냄 (Stress)
        end

        // 다 보낸 후 차단 해제 -> FIFO에 살아남은 데이터들이 쏟아져 나옴
        #(BIT_TIME * 5);
        sender_active = 0;

        // FIFO 깊이만큼만 데이터가 나오고, 나머지는 잘렸는지 파형으로 확인
        #(BIT_TIME * 250); // 20개가 다 나오려면 시간이 꽤 걸림

        $display("Simulation Finished");
        $stop;
    end
endmodule