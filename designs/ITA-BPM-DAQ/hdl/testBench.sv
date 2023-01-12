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
   
  wire [7:0]Busy;
  wire [7:0]CNV;
  wire [14:0]DDR_addr;
  wire [2:0]DDR_ba;
  wire DDR_cas_n;
  wire DDR_ck_n;
  wire DDR_ck_p;
  wire DDR_cke;
  wire DDR_cs_n;
  wire [3:0]DDR_dm;
  wire [31:0]DDR_dq;
  wire [3:0]DDR_dqs_n;
  wire [3:0]DDR_dqs_p;
  wire DDR_odt;
  wire DDR_ras_n;
  wire DDR_reset_n;
  wire DDR_we_n;
  wire FIXED_IO_ddr_vrn;
  wire FIXED_IO_ddr_vrp;
  wire [53:0]FIXED_IO_mio;
  wire FIXED_IO_ps_clk;
  wire FIXED_IO_ps_porb;
  wire FIXED_IO_ps_srstb;
  wire [5:0]GPIO_tri_o;
  wire [1:0]SCKI_N;
  wire [1:0]SCKI_P;
  wire [7:0]SCKO_N;
  wire [7:0]SCKO_P;
  wire SCL_0;
  wire SCL_1;
  wire SDA_0;
  wire SDA_1;
  wire [1:0]SDI_N;
  wire [1:0]SDI_P;
  wire [7:0]SDO_N;
  wire [7:0]SDO_P;

   reg         resp;
   
   reg         tb_ACLK = 0;
   reg         tb_ARESETn;
   assign FIXED_IO_ps_clk = tb_ACLK;
   assign FIXED_IO_ps_porb = tb_ARESETn;
   assign FIXED_IO_ps_srstb = tb_ARESETn;

   always #5 tb_ACLK = !tb_ACLK;
   
ITA_BPM_DAQ_wrapper dut
   (Busy,
    CNV,
    DDR_addr,
    DDR_ba,
    DDR_cas_n,
    DDR_ck_n,
    DDR_ck_p,
    DDR_cke,
    DDR_cs_n,
    DDR_dm,
    DDR_dq,
    DDR_dqs_n,
    DDR_dqs_p,
    DDR_odt,
    DDR_ras_n,
    DDR_reset_n,
    DDR_we_n,
    FIXED_IO_ddr_vrn,
    FIXED_IO_ddr_vrp,
    FIXED_IO_mio,
    FIXED_IO_ps_clk,
    FIXED_IO_ps_porb,
    FIXED_IO_ps_srstb,
    GPIO_tri_o,
    SCKI_N,
    SCKI_P,
    SCKO_N,
    SCKO_P,
    SCL_0,
    SCL_1,
    SDA_0,
    SDA_1,
    SDI_N,
    SDI_P,
    SDO_N,
    SDO_P);

   logic [7:0] scko;
   assign SCKO_P = scko;
   assign SCKO_N = ~scko;
   logic [7:0] sdo;
   assign SDO_P = sdo;
   assign SDO_N = ~sdo;

   generate
      for(genvar i = 0; i < 8; i += 1)
      begin
         LTC2333_digitalModel ltc2333
                  (
                   .cnv(CNV),
                   .scki(SCKI_P),
                   .sdi(SDI_P),
                   .busy(),
                   .scko(scko[i]),
                   .sdo(sdo[i])
                   );
      end
   endgenerate

   logic [31:0] read_data;
   
   initial
   begin
      
      $display ("running the tb");
      
      tb_ARESETn = 1'b0;
      repeat(2)@(posedge tb_ACLK);        
      tb_ARESETn = 1'b1;
      @(posedge tb_ACLK);
      
      repeat(5) @(posedge tb_ACLK);
      
      //Reset the PL
      testBench.dut.ITA_BPM_DAQ_i.processing_system7_0.inst.fpga_soft_reset(32'h1);
      testBench.dut.ITA_BPM_DAQ_i.processing_system7_0.inst.fpga_soft_reset(32'h0);

      testBench.dut.ITA_BPM_DAQ_i.processing_system7_0.inst.write_data(32'h41200000,4, 32'hFFFFFFFF, resp);

      testBench.dut.ITA_BPM_DAQ_i.processing_system7_0.inst.write_data(32'h43c1000c,4, 32'h00000010, resp);
      testBench.dut.ITA_BPM_DAQ_i.processing_system7_0.inst.write_data(32'h43c10004,4, 32'h000000ff, resp);
      testBench.dut.ITA_BPM_DAQ_i.processing_system7_0.inst.write_data(32'h43c00000,4, 32'h00000002, resp);
      testBench.dut.ITA_BPM_DAQ_i.processing_system7_0.inst.write_data(32'h43c10000,4, 32'h00000001, resp);
      #50000;

      testBench.dut.ITA_BPM_DAQ_i.processing_system7_0.inst.read_data(32'h43c00000+4*1+16*0,4,read_data,resp);
      $display("read_data:", read_data);
      testBench.dut.ITA_BPM_DAQ_i.processing_system7_0.inst.read_data(32'h43c00000+4*1+16*1,4,read_data,resp);
      $display("read_data:", read_data);
      testBench.dut.ITA_BPM_DAQ_i.processing_system7_0.inst.read_data(32'h43c00000+4*1+16*2,4,read_data,resp);
      $display("read_data:", read_data);

      repeat(4)
      begin
         testBench.dut.ITA_BPM_DAQ_i.processing_system7_0.inst.read_data(32'h7aa00000,4,read_data,resp);
         $display("read_data:", read_data);
      end

      testBench.dut.ITA_BPM_DAQ_i.processing_system7_0.inst.read_data(32'h43c00000+4*1+16*0,4,read_data,resp);
      $display("read_data:", read_data);
      testBench.dut.ITA_BPM_DAQ_i.processing_system7_0.inst.read_data(32'h43c00000+4*1+16*1,4,read_data,resp);
      $display("read_data:", read_data);
      testBench.dut.ITA_BPM_DAQ_i.processing_system7_0.inst.read_data(32'h43c00000+4*1+16*2,4,read_data,resp);
      $display("read_data:", read_data);

   end
   
endmodule
