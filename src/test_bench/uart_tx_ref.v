`timescale 1ns/1ps

module uart_tx_ref #(parameter N = 8)(
    input  wire baud_clk,
    input  wire sys_rst_l,
    input  wire xmitH,
    input  wire [N-1:0] xmit_dataH,
    output reg uart_XMIT_dataH,
    output reg xmit_doneH,
    output reg xmit_active
);

reg [N-1:0] tx;
integer i;

always @(negedge sys_rst_l)begin
    uart_XMIT_dataH = 1'b1;
    xmit_doneH = 1'b1;
    xmit_active = 1'b0;
    tx = 0;
end

initial begin
    uart_XMIT_dataH = 1'b1;
    xmit_doneH = 1'b1;
    xmit_active = 1'b0;
    tx = 0;
    
    wait(sys_rst_l == 1);
    
    forever
    begin

        //idle
        uart_XMIT_dataH = 1'b1;
        xmit_doneH = 1'b1;
        xmit_active = 1'b0;   
        
        wait(xmitH == 1);
        xmit_active = 1'b1;
        xmit_doneH = 1'b0;
        tx = xmit_dataH;
        
        //start bit
        uart_XMIT_dataH = 1'b0;
        repeat(16) @(posedge baud_clk);
        
        //data bit
        for(i = 0; i < N; i = i + 1)begin
            uart_XMIT_dataH = tx[0];
            repeat(16) @(posedge baud_clk);
            tx = tx >> 1;
        end
        //stop bit
        uart_XMIT_dataH = 1'b1;
        xmit_doneH = 1'b1;
        xmit_active = 1'b1;
        repeat(16) @(posedge baud_clk);
        
        if(xmitH == 1)begin
            xmit_active = 1'b1;
        end
        else begin
            xmit_active = 1'b0;
        end
    end
end
endmodule
