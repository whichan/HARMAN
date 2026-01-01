`timescale 1ns / 1ps

module data_memory(
    input         clk,
    input         d_we,
    input  [ 6:0] daddr, //128byte에 접근해야 하기 때문에 주소는 7bit 필요
                         //data memory는 주소로 접근
    input  [31:0] dwdata,
    output [31:0] drdata
);

    logic [31:0] data_ram [0:127];

    //Write Sequential Logic
    always_ff @( posedge clk ) begin
        if(d_we) begin
            data_ram[daddr] <= dwdata;
        end
    end

    //Read Combinational Logic
    assign drdata = data_ram[daddr];

endmodule