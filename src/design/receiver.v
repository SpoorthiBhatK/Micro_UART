`timescale 1ns / 1ps
`include "baud_gen.v"
module receiver #(parameter baud = 2400, parameter dw = 8, parameter clk_freq = 50000000)(
    output reg [dw-1:0] rec_dataH,
    output reg rec_readyH,
    output reg rec_busy,
    input clk,
    input rst,
    input uart_REC_dataH
);
//states
localparam idle  = 2'b00;
localparam start = 2'b01;
localparam data  = 2'b10;
localparam stop  = 2'b11;
////////////////////////////////////////////////////////////
wire baud_clk;
reg [1:0] current_state, next_state;
reg [dw-1:0] rx_data, next_rx_data;
reg [$clog2(dw)-1:0] bit_index, next_bit_index;
reg [3:0] count, next_count;
reg [dw-1:0] next_rec_dataH;
reg next_rec_readyH;
reg next_rec_busy;
reg rx_sync1, rx_sync2;
////////////////////////////////////////////////////////////
baud_gen #(.baud(baud), .clk_freq(clk_freq)) baud_generator (
    .clk(clk),
    .rst(rst),
    .baud_clk(baud_clk)
);
// SYNCHRONIZER
always @(posedge baud_clk or negedge rst)begin
    if(!rst)begin
        rx_sync1 <= 1'b1;  
        rx_sync2 <= 1'b1;
    end
    else begin
        rx_sync1 <= uart_REC_dataH;
        rx_sync2 <= rx_sync1;
    end
end
//current state logic
always @(posedge baud_clk or negedge rst)begin
    if(!rst)begin
        current_state <= idle;
        rec_readyH <= 1'b1;
        rec_busy <= 1'b0;
        rec_dataH <= 0;
        rx_data <= 0;
        bit_index <= 0;
        count <= 0;
    end
    else begin
        current_state <= next_state;
        rec_readyH <= next_rec_readyH;
        rec_busy <= next_rec_busy;
        rec_dataH <= next_rec_dataH;
        rx_data <= next_rx_data;
        bit_index <= next_bit_index;
        count <= next_count;
    end
end
//next state logic
always @(*)begin
    next_state = current_state;
    next_rx_data = rx_data;
    next_bit_index = bit_index;
    next_count = count;
    next_rec_dataH = rec_dataH;
    next_rec_readyH = rec_readyH;
    next_rec_busy = rec_busy;
    
    case(current_state)

    idle:begin
        next_rec_readyH = 1'b1;
        next_rec_busy = 1'b0;
        next_count = 0;
        next_bit_index = 0;
        
        if(rx_sync2 == 1'b0)begin
            next_state = start;
            next_rx_data = 0;
            next_rec_readyH = 1'b0;
            next_rec_busy = 1'b1;
        end
    end
   
    start:begin
        next_rec_readyH = 1'b0;
        next_rec_busy = 1'b1;
        
        if(count == 4'd4)begin
            next_count = 0;
            if(rx_sync2 == 1'b0)
                next_state = data;
            else
                next_state = idle;
        end
        else begin
            next_count = count + 1;
        end
    end
    
    data:begin
        next_rec_readyH = 1'b0;
        next_rec_busy = 1'b1;
       
        if(count == 4'd15) begin
            next_count = 0;
            next_rx_data[bit_index] = rx_sync2;
            if(bit_index == dw-1)begin
                next_state = stop;
                next_bit_index = 0;
            end

            else begin
                next_bit_index = bit_index + 1;
            end
        end
        else
        begin
            next_count = count + 1;
        end
    end
   
    stop:
    begin
        next_rec_readyH = 1'b0;
        next_rec_busy = 1'b1;
        if(count == 4'd15)begin
            next_count = 0;
            if(rx_sync2 == 1'b1)begin
                next_rec_dataH = rx_data;
                next_rec_readyH = 1'b1;
/////////////////////////////////////
		next_state = idle;
                next_rec_busy = 1'b0;
/////////////////////////////////////
            end
            
            if(rx_sync2 == 1'b0)begin
                next_state = start;
                next_rec_busy = 1'b1;
                next_rec_readyH = 1'b0;
            end
            
/*            else begin
                next_state = idle;
                next_rec_busy = 1'b0;
            end
*/
        end
        else begin
            next_count = count + 1;
        end
    end
    endcase
end
endmodule
