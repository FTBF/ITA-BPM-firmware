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

   logic write_clk = 0;
   logic aresetn = 1;

   always #10 write_clk <= ~write_clk;

   LTC2333_write #(
                   .BUSY_SIGNAL( 0),
                   .BUSY_TIME(550), // ns
                   .CLOCK_PERIOD(20) // ns
                   ) ltc2333_write(
                     .clk(write_clk),
                     .aresetn(aresetn),
                     // settings

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
   
   initial
   begin
      aresetn <= 1;

      #10 aresetn <= 0;
      #100 aresetn <= 1;
   end
   
endmodule
