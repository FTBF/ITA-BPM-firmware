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


module LTC2333_write_impl #(

                       parameter BUSY_SIGNAL = 0,
                       parameter BUSY_TIME = 550, // ns
                       parameter CLOCK_PERIOD = 20, // ns
                       parameter integer C_S_AXI_DATA_WIDTH = 32,
                       parameter integer C_S_AXI_ADDR_WIDTH = 32,
                       parameter integer N_REG = 4,
                       parameter type PARAM_T = logic[N_REG*C_S_AXI_DATA_WIDTH-1:0]
                       )(
                         input wire  clk,
                         input wire  aresetn,

                         input wire  IPIF_clk,
                                                                      
                         //IPIF interface
                         //configuration parameter interface 
                         input PARAM_T params,
                         
                         // inputs
                         input wire  busy,

                         // outputs
                         output reg  cnv,
                         output wire scki,
                         output reg  sdi
                         );


   parameter NCHAN = 8;
   
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
   logic        local_aresetn;

   assign local_aresetn = aresetn && !params.reset;

   //assign data = {2'b10, ctrl_ptr[2:0], params.range};
   //assign busy_delay = BUSY_TIME/CLOCK_PERIOD;
   //assign sampling_delay = (params.sample_period - BUSY_TIME)/CLOCK_PERIOD - 28;

   assign scki = clock_enable & ~clk;

   //Calculate next active channel 
   always_comb begin
      n_chan = 0;
      for(int k = 0; k < NCHAN; k += 1) if(params.active_channels[k]) n_chan += 1;

      if (|params.active_channels) begin
         int i, j;
         for(i = 1; (i < NCHAN) && (params.active_channels[(i + ctrl_ptr)%NCHAN] == 0); i += 1);
         next_ctrl_ptr = (ctrl_ptr + i)%NCHAN;
         
         for(j = 0; j < NCHAN && (params.active_channels[j] == 0); j += 1);
         ctrl_ptr_resetVal = j;
      end else begin
         next_ctrl_ptr = ctrl_ptr + 1;
         ctrl_ptr_resetVal = 0;
      end
   end

   always_ff @(posedge clk or negedge local_aresetn)
   begin
      if(local_aresetn == 0)
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
         busy_delay <= 0;
         sampling_delay <= 0;
         data <= 0;
         state <= RESET;
      end
      else
      begin
         case(state)
           RESET:
           begin
              n_reads_remaining <= params.n_reads;
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
              busy_delay <= BUSY_TIME/CLOCK_PERIOD;
              sampling_delay <= params.sample_period;
              if(params.mode == 0)
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
                 if(!busy)
                 begin
                    data <= {2'b10, ctrl_ptr[2:0], params.range};
                    ctrl_ptr <= next_ctrl_ptr;
                    state <= SEND;
                 end
              end
              else
              begin
                 busy_cnt <= busy_cnt + 1;
                 if(busy_cnt > busy_delay)
                 begin
                    data <= {2'b10, ctrl_ptr[2:0], params.range};
                    ctrl_ptr <= next_ctrl_ptr;
                    state <= SEND;
                 end
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
                    data <= {2'b10, ctrl_ptr[2:0], params.range};
                 end
                 else
                 begin
                    data <= {data[6:0],1'b0};
                 end
                 sdi <= data[7];
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
