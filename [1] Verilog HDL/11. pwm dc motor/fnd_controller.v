`timescale 1ns / 1ps

module fnd_display(
    input clock_100Mhz, // 100 Mhz clock source on Basys 3 FPGA
    input reset,
    input [1:0] in1_in2,  // motor direction switch sw[0] sw[1]
    input [3:0] display_number,    
    output [3:0] an,    // anode signals of the 7-segment LED display
    output [6:0] seg,    // cathode patterns of the 7-segment LED display
    output dp
    );

parameter T250_MS = 25000000;
parameter T500_MS = 50000000;
parameter FORWARD =  4'b1010;      // f  
parameter BACKWARD =  4'b1011;     // b


    reg [3:0] LED_BCD;
    reg [26:0] fnd_toggle_counter; 
    reg dis_mode = 1'b1;
    reg [19:0] refresh_counter; // 20-bit for creating 10.5ms refresh period or 380Hz refresh rate
             // the first 2 MSB bits for creating 4 LED-activating signals with 2.6ms digit period
             // bin 0011 1111 1111 1111 1111  <---> dec 262143
    // org wire [1:0] LED_activating_counter; 
    reg  [1:0] LED_activating_counter; 
            // count         0    ->  1  ->  2  ->  3
            // activates    LED1    LED2   LED3   LED4
            // and repeat

    always @(posedge clock_100Mhz)
    begin 
        refresh_counter <= refresh_counter + 1;
        if (fnd_toggle_counter >= 99_999_999) begin
            fnd_toggle_counter <= 0;
            dis_mode <= ~dis_mode;
        end else
            fnd_toggle_counter <= fnd_toggle_counter + 1;
    end 
    // org assign LED_activating_counter = refresh_counter[19:18];
    // anode activating signals for 4 LEDs, digit period of 2.6ms
    // decoder to generate anode signals
    reg dp_toggle = 1'b0;    // toggle per every 1 sec 
    reg r_dp;
    reg [3:0] r_an;
    assign an = r_an;

    always @(*)
    begin
        // org case(LED_activating_counter)
        case(refresh_counter[19:18])
        2'b00: begin
            r_an <= 4'b0111; 
            // activate LED1 and Deactivate LED2, LED3, LED4
            // LED_BCD <= display_number/1000;
            if (dis_mode == 1'b1) begin
                if (in1_in2 == 2'b10)
                    LED_BCD <= FORWARD;
                else if (in1_in2 == 2'b01)
                    LED_BCD <= BACKWARD;
                else LED_BCD <= 0;
            end
                else r_an <= 4'b1111;    // 1'st digit off 
            r_dp <= 1;
            // the first digit of the 16-bit number
              end
        2'b01: begin
            r_an <= 4'b1011; 
            // activate LED2 and Deactivate LED1, LED3, LED4
            LED_BCD = (display_number % 1000)/100;

                // the second digit of the 16-bit number
                // r_dp <= dp_toggle;  // dp toggle every 1 sec
             r_dp <= 1;
            end
        2'b10: begin
            r_an <= 4'b1101; 
            // activate LED3 and Deactivate LED2, LED1, LED4
             LED_BCD <= ((display_number % 1000)%100)/10;
            // the third digit of the 16-bit number
                r_dp <= 1;
                end
        2'b11: begin
            r_an <= 4'b1110; 
            // activate LED4 and Deactivate LED2, LED3, LED1
            LED_BCD <= ((display_number % 1000)%100)%10;
            // the fourth digit of the 16-bit number 
                r_dp <= 1;   
               end
        endcase
    end

    reg [6:0] r_fnd_dis;
    assign seg = r_fnd_dis;
    // assign dp = r_dp;

    // Cathode patterns of the 7-segment LED display 
    always @(*)
    begin
        case(LED_BCD)
        4'b0000: r_fnd_dis <= 7'b0000001; // "0"     
        4'b0001: r_fnd_dis <= 7'b1001111; // "1" 
        4'b0010: r_fnd_dis <= 7'b0010010; // "2" 
        4'b0011: r_fnd_dis <= 7'b0000110; // "3" 
        4'b0100: r_fnd_dis <= 7'b1001100; // "4" 
        4'b0101: r_fnd_dis <= 7'b0100100; // "5" 
        4'b0110: r_fnd_dis <= 7'b0100000; // "6" 
        4'b0111: r_fnd_dis <= 7'b0001111; // "7" 
        4'b1000: r_fnd_dis <= 7'b0000000; // "8"     
        4'b1001: r_fnd_dis <= 7'b0000100; // "9" 
        4'b1010: r_fnd_dis <= 7'b0111000; // "f" 
        4'b1011: r_fnd_dis <= 7'b1100000; // "b"
        default: r_fnd_dis <= 7'b0000001; // "0"
        endcase
    end
endmodule
