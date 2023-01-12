`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/31/2022 01:20:09 PM
// Design Name: 
// Module Name: testBench
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module testBench(

                 );
   
   logic cnv;
   logic scki;
   logic sdi;
   logic busy;
   logic scko;
   logic sdo;

   localparam integer C_S_AXI_ADDR_WIDTH = 32;
   localparam integer C_S_AXI_DATA_WIDTH = 32;
   localparam integer N_REG = 4;
   
   logic IPIF_clk = 0;
   logic IPIF_Bus2IP_resetn;
   logic [(C_S_AXI_ADDR_WIDTH-1) : 0] IPIF_Bus2IP_Addr; //unused
   logic                              IPIF_Bus2IP_RNW; //unused
   logic [((C_S_AXI_DATA_WIDTH/8)-1) : 0] IPIF_Bus2IP_BE; //unused
   logic [0 : 0]                          IPIF_Bus2IP_CS; //unused
   logic [N_REG-1 : 0]                    IPIF_Bus2IP_RdCE; 
   logic [N_REG-1 : 0]                    IPIF_Bus2IP_WrCE;
   logic [(C_S_AXI_DATA_WIDTH-1) : 0]     IPIF_Bus2IP_Data;
   logic [(C_S_AXI_DATA_WIDTH-1) : 0]     IPIF_IP2Bus_Data;
   logic                                  IPIF_IP2Bus_WrAck;
   logic                                  IPIF_IP2Bus_RdAck;
   logic                                  IPIF_IP2Bus_Error;

   logic                                  IPIF_Bus2IP_read_resetn;
   logic [(C_S_AXI_ADDR_WIDTH-1) : 0]     IPIF_Bus2IP_read_Addr; //unused
   logic                                  IPIF_Bus2IP_read_RNW; //unused
   logic [((C_S_AXI_DATA_WIDTH/8)-1) : 0] IPIF_Bus2IP_read_BE; //unused
   logic [0 : 0]                          IPIF_Bus2IP_read_CS; //unused
   logic [N_REG-1 : 0]                    IPIF_Bus2IP_read_RdCE; 
   logic [N_REG-1 : 0]                    IPIF_Bus2IP_read_WrCE;
   logic [(C_S_AXI_DATA_WIDTH-1) : 0]     IPIF_Bus2IP_read_Data;
   logic [(C_S_AXI_DATA_WIDTH-1) : 0]     IPIF_IP2Bus_read_Data;
   logic                                  IPIF_IP2Bus_read_WrAck;
   logic                                  IPIF_IP2Bus_read_RdAck;
   logic                                  IPIF_IP2Bus_read_Error;

   logic                                  FIFO_clk;
   logic                                  FIFO_rden;
   logic                                  FIFO_notEmpty;
   logic [31:0]                           FIFO_dout;


   logic write_clk = 0;
   logic aresetn = 1;

   always #10 write_clk <= ~write_clk;
   always #5  IPIF_clk <= ~IPIF_clk;

   LTC2333_write #(
                   .BUSY_SIGNAL( 0),
                   .BUSY_TIME(550), // ns
                   .CLOCK_PERIOD(20), // ns
                   .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
                   .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),
                   .N_REG(N_REG)

                   ) ltc2333_write(
                     .clk(write_clk),
                     .aresetn(aresetn),
                     .IPIF_clk(IPIF_clk),
                     // settings
                     .IPIF_Bus2IP_resetn(IPIF_Bus2IP_resetn),
                     .IPIF_Bus2IP_Addr(IPIF_Bus2IP_Addr), //unused
                     .IPIF_Bus2IP_RNW(IPIF_Bus2IP_RNW), //unused
                     .IPIF_Bus2IP_BE(IPIF_Bus2IP_BE), //unused
                     .IPIF_Bus2IP_CS(IPIF_Bus2IP_CS), //unused
                     .IPIF_Bus2IP_RdCE(IPIF_Bus2IP_RdCE), 
                     .IPIF_Bus2IP_WrCE(IPIF_Bus2IP_WrCE),
                     .IPIF_Bus2IP_Data(IPIF_Bus2IP_Data),
                     .IPIF_IP2Bus_Data(IPIF_IP2Bus_Data),
                     .IPIF_IP2Bus_WrAck(IPIF_IP2Bus_WrAck),
                     .IPIF_IP2Bus_RdAck(IPIF_IP2Bus_RdAck),
                     .IPIF_IP2Bus_Error(IPIF_IP2Bus_Error),

                     // inputs
                     .busy(0),

                     // outputs
                     .cnv(cnv),
                     .scki(scki),
                     .sdi(sdi)
                     );

   LTC2333_digitalModel #(
                              .DATA(24'habcdef)
                              ) ltc2333_digitalInterface(
                            .cnv(cnv),
                            .scki(scki),
                            .sdi(sdi),
                            .busy(busy),
                            .scko(scko),
                            .sdo(sdo)
                            );
   
   LTC2333_read
   #(
     .FIFO_MAX_SIZE(4096)
     ) ltc2333_read
   (
    .clk(write_clk),
    .aresetn(aresetn),

    .cnv(cnv),
    .scko(scko),
    .sdo(sdo),

    .IPIF_clk(IPIF_clk),
    .IPIF_Bus2IP_resetn(IPIF_Bus2IP_read_resetn),
    .IPIF_Bus2IP_Addr(  IPIF_Bus2IP_read_Addr), //unused
    .IPIF_Bus2IP_RNW(   IPIF_Bus2IP_read_RNW), //unused
    .IPIF_Bus2IP_BE(    IPIF_Bus2IP_read_BE), //unused
    .IPIF_Bus2IP_CS(    IPIF_Bus2IP_read_CS), //unused
    .IPIF_Bus2IP_RdCE(  IPIF_Bus2IP_read_RdCE), 
    .IPIF_Bus2IP_WrCE(  IPIF_Bus2IP_read_WrCE),
    .IPIF_Bus2IP_Data(  IPIF_Bus2IP_read_Data),
    .IPIF_IP2Bus_Data(  IPIF_IP2Bus_read_Data),
    .IPIF_IP2Bus_WrAck( IPIF_IP2Bus_read_WrAck),
    .IPIF_IP2Bus_RdAck( IPIF_IP2Bus_read_RdAck),
    .IPIF_IP2Bus_Error( IPIF_IP2Bus_read_Error),


    .FIFO_clk(IPIF_clk),
    .FIFO_rden(),
    .FIFO_notEmpty(),
    .FIFO_dout()

    );

   initial
   begin
      IPIF_Bus2IP_read_resetn <= 1;
      IPIF_Bus2IP_read_Addr <= 0; //unused
      IPIF_Bus2IP_read_RNW <= 0; //unused
      IPIF_Bus2IP_read_BE <= 0; //unused
      IPIF_Bus2IP_read_CS <= 0; //unused
      IPIF_Bus2IP_read_RdCE <= 0; 
      IPIF_Bus2IP_read_WrCE <= 0;
      IPIF_Bus2IP_read_Data <= 0;

      #100 IPIF_Bus2IP_read_resetn <= 0;
      #50  IPIF_Bus2IP_read_resetn <= 1;
      #50;
      
      IPIF_Bus2IP_read_RdCE <= 0; 
      IPIF_Bus2IP_read_WrCE <= 1;
      IPIF_Bus2IP_read_Data <= 32'h2;
      #10 IPIF_Bus2IP_read_WrCE <= 0;
      
      
   end
   
   initial
   begin
      aresetn <= 1;
      IPIF_Bus2IP_resetn <= 1;
      IPIF_Bus2IP_Addr <= 0; //unused
      IPIF_Bus2IP_RNW <= 0; //unused
      IPIF_Bus2IP_BE <= 0; //unused
      IPIF_Bus2IP_CS <= 0; //unused
      IPIF_Bus2IP_RdCE <= 0; 
      IPIF_Bus2IP_WrCE <= 0;
      IPIF_Bus2IP_Data <= 0;

      #10 aresetn <= 0;
      IPIF_Bus2IP_resetn <= 0;
      #100 aresetn <= 1;
      IPIF_Bus2IP_resetn <= 1;

      #100;
      IPIF_Bus2IP_RdCE <= 0; 
      IPIF_Bus2IP_WrCE <= 2;
      IPIF_Bus2IP_Data <= 32'h000300ff;
      #10 IPIF_Bus2IP_WrCE <= 0;

      #100;
      IPIF_Bus2IP_RdCE <= 0; 
      IPIF_Bus2IP_WrCE <= 8;
      IPIF_Bus2IP_Data <= 32'd5;
      #10 IPIF_Bus2IP_WrCE <= 0;

      #20000;
      IPIF_Bus2IP_RdCE <= 0; 
      IPIF_Bus2IP_WrCE <= 1;
      IPIF_Bus2IP_Data <= 32'h1;
      #10 IPIF_Bus2IP_WrCE <= 0;
      
   end

   
endmodule
