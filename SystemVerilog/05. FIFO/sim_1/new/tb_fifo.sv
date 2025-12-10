`timescale 1ns / 1ps

module tb_fifo ();


    reg clk;
    reg reset;
    reg wr;     // push
    reg rd;     // pop
    reg [7:0] wdata;
    wire [7:0] rdata;
    wire full;
    wire empty;

    bit [7:0] stimulus_data;

    fifo u_fifo (
        .clk(clk),
        .reset(reset),
        .wr(wr),     // push
        .rd(rd),     // pop
        .wdata(wdata),
        .rdata(rdata),
        .full(full),
        .empty(empty)
    );

    initial begin
        clk=0;
        forever #5 clk=~clk;
    end

    integer i;

    initial begin
        #0;
        reset = 1;
        wr = 0;
        rd = 0;
        wdata = 0;
        i = 0;
        #10;
        // reset
        reset = 0;

        // push -> full
        #10;
        wr = 1;
        rd = 0;
        for (i = 0; i < 4; i = i + 1) begin
            wdata = i + 8'h10;
            #10;
        end

        // pop -> empty
        #10;
        wr = 0;
        rd = 1;
        for (i = 0; i < 4; i = i + 1) begin
            #10;
        end

        // 1 time push
        wr = 1;
        rd = 0;
        wdata = 8'haa;
        #10;

        // push, pop -> non-empty, non-full
        #10;
        wr = 1;
        rd = 1;
        for (i = 0; i < 10; i = i + 1) begin
            wdata = i + 8'h10;
            if (u_fifo.u_register_file.register_file[0] == 2) begin
                $display("test %x", u_fifo.u_register_file.register_file[0]);
            end
            wdata = i;
            #10;
        end

        #30
        wr=1'b1;
        rd=1'b1;
        for(i=0; i<100; i++) begin
            stimulus_generate();
            wdata=stimulus_data;
            @(posedge clk);
            #10;
        end
        
        wr=0;
        rd=0;

        #50;
        $stop;
    end

    task stimulus_generate();
        stimulus_data = $random()%256;
    endtask

endmodule
