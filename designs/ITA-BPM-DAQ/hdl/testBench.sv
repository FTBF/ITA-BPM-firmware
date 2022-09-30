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
   
   wire [14:0]DDR_addr;
   wire [2:0] DDR_ba;
   wire       DDR_cas_n;
   wire       DDR_ck_n;
   wire       DDR_ck_p;
   wire       DDR_cke;
   wire       DDR_cs_n;
   wire [3:0] DDR_dm;
   wire [31:0] DDR_dq;
   wire [3:0]  DDR_dqs_n;
   wire [3:0]  DDR_dqs_p;
   wire        DDR_odt;
   wire        DDR_ras_n;
   wire        DDR_reset_n;
   wire        DDR_we_n;
   wire        FIXED_IO_ddr_vrn;
   wire        FIXED_IO_ddr_vrp;
   wire [53:0] FIXED_IO_mio;
   wire        FIXED_IO_ps_clk;
   wire        FIXED_IO_ps_porb;
   wire        FIXED_IO_ps_srstb;
   wire [5:0]  GPIO_tri_o;
   wire        cnv;
   wire        scki;
   wire        scko_0;
   wire        scko_1;
   wire        scko_2;
   wire        scko_3;
   wire        scko_4;
   wire        scko_5;
   wire        scko_6;
   wire        scko_7;
   wire        sdi;
   wire        sdo_0;
   wire        sdo_1;
   wire        sdo_2;
   wire        sdo_3;
   wire        sdo_4;
   wire        sdo_5;
   wire        sdo_6;
   wire        sdo_7;

   reg         resp;
   
   reg         tb_ACLK = 0;
   reg         tb_ARESETn;
   assign FIXED_IO_ps_clk = tb_ACLK;
   assign FIXED_IO_ps_porb = tb_ARESETn;
   assign FIXED_IO_ps_srstb = tb_ARESETn;

   always #5 tb_ACLK = !tb_ACLK;
   
   ITA_BPM_DAQ_wrapper dut
   (DDR_addr,
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
    cnv,
    scki,
    scko_0,
    scko_1,
    scko_2,
    scko_3,
    scko_4,
    scko_5,
    scko_6,
    scko_7,
    sdi,
    sdo_0,
    sdo_1,
    sdo_2,
    sdo_3,
    sdo_4,
    sdo_5,
    sdo_6,
    sdo_7);

   logic [7:0] scko;
   assign {scko_0, scko_1, scko_2, scko_3, scko_4, scko_5, scko_6, scko_7} = scko;
   logic [7:0] sdo;
   assign {sdo_0, sdo_1, sdo_2, sdo_3, sdo_4, sdo_5, sdo_6, sdo_7} = sdo;

   generate
      for(genvar i = 0; i < 8; i += 1)
      begin
         LTC2333_digitalModel ltc2333
                  (
                   .cnv(cnv),
                   .scki(scki),
                   .sdi(sdi),
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

      testBench.dut.ITA_BPM_DAQ_i.processing_system7_0.inst.write_data(32'h43c10004,4, 32'h000001ff, resp);
      testBench.dut.ITA_BPM_DAQ_i.processing_system7_0.inst.write_data(32'h43c10000,4, 32'h00000001, resp);
      testBench.dut.ITA_BPM_DAQ_i.processing_system7_0.inst.write_data(32'h43c00000,4, 32'h00000002, resp);
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
