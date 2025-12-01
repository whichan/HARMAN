module tick_generator_ds1302(
    input i_clk,        // 100MHz 시스템 클럭
    input i_reset,
    output reg o_tick_1mhz, // 이름은 1mhz지만 실제로는 느린 속도로 쓸 겁니다
    output reg o_tick_1hz,
    output reg o_tick_1khz
);
    // 100MHz / 10000 = 10kHz (안전한 속도)
    localparam CNT_SLOW = 10000; //10khz(통신용)
    localparam CNT_1HZ  = 100_000_000; //1hz(시간용)
    localparam CNT_1KHZ = 100_000; //1khz tick(부저용)

    reg [31:0] cnt_fast;
    reg [31:0] cnt_slow;
    reg [31:0] cnt_1khz;

    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            cnt_fast <= 0;
            o_tick_1mhz <= 0;
            cnt_slow <= 0;
            o_tick_1hz <= 0;
        end else begin
            // 1. 통신용 틱 (10kHz)
            if (cnt_fast >= CNT_SLOW - 1) begin
                cnt_fast <= 0;
                o_tick_1mhz <= 1; 
            end else begin
                cnt_fast <= cnt_fast + 1;
                o_tick_1mhz <= 0;
            end

            // 2. 1초 틱
            if (cnt_slow >= CNT_1HZ - 1) begin
                cnt_slow <= 0;
                o_tick_1hz <= 1;
            end else begin
                cnt_slow <= cnt_slow + 1;
                o_tick_1hz <= 0;
            end

            //3. 1khz 틱
            if(cnt_1khz >= CNT_1KHZ-1) begin
                cnt_1khz <= 0;
                o_tick_1khz <= 1;
            end else begin
                cnt_1khz <= cnt_1khz + 1;
                o_tick_1khz <= 0;
            end
            
        end
    end
endmodule