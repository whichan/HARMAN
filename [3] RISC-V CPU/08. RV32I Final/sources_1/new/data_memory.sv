`timescale 1ns / 1ps
`include "define.vh"

module data_memory(
    input         clk,
    input         d_we,
    input  [ 6:0] daddr,  //alu_result[6:0]
    input  [ 2:0] funct3, //SW, SB, SH
    input  [31:0] dwdata,
    output [31:0] drdata
    );
    
    //word addressing
    logic [31:0]  data_ram [0:127];
    wire  [ 4:0] byte_div = daddr[6:2]; //하위 2비트를 버림: 나누기4
                                        //ex) 주소 24(011000) -> 6(0110), 즉 6번째 층 선택
    wire  [ 1:0] byte_sel = daddr[1:0]; //한 층(4바이트)에서 몇 번째 칸인지 선택
                                        //ex) 주소 25(011001) -> 01. 즉, 6번째 층의 첫번째 칸 의미

    //write SL
    always_ff @( posedge clk ) begin 
        if(d_we) begin
            case(funct3)
                `SB: begin //8bit
                    case(byte_sel)
                        2'b00: data_ram[byte_div][ 7:0] <= dwdata [7:0];
                        2'b01: data_ram[byte_div][15:8] <= dwdata [7:0];
                        2'b10: data_ram[byte_div][23:16] <= dwdata[7:0];
                        2'b11: data_ram[byte_div][31:24] <= dwdata[7:0];
                    endcase
                end

                `SH: begin //16bit
                    if(byte_sel[1]) begin
                        data_ram[byte_div][31:16] <= dwdata[15:0];
                    end else begin
                        data_ram[byte_div][15:0] <= dwdata [15:0];
                    end
                end
                default: data_ram[byte_div] <= dwdata;
            endcase
        end
    end
    
    //Datapath에서 자르기
    //Read CL
    assign drdata = data_ram[byte_div];
     
endmodule

// `timescale 1ns / 1ps

// module data_memory(
//     input         clk,
//     input         d_we,
//     input         wr_en,
//     input  [ 6:0] daddr,
//     input  [31:0] dwdata,
//     output [31:0] drdata
//     );
    
//     //word addressing
//     logic [31:0] data_ram [0:127];

//     //write SL
//     always_ff @( posedge clk ) begin 
//         if(d_we) begin
//             data_ram[daddr] <= dwdata;
//         end
//     end
    
//     //read CL
//     assign drdata = data_ram[daddr];
    
// endmodule


// `timescale 1ns / 1ps

// module data_mem (
//     input               clk,
//     input               d_we,
//     input  logic [ 8:0] daddr,        // byte address
//     input        [31:0] dwdata,
//     input  logic [ 3:0] byte_enable,    //  실제 사용되는 바이트
//     output       [31:0] drdata  // read -> 출력
// );

//     // byte addressing    

//     logic [6:0] word_addr;
//     logic [1:0] byte_offset;
//     // daddr splitting


//     assign word_addr   = daddr[8:2];    // 몇번째 워드인지
//     assign byte_offset = daddr[1:0];    // 워드 안에서 몇번째 바이트인지
    


//     logic [31:0] data_ram[0:127];
//     // data_ram[i] -> 32bit word 1개


//     // write SL

//     always_ff @(posedge clk) begin
//         if (d_we) begin
//             if (byte_enable[0]) data_ram[daddr][7:0] <= dwdata[7:0];    // byte0
//             if (byte_enable[1]) data_ram[daddr][15:8] <= dwdata[15:8];  // byte1
//             if (byte_enable[2]) data_ram[daddr][23:16] <= dwdata[23:16]; // byte2
//             if (byte_enable[3]) data_ram[daddr][31:24] <= dwdata[31:24]; // byte3
//         end
//     end

//     // read CL
//     assign drdata = data_ram[daddr];


// endmodule