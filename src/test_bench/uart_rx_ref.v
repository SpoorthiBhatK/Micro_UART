`timescale 1ns / 1ps

module uart_rx_ref #(parameter N = 8)(

    input  wire baud_clk,
    input  wire sys_rst_l,
    input  wire uart_REC_dataH,

    output reg  [N-1:0] rec_dataH,
    output reg  rec_readyH,
    output reg  rec_busy

);

//----------------------------------------------------------
// STATES
//----------------------------------------------------------

localparam idle  = 2'b00;
localparam start = 2'b01;
localparam data  = 2'b10;
localparam stop  = 2'b11;

//----------------------------------------------------------
// INTERNAL SIGNALS
//----------------------------------------------------------

reg [1:0] current_state;

reg [N-1:0] rx_data;

reg [$clog2(N)-1:0] bit_index;

reg [4:0] count;

//----------------------------------------------------------
// SYNCHRONIZER
//----------------------------------------------------------

reg rx_sync1, rx_sync2;

//----------------------------------------------------------
// SYNCHRONIZER
//----------------------------------------------------------

always @(posedge baud_clk or negedge sys_rst_l) begin

    if(!sys_rst_l) begin

        rx_sync1 <= 1'b1;
        rx_sync2 <= 1'b1;

    end

    else begin

        rx_sync1 <= uart_REC_dataH;
        rx_sync2 <= rx_sync1;

    end

end

//----------------------------------------------------------
// RECEIVER FSM
//----------------------------------------------------------

always @(posedge baud_clk or negedge sys_rst_l) begin

    //------------------------------------------------------
    // RESET
    //------------------------------------------------------

    if(!sys_rst_l) begin

        current_state <= idle;

        rec_dataH <= 0;

        rec_readyH <= 1'b1;

        rec_busy <= 1'b0;

        rx_data <= 0;

        bit_index <= 0;

        count <= 0;

    end

    //------------------------------------------------------
    // FSM
    //------------------------------------------------------

    else begin

        case(current_state)

        //--------------------------------------------------
        // IDLE
        //--------------------------------------------------

        idle: begin

            rec_readyH <= 1'b1;

            rec_busy <= 1'b0;

            count <= 0;

            bit_index <= 0;

            if(rx_sync2 == 1'b0) begin

                current_state <= start;

                rx_data <= 0;

                rec_readyH <= 1'b0;

                rec_busy <= 1'b1;

            end

        end

        //--------------------------------------------------
        // START
        //--------------------------------------------------

        start: begin

            rec_readyH <= 1'b0;

            rec_busy <= 1'b1;

            //------------------------------------------------
            // MATCH DUT START TIMING
            //------------------------------------------------

            if(count == 4'd4) begin

                count <= 0;

                if(rx_sync2 == 1'b0)

                    current_state <= data;

                else

                    current_state <= idle;

            end

            else begin

                count <= count + 1;

            end

        end

        //--------------------------------------------------
        // DATA
        //--------------------------------------------------

        data: begin

            rec_readyH <= 1'b0;

            rec_busy <= 1'b1;

            //------------------------------------------------
            // MATCH DUT DATA TIMING
            //------------------------------------------------

            if(count == 4'd15) begin

                count <= 0;

                rx_data[bit_index] <= rx_sync2;

                if(bit_index == N-1) begin

                    current_state <= stop;

                    bit_index <= 0;

                end

                else begin

                    bit_index <= bit_index + 1;

                end

            end

            else begin

                count <= count + 1;

            end

        end

        //--------------------------------------------------
        // STOP
        //--------------------------------------------------

        stop: begin

            rec_readyH <= 1'b0;

            rec_busy <= 1'b1;

            //------------------------------------------------
            // MATCH DUT STOP TIMING
            //------------------------------------------------

            if(count == 4'd15) begin

                count <= 0;

                //--------------------------------------------
                // VALID STOP BIT
                //--------------------------------------------

                if(rx_sync2 == 1'b1) begin

                    rec_dataH <= rx_data;

                    rec_readyH <= 1'b1;

                end

                //--------------------------------------------
                // BACK TO BACK
                //--------------------------------------------

                if(rx_sync2 == 1'b0) begin

                    current_state <= start;

                    rec_busy <= 1'b1;

                    rec_readyH <= 1'b0;

                end

                //--------------------------------------------
                // RETURN TO IDLE
                //--------------------------------------------

                else begin

                    current_state <= idle;

                    rec_busy <= 1'b0;

                end

            end

            else begin

                count <= count + 1;

            end

        end

        endcase

    end

end

endmodule
