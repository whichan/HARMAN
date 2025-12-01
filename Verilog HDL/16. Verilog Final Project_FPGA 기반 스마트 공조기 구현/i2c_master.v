`timescale 1ns / 1ps

module i2c_master(
    input clk,              // 100MHz
    input reset,
    input start,            // 전송 시작 신호
    input dc,               // 0: Command, 1: Data
    input [7:0] data,       // 전송할 데이터
    input send,             // 데이터 전송 요청
    output reg done,        // 전송 완료
    output scl,
    inout sda
);

    // 타이밍 설정 (200kHz I2C)
    localparam TICKS_PER_STATE = 500;
    
    reg [15:0] tick_cnt;
    reg tick;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tick_cnt <= 0;
            tick <= 0;
        end else begin
            if (tick_cnt == TICKS_PER_STATE - 1) begin
                tick_cnt <= 0;
                tick <= 1;
            end else begin
                tick_cnt <= tick_cnt + 1;
                tick <= 0;
            end
        end
    end
    
    // I2C 신호 제어
    reg scl_reg;
    reg sda_out;
    reg sda_oe;
    
    assign scl = scl_reg;
    assign sda = sda_oe ? sda_out : 1'bz;
    
    // 상태 머신
    localparam ST_IDLE   = 4'd0;
    localparam ST_START1 = 4'd1;
    localparam ST_START2 = 4'd2;
    localparam ST_START3 = 4'd3;
    localparam ST_BIT0   = 4'd4;
    localparam ST_BIT1   = 4'd5;
    localparam ST_ACK0   = 4'd6;
    localparam ST_ACK1   = 4'd7;
    localparam ST_STOP1  = 4'd8;
    localparam ST_STOP2  = 4'd9;
    localparam ST_STOP3  = 4'd10;
    localparam ST_DONE   = 4'd11;
    
    reg [3:0] state;
    reg [7:0] cur_byte;
    reg [2:0] bit_idx;
    reg [1:0] byte_cnt;  // 0: Addr, 1: Control, 2: Data
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= ST_IDLE;
            scl_reg <= 1;
            sda_out <= 1;
            sda_oe <= 1;
            done <= 0;
            cur_byte <= 0;
            bit_idx <= 7;
            byte_cnt <= 0;
        end else if (tick) begin
            case (state)
                ST_IDLE: begin
                    scl_reg <= 1;
                    sda_out <= 1;
                    sda_oe <= 1;
                    done <= 0;
                    
                    if (start) begin
                        byte_cnt <= 0;
                        cur_byte <= 8'h78;  // SSD1306 I2C Address
                        bit_idx <= 7;
                        state <= ST_START1;
                    end
                end
                
                // START Condition
                ST_START1: begin
                    scl_reg <= 1;
                    sda_out <= 1;
                    sda_oe <= 1;
                    state <= ST_START2;
                end
                
                ST_START2: begin
                    scl_reg <= 1;
                    sda_out <= 0;
                    sda_oe <= 1;
                    state <= ST_START3;
                end
                
                ST_START3: begin
                    scl_reg <= 0;
                    sda_out <= 0;
                    sda_oe <= 1;
                    state <= ST_BIT0;
                end
                
                // Data Bit Transmission
                ST_BIT0: begin
                    scl_reg <= 0;
                    sda_out <= cur_byte[bit_idx];
                    sda_oe <= 1;
                    state <= ST_BIT1;
                end
                
                ST_BIT1: begin
                    scl_reg <= 1;
                    if (bit_idx == 0) begin
                        state <= ST_ACK0;
                    end else begin
                        bit_idx <= bit_idx - 1;
                        state <= ST_BIT0;
                    end
                end
                
                // ACK
                ST_ACK0: begin
                    scl_reg <= 0;
                    sda_oe <= 0;  // Release SDA
                    state <= ST_ACK1;
                end
                
                ST_ACK1: begin
                    scl_reg <= 1;
                    
                    if (byte_cnt == 0) begin
                        // Address 전송 완료 -> Control byte
                        byte_cnt <= 1;
                        cur_byte <= dc ? 8'h40 : 8'h80;  // Co=1, D/C=dc
                        bit_idx <= 7;
                        state <= ST_BIT0;
                    end else if (byte_cnt == 1) begin
                        // Control byte 전송 완료 -> Data byte
                        byte_cnt <= 2;
                        cur_byte <= data;
                        bit_idx <= 7;
                        state <= ST_BIT0;
                    end else begin
                        // 모든 바이트 전송 완료 -> STOP
                        state <= ST_STOP1;
                    end
                end
                
                // STOP Condition
                ST_STOP1: begin
                    scl_reg <= 0;
                    sda_out <= 0;
                    sda_oe <= 1;
                    state <= ST_STOP2;
                end
                
                ST_STOP2: begin
                    scl_reg <= 1;
                    sda_out <= 0;
                    sda_oe <= 1;
                    state <= ST_STOP3;
                end
                
                ST_STOP3: begin
                    scl_reg <= 1;
                    sda_out <= 1;
                    sda_oe <= 1;
                    state <= ST_DONE;
                end
                
                ST_DONE: begin
                    done <= 1;
                    if (!send) begin  // send 신호가 내려가면 IDLE로
                        state <= ST_IDLE;
                        done <= 0;
                    end
                end
                
                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule