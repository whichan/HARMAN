`timescale 1ns / 1ps

module tb_ram();

    logic clk;
    logic [9:0] addr;
    logic [7:0] wdata;
    logic we;
    wire [7:0] rdata;

    ram u_ram(
        .clk(clk),
        .addr(addr),
        .wdata(wdata),
        .we(we),
        .rdata(rdata)
    );

    initial begin
        clk=0;
        forever #5 clk=~clk;
    end

    initial begin
        #0;
        we=0;
        
        #10;
        we=1;
        addr=10;
        wdata=1;

        #10;
        addr=11;
        wdata=2;

        #10
        addr=31;
        wdata=3;

        #10
        addr=32;
        wdata=4;

        #10
        we=0;
        addr=10;
        #10
        addr=11;
        #10
        addr=31;
        #10
        addr=32;
        #100;
        
        $stop;

    end

endmodule
