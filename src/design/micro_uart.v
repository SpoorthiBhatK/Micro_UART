`timescale 1ns / 1ps
`include "transmitter.v"
`include "receiver.v"
module micro_uart #(parameter baud = 2400, parameter dw = 8, parameter clk_freq = 50000000)(
    output uart_XMIT_dataH,
    output xmit_doneH,
    output xmit_active,
    output [dw-1:0]rec_dataH,
    output rec_readyH,
    output rec_busy,
    input xmitH,
    input [dw-1:0]xmit_dataH,
    input sys_clk,
    input sys_rst_l,
    input uart_REC_dataH
);
//Transmitter
transmitter #(.baud(baud), .dw(dw), .clk_freq(clk_freq)) Tx (
    .uart_XMIT_dataH(uart_XMIT_dataH),
    .xmit_doneH(xmit_doneH),
    .xmit_active(xmit_active),
    .clk(sys_clk),
    .rst(sys_rst_l),
    .xmitH(xmitH),
    .xmit_dataH(xmit_dataH)
);

//Receiver
receiver #(.baud(baud), .dw(dw), .clk_freq(clk_freq)) Rx (
    .rec_dataH(rec_dataH),
    .rec_readyH(rec_readyH),
    .rec_busy(rec_busy),
    .clk(sys_clk),
    .rst(sys_rst_l),
    .uart_REC_dataH(uart_REC_dataH)
);

endmodule
