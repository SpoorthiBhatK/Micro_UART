`timescale 1ns / 1ps
module baud_gen #(parameter baud = 2400, parameter clk_freq = 50000000)(
    output reg baud_clk,
    input clk,
    input rst
);

localparam integer clk_count = clk_freq / (baud * 16 * 2);

reg [$clog2(clk_count)-1:0] counter;

always @(posedge clk or negedge rst)begin
    if(!rst)begin
        counter <= 0;
        baud_clk <= 0;
    end
    else begin
        if(counter == clk_count - 1)begin
            counter <= 0;
            baud_clk <= ~baud_clk;
        end
        else begin
            counter <= counter + 1;
        end
    end
end
endmodule
