`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/19/2022 01:20:15 PM
// Design Name: 
// Module Name: LTC2333-write
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


module LTC2333_write #(
                       parameter BUSY_SIGNAL = 0,
                       parameter BUSY_TIME = 550, // ns
                       parameter CLOCK_PERIOD = 20 // ns
                       )(
                         input wire  clk,
                         input wire  aresetn,
                         // settings

                         // inputs
                         input wire  busy,

                         // outputs
                         output reg  cnv,
                         output wire scki,
                         output reg  sdi
                         );

   parameter NCHAN = 8;
   parameter [7:0] active_channels = 8'h10;
   parameter [15:0] n_reads = 0;
   parameter [2:0] range = 0;
   parameter [31:0] sample_period = 10000;
   parameter [0:0] mode = 1;
   
   typedef enum { RESET, IDLE, BUSY, SEND, DELAY } state_t;

   state_t state;
   logic [7:0]  busy_cnt;
   logic [31:0] delay_cnt;
   logic [3:0]  ctrl_ptr;
   logic [3:0]  ctrl_ptr_resetVal;
   logic [3:0]  next_ctrl_ptr;
   logic [3:0]  n_chan;
   logic [7:0]  ctrl_cnt;
   logic [15:0] n_reads_remaining;
   logic [3:0]  n_chan_remaining;
   logic        clock_enable;
   logic [7:0]  data;
   logic [15:0] busy_delay;
   logic [31:0] sampling_delay;

   assign data = {2'b10, ctrl_ptr[2:0], range};
   assign busy_delay = BUSY_TIME/CLOCK_PERIOD;
   assign sampling_delay = (sample_period - BUSY_TIME)/CLOCK_PERIOD - 28;

   assign scki = clock_enable & ~clk;

   //Calculate next active channel 
   always_comb begin
      n_chan = 0;
      for(int k = 0; k < NCHAN; k += 1) if(active_channels[k]) n_chan += 1;

      if (|active_channels) begin
         int i, j;
         for(i = 1; (i < NCHAN) && (active_channels[(i + ctrl_ptr)%NCHAN] == 0); i += 1);
         next_ctrl_ptr = (ctrl_ptr + i)%NCHAN;
         
         for(j = 0; j < NCHAN && (active_channels[j] == 0); j += 1);
         ctrl_ptr_resetVal = j;
      end else begin
         next_ctrl_ptr = ctrl_ptr + 1;
         ctrl_ptr_resetVal = 0;
      end
   end

   always_ff @(posedge clk or negedge aresetn)
   begin
      if(aresetn == 0)
      begin
         cnv <= 0;
         sdi <= 0;
         busy_cnt <= 0;
         delay_cnt <= 0;
         ctrl_cnt <= 0;
         ctrl_ptr <= 0;
         n_reads_remaining <= 0;
         n_chan_remaining <= 0;
         clock_enable <= 0;
         state <= RESET;
      end
      else
      begin
         case(state)
           RESET:
           begin
              n_reads_remaining <= n_reads;
              n_chan_remaining <= n_chan;
              state <= IDLE;
           end
           
           IDLE:
           begin                
              cnv <= 0;
              sdi <= 0;
              busy_cnt <= 0;
              ctrl_cnt <= 0;
              delay_cnt <= 0;
              ctrl_ptr <= ctrl_ptr_resetVal;
              clock_enable <= 0;
              if(mode == 0)
              begin
                 if(n_reads_remaining > 0)
                 begin
                    n_reads_remaining <= n_reads_remaining - 1;
                    cnv <= 1;
                    state <= BUSY;
                 end
                 else
                 begin
                    state <= IDLE;
                 end
              end
              else
              begin
                 cnv <= 1;
                 state <= BUSY;
              end
           end
           
           BUSY:
           begin
              if(BUSY_SIGNAL)
              begin              
                 if(!busy) state <= SEND;
              end
              else
              begin
                 busy_cnt <= busy_cnt + 1;
                 if(busy_cnt > busy_delay) state <= SEND;
              end
           end
              
           SEND:
           begin
              cnv <= 0;
              clock_enable <= 1;
              ctrl_cnt <= ctrl_cnt + 1;     
              if(n_chan_remaining > 0)
              begin
                 if(ctrl_cnt[2:0] == 7)
                 begin
                    ctrl_ptr <= next_ctrl_ptr;
                    n_chan_remaining <= n_chan_remaining - 1;
                 end
                 sdi <= data[7-ctrl_cnt[2:0]];
              end
              else
              begin
                 sdi <= 0;
                 if(ctrl_cnt >= 24)
                 begin
                    clock_enable <= 0;
                    state <= DELAY;
                 end
              end
           end // case: SEND

           DELAY:
           begin
              clock_enable <= 0;
              delay_cnt <= delay_cnt + 1;
              if(delay_cnt >= sampling_delay) state <= IDLE;
           end
           
         endcase // case (state)
      end
      
   end
   
   
endmodule
