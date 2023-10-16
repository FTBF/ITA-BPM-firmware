`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/31/2022 01:28:36 PM
// Design Name: 
// Module Name: LTC2358_digitalModel
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


module LTC2333_digitalModel #(
                              parameter [23:0] DATA = 24'habcdef
                              )(
                            input logic  cnv,
                            input logic  scki,
                            input logic  sdi,
                            output logic busy,
                            output logic scko = 0,
                            output logic sdo = 0
                            );
   
   logic  internal_clk = 0;
   always
     begin
        #10 internal_clk <= ~internal_clk;        
     end
     
   logic  internal_clk2 = 0;
   always
     begin
        #1 internal_clk2 <= ~internal_clk2;        
     end
    
    logic scko_l = 0;
    logic [7:0] scko_sr = 0;
    always @(posedge internal_clk2)
    begin
        scko_sr[0] <= scko_l;
        scko_sr[7:1] <= scko_sr[6:0];
        scko <= scko_sr[7];
    end
       

   logic [7:0] busy_count = 25;
   always @(posedge internal_clk)
   begin
      if(busy_count < 25)
      begin
         busy <= 1;
         busy_count <= busy_count + 1;
      end
      else
      begin
         busy <= 0;
      end
   end // always @ (posedge internal_clk)

   // bad sim only nonsense 
   always @(posedge cnv)
   begin
      busy_count <= 0;
   end
   

   logic [3:0] cmd_ptr = 0;
   
   // recieve logic
   logic [2:0] recv_bit_cnt = 7;
   logic [3:0] recv_byte_cnt = 0;
   logic [7:0] buffer [15:0] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
   logic       reset = 0;
   logic       write_byte = 0;
   logic       change = 0;
   IDDRE1 #(
            .DDR_CLK_EDGE("OPPOSITE_EDGE"), // IDDRE1 mode (OPPOSITE_EDGE, SAME_EDGE, SAME_EDGE_PIPELINED)
            .IS_CB_INVERTED(1'b1),          // Optional inversion for CB
            .IS_C_INVERTED(1'b0)            // Optional inversion for C
            )
   IDDRE1_inst (
                .Q1(Q1), // 1-bit output: Registered parallel output 1
                .Q2(Q2), // 1-bit output: Registered parallel output 2
                .C(scki),   // 1-bit input: High-speed clock
                .CB(scki), // 1-bit input: Inversion of High-speed clock C
                .D(D),   // 1-bit input: Serial Data Input
                .R(R)    // 1-bit input: Active High Async Reset
                );
   always @(posedge scki or negedge scki or posedge busy)
     begin
        if(busy)
          begin
             reset <= 1;
             recv_bit_cnt <= 7;
             recv_byte_cnt <= 0;
             write_byte = 0;
             change <= 0;
          end
        else
          begin
             recv_bit_cnt <= recv_bit_cnt - 1;
             if(recv_bit_cnt == 7 && recv_byte_cnt == 0 && reset == 1 && sdi == 1)
               begin
                  for(int i = 0; i < 16; i += 1)
                    begin
                       buffer[i] = 0;
                    end
                  reset <= 0;
                  change <= 1;
               end
             if(recv_bit_cnt == 7)
               begin
                  if(sdi == 1) write_byte = 1;
                  else         write_byte = 0;
               end
             if(write_byte) buffer[recv_byte_cnt][recv_bit_cnt] <= sdi;
             if(recv_bit_cnt == 0) recv_byte_cnt <= recv_byte_cnt + 1;
             
          end
     end // always @ (posedge scki or posedge busy)

   // output logic
   logic [4:0] output_bit_cnt = 0;
   logic [3:0] next_cmd_ptr;

   always_comb
     begin
        if(buffer[0][7] == 0) next_cmd_ptr <= 0;
        else
          begin
             if(buffer[cmd_ptr + 1][7]) next_cmd_ptr = cmd_ptr + 1;
             else                       next_cmd_ptr = 0;
          end
     end
         

   logic [7:0] current_cmd;
   always @(posedge scki or negedge scki or posedge busy)
     begin
        if(busy)
          begin
             scko_l <= 0;
             output_bit_cnt <= 23;
             if(change) cmd_ptr = 0;
             else       cmd_ptr = next_cmd_ptr;
             current_cmd <= buffer[cmd_ptr];
          end
        else
          begin
             scko_l <= !scko_l;
        
             if(output_bit_cnt > 0) output_bit_cnt <= output_bit_cnt - 1;
             else                   output_bit_cnt <= 23;

             if(output_bit_cnt >= 6) sdo <= DATA[output_bit_cnt];
             else                    sdo <= current_cmd[output_bit_cnt];
          end
     end // always @ (posedge scki or posedge busy)

   
   
   
endmodule
