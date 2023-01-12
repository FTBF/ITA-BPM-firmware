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
                       parameter CLOCK_PERIOD = 20, // ns
                       parameter integer C_S_AXI_DATA_WIDTH = 32,
                       parameter integer C_S_AXI_ADDR_WIDTH = 32,
                       parameter integer N_REG = 4

                       )(
                         input wire                                   clk,
                         input wire                                   clk_ps,
                         input wire                                   aresetn,

                         input wire                                   IPIF_clk,
                                                                      
                         //IPIF interface
                         //configuration parameter interface 
                         input logic                                  IPIF_Bus2IP_resetn,
                         input logic [(C_S_AXI_ADDR_WIDTH-1) : 0]     IPIF_Bus2IP_Addr, //unused
                         input logic                                  IPIF_Bus2IP_RNW, //unused
                         input logic [((C_S_AXI_DATA_WIDTH/8)-1) : 0] IPIF_Bus2IP_BE, //unused
                         input logic [0 : 0]                          IPIF_Bus2IP_CS, //unused
                         input logic [N_REG-1 : 0]                    IPIF_Bus2IP_RdCE, 
                         input logic [N_REG-1 : 0]                    IPIF_Bus2IP_WrCE,
                         input logic [(C_S_AXI_DATA_WIDTH-1) : 0]     IPIF_Bus2IP_Data,
                         output logic [(C_S_AXI_DATA_WIDTH-1) : 0]    IPIF_IP2Bus_Data,
                         output logic                                 IPIF_IP2Bus_WrAck,
                         output logic                                 IPIF_IP2Bus_RdAck,
                         output logic                                 IPIF_IP2Bus_Error,
                         
                         // inputs
                         input wire                                   busy,

                         // outputs
                         output reg                                   cnv,
                         output wire [1:0]                            scki,
                         output reg [1:0]                             sdi
                         );


   //decode configuration parameters from IPIF bus 
   assign IPIF_IP2Bus_Error = 0;
   
   typedef struct packed{
      // Register 3
      logic [15:0]           padding3;
      logic [15:0]           n_reads;
      // Register 2
      logic [31:0]           sample_period;
      // Register 1
      logic [12:0]           padding1_2;
      logic [2:0]            range;
      logic [6:0]            padding1_1;
      logic                  mode;
      logic [7:0]            active_channels;
      // Register 0
      logic [30:0]           padding0;
      logic                  reset;
   } param_t;
   
   param_t params_from_IP;
   param_t params_from_bus;
   param_t params_to_IP;
   param_t params_to_bus;
   
   always_comb begin
      params_from_IP = params_to_IP;
      //More efficient to explicitely zero padding 
      params_from_IP.padding3   = '0;
      params_from_IP.padding1_1 = '0;
      params_from_IP.padding1_2 = '0;
      params_from_IP.padding0   = '0;
   end
   
   IPIF_parameterDecode#(
                         .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
                         .N_REG(N_REG),
                         .PARAM_T(param_t),
                         .DEFAULTS({32'h0, 32'd328, 32'hff, 32'b0}),
                         .SELF_RESET(128'b1)
                         ) parameterDecoder (
                         .clk(IPIF_clk),
                         
                         .IPIF_bus2ip_data(IPIF_Bus2IP_Data),  
                         .IPIF_bus2ip_rdce(IPIF_Bus2IP_RdCE),
                         .IPIF_bus2ip_resetn(IPIF_Bus2IP_resetn),
                         .IPIF_bus2ip_wrce(IPIF_Bus2IP_WrCE),
                         .IPIF_ip2bus_data(IPIF_IP2Bus_Data),
                         .IPIF_ip2bus_rdack(IPIF_IP2Bus_RdAck),
                         .IPIF_ip2bus_wrack(IPIF_IP2Bus_WrAck),
                         
                         .parameters_out(params_from_bus),
                         .parameters_in(params_to_bus)
                         );

   IPIF_clock_converter #(
                          .INCLUDE_SYNCHRONIZER(1),
                          .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
                          .N_REG(N_REG),
                          .PARAM_T(param_t)
                          ) IPIF_clock_conv (
                          .IP_clk(clk),
                          .bus_clk(IPIF_clk),
                          .params_from_IP(params_from_IP),
                          .params_from_bus(params_from_bus),
                          .params_to_IP(params_to_IP),
                          .params_to_bus(params_to_bus));

   
   LTC2333_write_impl #(
                        .BUSY_SIGNAL(BUSY_SIGNAL),
                        .BUSY_TIME(BUSY_TIME),
                        .CLOCK_PERIOD(CLOCK_PERIOD),
                        .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
                        .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH),
                        .N_REG(N_REG),
                        .PARAM_T(param_t)
                        ) ltc2333_write_impl(
                          .clk(clk),
                          .clk_ps(clk_ps),
                          .aresetn(aresetn),

                          .IPIF_clk(IPIF_clk),
                          
                          //IPIF interface
                          //configuration parameter interface 
                          .params(params_to_IP),
                          
                          // inputs
                          .busy(busy),

                          // outputs
                          .cnv(cnv),
                          .scki(scki),
                          .sdi(sdi)
                          );

   
endmodule
