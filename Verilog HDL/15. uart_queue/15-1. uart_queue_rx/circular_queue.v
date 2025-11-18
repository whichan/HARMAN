`timescale 1ns / 1ps

module circular_queue #(
    parameter DATA_WIDTH = 8, //1개의 데이터 비트 수 (UART = 8)
    parameter DEPTH = 64, //저장 가능한 바이트 수
    parameter ADDR_WIDTH = $clog2(DEPTH) //depth에 필요한 주소 비트 수
) (
    input clk,
    input reset,
    input wr_en,
    input [DATA_WIDTH-1:0] wr_data,
    input rd_en,
    output [DATA_WIDTH-1:0] rd_data,
    output full,
    output empty
    );

    // ========== 내부 레지스터 ========== //

    // 1. 데이터 저장을 위한 메모리
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    //2. 포인터 (쓰기/읽기 주소)
    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;

    //3. 카운터 (Full/Empty 판별용)
    reg [ADDR_WIDTH:0] counter;
    

    // ========== 출력 로직 ========== //

    //1. 큐 상태
    assign empty = (counter == 0);
    assign full = (counter == DEPTH);

    //2. 읽기 데이터
    assign rd_data = mem[rd_ptr];

    // ========== Sequential Logic ========== //
    always @(posedge clk or posedge reset) begin
        if(reset) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            counter <= 0;
        end else begin
            //동시 쓰기/읽기
            if(wr_en && !full && rd_en && !empty) begin
                mem[wr_ptr] <= wr_data; //
                wr_ptr <= wr_ptr + 1'b1; //
                rd_ptr <= rd_ptr + 1'b1;
                counter <= counter;
            end else if(wr_en && !full) begin
            //쓰기만
                mem[wr_ptr] <= wr_data;
                wr_ptr <= wr_ptr + 1'b1;
                counter <= counter + 1'b1;
            end else if(rd_en && !empty) begin
            //읽기만
                rd_ptr <= rd_ptr + 1'b1;
                counter <= counter - 1'b1;
            end
        end
    end

endmodule