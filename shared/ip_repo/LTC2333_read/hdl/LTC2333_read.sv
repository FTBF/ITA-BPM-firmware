`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/23/2022 03:47:33 PM
// Design Name: 
// Module Name: LTC2333_read
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


module LTC2333_read
#(
  parameter FIFO_MAX_SIZE = 4096,
  parameter integer C_S_AXI_DATA_WIDTH = 32,
  parameter integer C_S_AXI_ADDR_WIDTH = 32,
  parameter integer N_REG = 4
  )
   (
    input logic                                  clk,
    input logic                                  aresetn,

    input logic                                  timetrig,

    input logic                                  cnv,
    input logic                                  scko,
    input logic                                  sdo,

    output logic                                 time_we, 

    //IPIF interface
    //configuration parameter interface
    input logic                                  IPIF_clk,
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

    input logic                                  FIFO_clk,
    input logic                                  FIFO_rden,
    output logic                                 FIFO_notEmpty,
    output logic [31:0]                          FIFO_dout,

    output logic                                 FIFO_full,
    output logic                                 interrupt,
    input logic                                  FIFO_write_block

    );

   logic [$clog2(FIFO_MAX_SIZE):0] FIFO_rd_count;

   //decode configuration parameters from IPIF bus 
   assign IPIF_IP2Bus_Error = 0;
   
   typedef struct       packed{
      // Register 3
      logic [31:0]      nsum;
      // Register 2
      logic [31:0]      intr_depth;
      // Register 1
      logic [31:0]      fifo_occ;
      // Register 0
      logic [29:0]      padding0;
      logic             enable;
      logic             reset;
   } param_t;
   
   param_t params_from_IP;
   param_t params_from_bus;
   param_t params_to_IP;
   param_t params_to_bus;
   
   always_comb begin
      params_from_IP = params_to_IP;
      //More efficient to explicitely zero padding 
      params_from_IP.padding0   = '0;

      //readback parameters 
      params_from_IP.fifo_occ = FIFO_rd_count;
   end
   
   IPIF_parameterDecode
   #(
     .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
     .N_REG(N_REG),
     .PARAM_T(param_t),
     .DEFAULTS({32'h0, 32'd1, 32'h0, 32'b0}),
     .SELF_RESET(128'b1)
     ) parameterDecoder 
   (
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

   IPIF_clock_converter 
   #(
     .INCLUDE_SYNCHRONIZER(1),
     .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
     .N_REG(N_REG),
     .PARAM_T(param_t)
     ) IPIF_clock_conv 
   (
    .IP_clk(clk),
    .bus_clk(IPIF_clk),
    .params_from_IP(params_from_IP),
    .params_from_bus(params_from_bus),
    .params_to_IP(params_to_IP),
    .params_to_bus(params_to_bus)
    );

   assign interrupt = FIFO_rd_count > params_to_IP.intr_depth;
   
   //SDO is DDR w.r.t. scko
   logic [1:0] sdr_data;
   logic       scko_dly;
   logic       sdo_dly;
   logic       sdo_dly_tmp;

   assign scko_dly = scko;
   IDELAYE2 #(
              .CINVCTRL_SEL("FALSE"),          // Enable dynamic clock inversion (FALSE, TRUE)
              .DELAY_SRC("IDATAIN"),           // Delay input (IDATAIN, DATAIN)
              .HIGH_PERFORMANCE_MODE("FALSE"), // Reduced jitter ("TRUE"), Reduced power ("FALSE")
              .IDELAY_TYPE("FIXED"),           // FIXED, VARIABLE, VAR_LOAD, VAR_LOAD_PIPE
              .IDELAY_VALUE(31),                // Input delay tap setting (0-31)
              .PIPE_SEL("FALSE"),              // Select pipelined mode, FALSE, TRUE
              .REFCLK_FREQUENCY(200.0),        // IDELAYCTRL clock input frequency in MHz (190.0-210.0, 290.0-310.0).
              .SIGNAL_PATTERN("DATA")          // DATA, CLOCK input signal
              )
   IDELAYE2_scko_inst (
                  .CNTVALUEOUT(), // 5-bit output: Counter value output
                  .DATAOUT(sdo_dly_tmp),         // 1-bit output: Delayed data output
                  .C(1'b0),                     // 1-bit input: Clock input
                  .CE(1'b1),                   // 1-bit input: Active high enable increment/decrement input
                  .CINVCTRL(1'b0),       // 1-bit input: Dynamic clock inversion input
                  .CNTVALUEIN(5'b0),   // 5-bit input: Counter value input
                  .DATAIN(1'b0),           // 1-bit input: Internal delay data input
                  .IDATAIN(sdo),         // 1-bit input: Data input from the I/O
                  .INC(1'b0),                 // 1-bit input: Increment / Decrement tap delay input
                  .LD(1'b0),                   // 1-bit input: Load IDELAY_VALUE input
                  .LDPIPEEN(1'b0),       // 1-bit input: Enable PIPELINE register to load data input
                  .REGRST(1'b0)            // 1-bit input: Active-high reset tap-delay input
                  );

   IDELAYE2 #(
              .CINVCTRL_SEL("FALSE"),          // Enable dynamic clock inversion (FALSE, TRUE)
              .DELAY_SRC("DATAIN"),           // Delay input (IDATAIN, DATAIN)
              .HIGH_PERFORMANCE_MODE("FALSE"), // Reduced jitter ("TRUE"), Reduced power ("FALSE")
              .IDELAY_TYPE("FIXED"),           // FIXED, VARIABLE, VAR_LOAD, VAR_LOAD_PIPE
              .IDELAY_VALUE(31),                // Input delay tap setting (0-31)
              .PIPE_SEL("FALSE"),              // Select pipelined mode, FALSE, TRUE
              .REFCLK_FREQUENCY(200.0),        // IDELAYCTRL clock input frequency in MHz (190.0-210.0, 290.0-310.0).
              .SIGNAL_PATTERN("DATA")          // DATA, CLOCK input signal
              )
   IDELAYE2_sdo_inst (
                  .CNTVALUEOUT(), // 5-bit output: Counter value output
                  .DATAOUT(sdo_dly),         // 1-bit output: Delayed data output
                  .C(1'b0),                     // 1-bit input: Clock input
                  .CE(1'b1),                   // 1-bit input: Active high enable increment/decrement input
                  .CINVCTRL(1'b0),       // 1-bit input: Dynamic clock inversion input
                  .CNTVALUEIN(5'b0),   // 5-bit input: Counter value input
                  .DATAIN(sdo_dly_tmp),           // 1-bit input: Internal delay data input
                  .IDATAIN(1'b0),         // 1-bit input: Data input from the I/O
                  .INC(1'b0),                 // 1-bit input: Increment / Decrement tap delay input
                  .LD(1'b0),                   // 1-bit input: Load IDELAY_VALUE input
                  .LDPIPEEN(1'b0),       // 1-bit input: Enable PIPELINE register to load data input
                  .REGRST(1'b0)            // 1-bit input: Active-high reset tap-delay input
                  );
   
   IDDR #(
      .DDR_CLK_EDGE("OPPOSITE_EDGE"), // "OPPOSITE_EDGE", "SAME_EDGE" 
                                      //    or "SAME_EDGE_PIPELINED" 
      .INIT_Q1(1'b0), // Initial value of Q1: 1'b0 or 1'b1
      .INIT_Q2(1'b0), // Initial value of Q2: 1'b0 or 1'b1
      .SRTYPE("ASYNC") // Set/Reset type: "SYNC" or "ASYNC" 
   ) IDDR_inst (
      .Q1(sdr_data[1]), // 1-bit output for positive edge of clock
      .Q2(sdr_data[0]), // 1-bit output for negative edge of clock
      .C(scko_dly),   // 1-bit clock input
      .CE(1'b1), // 1-bit clock enable input
      .D(sdo_dly),   // 1-bit DDR data input
      .R(1'b0),   // 1-bit reset
      .S(1'b0)    // 1-bit set
   );

   //deserialization logic
   logic       aresetn_local;
   always @(posedge clk)
   begin
      aresetn_local <= aresetn && !params_to_IP.reset;
   end
   
   logic reset;
   assign reset = !aresetn_local | cnv;
   logic [6:0] deser_cnt;
   logic [25:0] deser_data_sr;
   

   logic [25:0] deser_data;
   assign deser_data = {deser_data_sr[23:0], sdr_data};

   logic        latch;
   logic        latch_z;
   logic        latch_z2;
   logic        latch_pulse;
   assign latch_pulse = (latch_z2 == 1'b0) && (latch_z == 1'b1);
   
   always @(posedge scko_dly or posedge reset)
   begin
      if(reset)
      begin
         deser_cnt <= 0;
         latch <= 0;
         deser_data_sr <= 0;
      end
      else
      begin
         deser_data_sr <= deser_data;
         deser_cnt <= deser_cnt + 1;

         if(deser_cnt == 'hb) latch <= 1;
         else                 latch <= 0;
      end
   end // always @ (posedge scko or posedge reset)

   xpm_cdc_single #(
                    .DEST_SYNC_FF(2),   // DECIMAL; range: 2-10
                    .INIT_SYNC_FF(1),   // DECIMAL; 0=disable simulation init values, 1=enable simulation init values
                    .SIM_ASSERT_CHK(0), // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
                    .SRC_INPUT_REG(0)   // DECIMAL; 0=do not register input, 1=register input
                    )
   xpm_cdc_single_inst (
                        .dest_out(latch_z), // 1-bit output: src_in synchronized to the destination clock domain. This output is
                        .dest_clk(clk), // 1-bit input: Clock signal for the destination clock domain.
                        .src_in(latch)      // 1-bit input: Input signal to be synchronized to dest_clk domain.
                        );

   always @(posedge clk or negedge aresetn_local)
   begin
      if(!aresetn_local)
      begin
         latch_z2 <= '0;
      end
      else
      begin
         latch_z2 <= latch_z;
      end
   end // always @ (posedge clk or negedge aresetn_local)

   //skip first readback after write note starts
   logic pastFirstRead;
   always @(posedge clk or posedge timetrig or negedge aresetn_local)
   begin
      if(timetrig || !aresetn_local) pastFirstRead <= 0;
      else if(latch_pulse)           pastFirstRead <= 1;
   end

   //summing logic.  If nsum == 0, bypass summing logic
   logic [31:0] sum [8];
   logic [7:0]  sum_we;
   generate
      genvar    iChan;
      for (iChan = 0; iChan < 8; iChan++)
      begin
         logic [31:0] count = 0;
         always @(posedge clk)
         begin
            sum_we[iChan] <= '0;
            if( count == params_to_IP.nsum )
            begin
               count <= '0;
               sum_we[iChan] <= 1;
            end
            else if( params_to_IP.enable && iChan == deser_data[5:3] && pastFirstRead && latch_pulse)
            begin
               count <= count + 1;
               if(count == 0)
               begin
                  sum[iChan] <= {8'b0, deser_data[23:0]};
               end
               else
               begin
                  sum[iChan][31:6] <= sum[iChan][31:6] + {8'b0, deser_data[23:6]};
               end
            end
         end // always @ (posedge clk)
      end
   endgenerate

   //FIFO inout mux
   logic [31:0] fifo_input;
   logic        fifo_we;
   always_comb
   begin
      if(params_to_IP.nsum == '0)
      begin
         fifo_input = {8'b0, deser_data[23:0]};
         fifo_we = pastFirstRead && latch_pulse;
      end
      else
      begin
         fifo_we = |sum_we;
         case(sum_we)
           8'h01: fifo_input <= sum[0];
           8'h02: fifo_input <= sum[1];
           8'h04: fifo_input <= sum[2];
           8'h08: fifo_input <= sum[3];
           8'h10: fifo_input <= sum[4];
           8'h20: fifo_input <= sum[5];
           8'h40: fifo_input <= sum[6];
           8'h80: fifo_input <= sum[7];
           default: fifo_input <= '0;
         endcase;
      end
   end // always_comb

   assign time_we = fifo_we;
   
   logic empty;
   assign FIFO_notEmpty = !empty;
   xpm_fifo_async 
   #(
     .CDC_SYNC_STAGES(2),       // DECIMAL
     .DOUT_RESET_VALUE("0"),    // String
     .ECC_MODE("no_ecc"),       // String
     .FIFO_MEMORY_TYPE("auto"), // String
     .FIFO_READ_LATENCY(1),     // DECIMAL
     .FIFO_WRITE_DEPTH(FIFO_MAX_SIZE),   // DECIMAL
     .FULL_RESET_VALUE(0),      // DECIMAL
     .PROG_EMPTY_THRESH(10),    // DECIMAL
     .PROG_FULL_THRESH(10),     // DECIMAL
     .RD_DATA_COUNT_WIDTH($clog2(FIFO_MAX_SIZE) + 1),   // DECIMAL
     .READ_DATA_WIDTH(32),      // DECIMAL
     .READ_MODE("std"),         // String
     .RELATED_CLOCKS(0),        // DECIMAL
     .SIM_ASSERT_CHK(1),        // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
     .USE_ADV_FEATURES("0404"), // String
     .WAKEUP_TIME(0),           // DECIMAL
     .WRITE_DATA_WIDTH(32),     // DECIMAL
     .WR_DATA_COUNT_WIDTH($clog2(FIFO_MAX_SIZE) + 1)    // DECIMAL
     ) xpm_fifo_async_data 
   (
    .almost_empty(),
    .almost_full(),     // 1-bit output: Almost Full: When asserted, this signal indicates that
    .data_valid(),       // 1-bit output: Read Data Valid: When asserted, this signal indicates
    .dbiterr(),             // 1-bit output: Double Bit Error: Indicates that the ECC decoder detected
    .dout(FIFO_dout),                   // READ_DATA_WIDTH-bit output: Read Data: The output data bus is driven
    .empty(empty),                 // 1-bit output: Empty Flag: When asserted, this signal indicates that the
    .full(FIFO_full),                   // 1-bit output: Full Flag: When asserted, this signal indicates that the
    .overflow(),           // 1-bit output: Overflow: This signal indicates that a write request
    .prog_empty(),       // 1-bit output: Programmable Empty: This signal is asserted when the
    .prog_full(),         // 1-bit output: Programmable Full: This signal is asserted when the
    .rd_data_count(FIFO_rd_count), // RD_DATA_COUNT_WIDTH-bit output: Read Data Count: This bus indicates the
    .rd_rst_busy(),     // 1-bit output: Read Reset Busy: Active-High indicator that the FIFO read
    .sbiterr(),             // 1-bit output: Single Bit Error: Indicates that the ECC decoder detected
    .underflow(),         // 1-bit output: Underflow: Indicates that the read request (rd_en) during
    .wr_ack(),               // 1-bit output: Write Acknowledge: This signal indicates that a write
    .wr_data_count(), // WR_DATA_COUNT_WIDTH-bit output: Write Data Count: This bus indicates
    .wr_rst_busy(wr_rst_busy),     // 1-bit output: Write Reset Busy: Active-High indicator that the FIFO
    .din(fifo_input),                     // WRITE_DATA_WIDTH-bit input: Write Data: The input data bus used when
    .injectdbiterr(1'b0), // 1-bit input: Double Bit Error Injection: Injects a double bit error if
    .injectsbiterr(1'b0), // 1-bit input: Single Bit Error Injection: Injects a single bit error if
    .rd_clk(FIFO_clk),               // 1-bit input: Read clock: Used for read operation. rd_clk must be a free
    .rd_en(FIFO_rden),                 // 1-bit input: Read Enable: If the FIFO is not empty, asserting this
    .rst(!aresetn_local),                     // 1-bit input: Reset: Must be synchronous to wr_clk. The clock(s) can be
    .sleep(1'b0),                 // 1-bit input: Dynamic power saving: If sleep is High, the memory/fifo
    .wr_clk(clk),               // 1-bit input: Write clock: Used for write operation. wr_clk must be a
    .wr_en(!FIFO_write_block && params_to_IP.enable && fifo_we)                  // 1-bit input: Write Enable: If the FIFO is not full, asserting this
    );

endmodule
