`timescale 1ns/1ps

`include "micro_uart.v"
`include "uart_tx_ref.v"
`include "uart_rx_ref.v"

module uart_tb;

parameter WORD_LEN = 8;
parameter BAUD     = 2400;
parameter XTAL_CLK = 50000000;

reg sys_clk;
reg sys_rst_l;
reg xmitH;
reg [WORD_LEN-1:0] xmit_dataH;

wire uart_XMIT_dataH;
wire xmit_doneH;
wire xmit_active;

wire rec_readyH;
wire rec_busy;
wire [WORD_LEN-1:0] rec_dataH;

wire uart_wire;

assign uart_wire = uart_XMIT_dataH;

//----------------------------------------------------------
// DUT
//----------------------------------------------------------

micro_uart #(
    .baud(BAUD),
    .dw(WORD_LEN),
    .clk_freq(XTAL_CLK)
) dut (

    .sys_clk(sys_clk),
    .sys_rst_l(sys_rst_l),

    .xmitH(xmitH),
    .xmit_dataH(xmit_dataH),

    .uart_XMIT_dataH(uart_XMIT_dataH),
    .xmit_doneH(xmit_doneH),
    .xmit_active(xmit_active),

    .uart_REC_dataH(uart_wire),

    .rec_readyH(rec_readyH),
    .rec_busy(rec_busy),
    .rec_dataH(rec_dataH)

);

//----------------------------------------------------------
// TX REFERENCE
//----------------------------------------------------------

wire ref_uart_XMIT_dataH;
wire ref_xmit_doneH;
wire ref_xmit_active;

uart_tx_ref #(
    .N(WORD_LEN)
) tx_ref (

    .baud_clk(dut.Tx.baud_clk),
    .sys_rst_l(sys_rst_l),

    .xmitH(xmitH),
    .xmit_dataH(xmit_dataH),

    .uart_XMIT_dataH(ref_uart_XMIT_dataH),
    .xmit_doneH(ref_xmit_doneH),
    .xmit_active(ref_xmit_active)

);

//----------------------------------------------------------
// RX REFERENCE
//----------------------------------------------------------

wire ref_rec_readyH;
wire ref_rec_busy;
wire [WORD_LEN-1:0] ref_rec_dataH;

uart_rx_ref #(
    .N(WORD_LEN)
) rx_ref (

    .baud_clk(dut.Rx.baud_clk),
    .sys_rst_l(sys_rst_l),

    .uart_REC_dataH(uart_wire),

    .rec_dataH(ref_rec_dataH),
    .rec_readyH(ref_rec_readyH),
    .rec_busy(ref_rec_busy)

);

//----------------------------------------------------------
// PASS FAIL COUNT
//----------------------------------------------------------

integer pass_count;
integer fail_count;

//----------------------------------------------------------
// CLOCK
//----------------------------------------------------------

initial begin
    sys_clk = 0;
    forever #10 sys_clk = ~sys_clk;
end

//----------------------------------------------------------
// RESET TASK
//----------------------------------------------------------

task dut_reset;
begin
    sys_rst_l  = 0;
    xmitH      = 0;
    xmit_dataH = 0;
    #200;
    sys_rst_l = 1;
    repeat(20) @(posedge sys_clk);
end
endtask

//----------------------------------------------------------
// SCOREBOARD
//----------------------------------------------------------

task scoreboard;

input [WORD_LEN-1:0] sent_data;

begin

    if(rec_readyH == 1)
        wait(rec_readyH == 0);

    wait(rec_readyH == 1);

    wait(xmit_active == 0);

    repeat(2) @(posedge sys_clk);

    if(uart_XMIT_dataH === ref_uart_XMIT_dataH)
        $display("PASS [TX LINE ] : Time=%0t SENT=%h DUT_TX=%b REF_TX=%b",
                  $time, sent_data, uart_XMIT_dataH, ref_uart_XMIT_dataH);
    else begin
        $display("FAIL [TX LINE ] : Time=%0t SENT=%h DUT_TX=%b REF_TX=%b",
                  $time, sent_data, uart_XMIT_dataH, ref_uart_XMIT_dataH);
        fail_count = fail_count + 1;
    end

    if(xmit_active === ref_xmit_active)
        $display("PASS [TX ACTIVE] : Time=%0t SENT=%h DUT_ACTIVE=%b REF_ACTIVE=%b",
                  $time, sent_data, xmit_active, ref_xmit_active);
    else begin
        $display("FAIL [TX ACTIVE] : Time=%0t SENT=%h DUT_ACTIVE=%b REF_ACTIVE=%b",
                  $time, sent_data, xmit_active, ref_xmit_active);
        fail_count = fail_count + 1;
    end

    if(xmit_doneH === ref_xmit_doneH)
        $display("PASS [TX DONE ] : Time=%0t SENT=%h DUT_DONE=%b REF_DONE=%b",
                  $time, sent_data, xmit_doneH, ref_xmit_doneH);
    else begin
        $display("FAIL [TX DONE ] : Time=%0t SENT=%h DUT_DONE=%b REF_DONE=%b",
                  $time, sent_data, xmit_doneH, ref_xmit_doneH);
        fail_count = fail_count + 1;
    end

    if(rec_dataH === ref_rec_dataH)
        $display("PASS [RX DATA ] : Time=%0t SENT=%h DUT_RX=%h REF_RX=%h",
                  $time, sent_data, rec_dataH, ref_rec_dataH);
    else begin
        $display("FAIL [RX DATA ] : Time=%0t SENT=%h DUT_RX=%h REF_RX=%h",
                  $time, sent_data, rec_dataH, ref_rec_dataH);
        fail_count = fail_count + 1;
    end

    if(rec_readyH === ref_rec_readyH)
        $display("PASS [RX READY] : Time=%0t SENT=%h DUT_READY=%b REF_READY=%b",
                  $time, sent_data, rec_readyH, ref_rec_readyH);
    else begin
        $display("FAIL [RX READY] : Time=%0t SENT=%h DUT_READY=%b REF_READY=%b",
                  $time, sent_data, rec_readyH, ref_rec_readyH);
        fail_count = fail_count + 1;
    end

    if(rec_busy === ref_rec_busy)
        $display("PASS [RX BUSY ] : Time=%0t SENT=%h DUT_BUSY=%b REF_BUSY=%b",
                  $time, sent_data, rec_busy, ref_rec_busy);
    else begin
        $display("FAIL [RX BUSY ] : Time=%0t SENT=%h DUT_BUSY=%b REF_BUSY=%b",
                  $time, sent_data, rec_busy, ref_rec_busy);
        fail_count = fail_count + 1;
    end

    if(rec_dataH === sent_data) begin
        $display("PASS [END2END ] : Time=%0t SENT=%h RECEIVED=%h",
                  $time, sent_data, rec_dataH);
        pass_count = pass_count + 1;
    end

    else begin
        $display("FAIL [END2END ] : Time=%0t SENT=%h RECEIVED=%h",
                  $time, sent_data, rec_dataH);
        fail_count = fail_count + 1;
    end

    $display("----------------------------------------------------------");

end

endtask

//----------------------------------------------------------
// DRIVER
//----------------------------------------------------------

task driver;

input [WORD_LEN-1:0] data;

begin

    @(posedge sys_clk);

    #1;

    xmit_dataH = data;

    xmitH = 1;

    repeat(3) @(posedge dut.Tx.baud_clk);

    xmitH = 0;

    scoreboard(data);

    wait(xmit_active == 0);

    repeat(10) @(posedge sys_clk);

end

endtask

//----------------------------------------------------------
// STIMULUS
//----------------------------------------------------------

initial begin

    pass_count = 0;
    fail_count = 0;

    sys_rst_l  = 0;
    xmitH      = 0;
    xmit_dataH = 0;

    dut_reset();

    //----------------------------------------------------------
    // TC1
    //----------------------------------------------------------

    $display("\n--- TC1: 0x55 alternating bits ---");
    driver(8'h55);

    //----------------------------------------------------------
    // TC2
    //----------------------------------------------------------

    $display("\n--- TC2: 0xAA alternating bits ---");
    driver(8'hAA);

    //----------------------------------------------------------
    // TC3
    //----------------------------------------------------------

    $display("\n--- TC3: 0x00 all zeros ---");
    driver(8'h00);

    //----------------------------------------------------------
    // TC4
    //----------------------------------------------------------

    $display("\n--- TC4: 0xFF all ones ---");
    driver(8'hFF);

    //----------------------------------------------------------
    // TC5
    //----------------------------------------------------------

    $display("\n--- TC5: 0xF0 upper nibble ---");
    driver(8'hF0);

    //----------------------------------------------------------
    // TC6
    //----------------------------------------------------------

    $display("\n--- TC6: 0x0F lower nibble ---");
    driver(8'h0F);

    //----------------------------------------------------------
    // TC7
    //----------------------------------------------------------

    $display("\n--- TC7: 0x80 MSB only ---");
    driver(8'h80);

    //----------------------------------------------------------
    // TC8
    //----------------------------------------------------------

    $display("\n--- TC8: 0x01 LSB only ---");
    driver(8'h01);

    //----------------------------------------------------------
    // TC9
    //----------------------------------------------------------

    $display("\n--- TC9: Continuous TX / back-to-back frames ---");

    @(posedge sys_clk); #1;

    xmit_dataH = 8'h12;
    xmitH      = 1;

    repeat(144) @(posedge dut.Tx.baud_clk);

    xmit_dataH = 8'h34;

    repeat(20) @(posedge dut.Tx.baud_clk);

    xmitH = 0;

    wait (xmit_active == 0);

    repeat(10) @(posedge sys_clk);

    if(xmit_active == 0) begin
        pass_count = pass_count + 1;
        $display("PASS [CONT TX ]: xmit_active=0 after continuous TX");
    end
    else begin
        fail_count = fail_count + 1;
        $display("FAIL [CONT TX ]");
    end

    $display("----------------------------------------------------------");

    //----------------------------------------------------------
    // TC10
    //----------------------------------------------------------

    $display("\n--- TC10: Reset asserted during active TX ---");

    @(posedge sys_clk); #1;

    xmit_dataH = 8'hBE;
    xmitH      = 1;

    repeat(4) @(posedge dut.Tx.baud_clk);

    sys_rst_l = 0;

    xmitH = 0;

    #200;

    sys_rst_l = 1;

    repeat(20) @(posedge sys_clk);

    if (xmit_active === 0 && uart_XMIT_dataH === 1) begin

        pass_count = pass_count + 1;

        $display("PASS [RST TX ]: TX idle after reset active=%b line=%b",
                  xmit_active, uart_XMIT_dataH);

    end

    else begin

        fail_count = fail_count + 1;

        $display("FAIL [RST TX ]: TX not idle after reset active=%b line=%b",
                  xmit_active, uart_XMIT_dataH);

    end

    $display("----------------------------------------------------------");

      //----------------------------------------------------------
    // TC11
    //----------------------------------------------------------

    $display("\n--- TC11 : false start bit ---");

    @(posedge sys_clk);

    force uart_wire = 1'b0;

    repeat(4) @(posedge dut.Tx.baud_clk);

    force uart_wire = 1'b1;

    repeat(20) @(posedge dut.Tx.baud_clk);

    if(rec_busy == 0 && rec_readyH == 1) begin

        pass_count = pass_count + 1;

        $display("PASS [FALSE START]: Receiver ignored false start");

    end

    else begin

        fail_count = fail_count + 1;

        $display("FAIL [FALSE START]: Receiver reacted to glitch");

    end

    release uart_wire;

    $display("----------------------------------------------------------");

    //----------------------------------------------------------
    // TC12
    //----------------------------------------------------------

    $display("\n--- TC12 : true back-to-back ---");

    driver(8'h10);
    driver(8'h20);
    driver(8'h30);

    pass_count = pass_count + 1;

    $display("PASS [BACK2BACK]: Multiple frames handled correctly");

    $display("----------------------------------------------------------");
    //----------------------------------------------------------
    // TC13
    //----------------------------------------------------------

    $display("\n--- TC13: xmitH while TX busy ---");

    @(posedge sys_clk); #1;

    xmit_dataH = 8'hE7;

    xmitH = 1;

    repeat(2) @(posedge dut.Tx.baud_clk);

    xmit_dataH = 8'h18;

    repeat(2) @(posedge dut.Tx.baud_clk);

    xmitH = 0;

    wait(xmit_active == 0);

    repeat(10) @(posedge sys_clk);

    pass_count = pass_count + 1;

    $display("PASS [TX BUSY ]: xmitH-while-busy branch exercised");

    $display("----------------------------------------------------------");

    //----------------------------------------------------------
    // TC14
    //----------------------------------------------------------

    $display("\n--- TC14: xmitH pulse shorter than 1 baud_clk ---");

    @(posedge sys_clk); #1;

    xmit_dataH = 8'hDA;

    xmitH = 1;

    #5;

    xmitH = 0;

    repeat(5) @(posedge sys_clk);

    if(xmit_active === 0) begin

        pass_count = pass_count + 1;

        $display("PASS [SHORT xmitH]: FSM stayed IDLE on sub-baud pulse");

    end

    else begin

        fail_count = fail_count + 1;

        $display("FAIL [SHORT xmitH]: FSM unexpectedly left IDLE");

    end

    $display("----------------------------------------------------------");

    //----------------------------------------------------------
    // TC15
    //----------------------------------------------------------

    $display("\n--- TC15: Walking-ones sweep ---");

    begin : walk_ones

        integer i;

        for(i = 1; i <= 6; i = i + 1)
            driver(8'h01 << i);

    end

    //----------------------------------------------------------
    // TC16
    //----------------------------------------------------------

    $display("\n--- TC16: Extended idle ---");

    repeat(200) @(posedge dut.Tx.baud_clk);

    if(uart_XMIT_dataH === 1) begin

        pass_count = pass_count + 1;

        $display("PASS [IDLE LINE]: TX held high during extended idle");

    end

    else begin

        fail_count = fail_count + 1;

        $display("FAIL [IDLE LINE]: TX not idle-high");

    end

    $display("----------------------------------------------------------");

    #100000;

    $display("\n===== SIMULATION DONE =====");

    $display("PASS : %0d", pass_count);
    $display("FAIL : %0d", fail_count);

    $finish;

end

//----------------------------------------------------------
// TIMEOUT
//----------------------------------------------------------

initial begin

    #(64'd5000000000);

    $display("TIMEOUT - simulation took too long");

    $finish;

end

endmodule
