`timescale 1ns / 1ps
`include "baud_gen.v"
module transmitter #(parameter baud = 2400, parameter dw = 8, parameter clk_freq = 50000000)(
    input wire clk,
    input wire rst,
    input wire xmitH,
    input wire [dw-1:0] xmit_dataH,
    output reg uart_XMIT_dataH,
    output reg xmit_doneH,
    output reg xmit_active
);

//States
localparam idle  = 2'b00;
localparam start = 2'b01;
localparam data  = 2'b10;
localparam stop  = 2'b11;
///////////////////////////////////////////////////////
wire baud_clk;                      //baud clk(Slower than sys clk)
reg [1:0] st, next_st;              //st= currenstate, next_state
reg [dw-1:0] temp, next_temp;       //store data in current state and nextstate
reg [$clog2(dw)-1:0] bit_count, next_bit_count; //count transmitted bits in current state and next state
reg [3:0] samp, next_samp;          //Keep count of samples of a data transmitted in current state and next state

//baud gen instantiation
baud_gen #(.baud(baud), .clk_freq(clk_freq)) baud_generator (
    .clk(clk),
    .rst(rst),
    .baud_clk(baud_clk)
);

//Current State Logic
always @(posedge baud_clk or negedge rst)begin
    if(!rst)begin
        st <= idle;
        uart_XMIT_dataH <= 1;
        xmit_doneH <= 1;
        xmit_active <= 0;
        temp <= 0;
        bit_count <= 0;
        samp <= 0;
    end
    else begin
        st <= next_st;
        temp <= next_temp;
        bit_count <= next_bit_count;
        samp <= next_samp;
    end
end
//Next State Logic
always @(*)begin
    next_st = st;
    next_temp = temp;
    next_bit_count = bit_count;
    next_samp = samp;
    uart_XMIT_dataH = 1;
    xmit_doneH = 1;
    xmit_active = 0;

    case(st)
    idle:begin
        uart_XMIT_dataH = 1;
        xmit_doneH = 1;
        xmit_active = 0;
        next_samp = 0;
        next_bit_count = 0;
        if(xmitH)begin
            next_st = start;
            next_temp = xmit_dataH;
        end
    end

    start:begin
        uart_XMIT_dataH = 0;
        xmit_doneH = 0;
        xmit_active = 1;
        if(samp == 4'd15)begin
            next_samp = 0;
            next_st = data;
        end
        else begin
            next_samp = samp + 1;
        end
    end

    data:begin
        uart_XMIT_dataH = temp[0];
        xmit_doneH = 0;
        xmit_active = 1;
        if(samp == 4'd15)begin
            next_samp = 0;
            next_temp = temp >> 1;
            if(bit_count == dw-1)begin
                next_st = stop;
                next_bit_count = 0;
            end
            else begin
                next_bit_count = bit_count + 1;
            end
        end
        else begin
            next_samp = samp + 1;
        end
    end
   
    stop:begin
        uart_XMIT_dataH = 1;
        if(samp == 4'd15)
        begin
            next_samp = 0;
            if(xmitH)begin
                next_st = start;
                next_temp = xmit_dataH;
                xmit_doneH = 1;
                xmit_active = 1;
            end
            else begin
                next_st = idle;
                xmit_doneH = 1;
                xmit_active = 0;
            end
        end
        else begin
            next_samp = samp + 1;
            xmit_doneH = 0;
            xmit_active = 1;
        end
    end
    endcase
end
endmodule
