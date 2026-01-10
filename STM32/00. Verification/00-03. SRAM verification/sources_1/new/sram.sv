`timescale 1ns / 1ps

module sram(
    input clk,
    input [3:0] addr, //4byte buffer이므로 2개의 주소 필요
    input [7:0] wdata, //data는 8bit
    input we,
    output [7:0] rdata
);

    logic [7:0] register_file [0:15]; //data 8bit, size 16byte

    always @(posedge clk) begin
        //write
        if(we) begin
            //clk이 posedge 일 때 wr신호가 1이면 데이터를 레지스터에 저장
            register_file[addr] <= wdata; 
        end
    end

    //읽기동작(조합논리)
    assign rdata = register_file[addr];

endmodule