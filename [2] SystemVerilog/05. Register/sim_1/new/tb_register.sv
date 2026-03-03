`timescale 1ns / 1ps

module tb_register();

    logic clk;
    logic reset;
    logic [31:0] in;
    bit [31:0] out;

    register u_register(
        .clk(clk),
        .reset(reset),
        .in(in),
        .out(out)
    );

    initial begin
        clk=0;
        forever #5 clk=~clk;
    end

    initial begin
        #0;
        reset=1;
        in=0;


        #10;
        reset=0;
        
        /*#25;
        in=32'h0110_0001;

        #10;
        in=32'h1001_1010;

        #11;
        in=32'h3232_2725;

        #61;
        in=32'h1011_0111;

        #100;
        $stop;*/

        #10;
        //stimulus
        in=32'h1234_0000;
        #10;
        for(int i=0; i<10; i++) begin
            in=32'h1234+0000+i;
            #10;
        end
        $stop;
    end

endmodule