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
    
    task write_byte;
        input [7:0] in_byte;
        begin
        for(int i = 7; i >= 0; i -= 1)
            begin
                sdi <= in_byte[i];
        
                #5 scki <= 1;
                #5 scki <= 0;
            end
        end
    endtask
    
    task read;
        begin
            cnv <= 1;
            #50 cnv <= 0;
            sdi <= 0;
            #600
            write_byte(8'h0);
            write_byte(8'h0);
            write_byte(8'h0);
        end
    endtask
    
    LTC2333_digitalModel ltc2333
    (
        .cnv(cnv),
        .scki(scki),
        .sdi(sdi),
        .busy(busy),
        .scko(scko),
        .sdo(sdo)
    );
    
    initial
    begin
        cnv <= 0;
        sdi <= 0;
        scki <= 0;
        
        #100
        
        cnv <= 1;
        #50 cnv <= 0;
        
        #500
        
        write_byte(8'h80);
        write_byte(8'h00);
        write_byte(8'h00);
        
        #100 cnv <= 1;
        #50 cnv <= 0;
        
        sdi <= 0;
        
        #600
        
        
        write_byte(8'h00);
        write_byte(8'h00);
        write_byte(8'h00);
        
        #100 cnv <= 1;
        #50 cnv <= 0;
        
        sdi <= 0;
        
        #600
        
        
        write_byte(8'h80);
        write_byte(8'h81);
        write_byte(8'h82);
        write_byte(8'h83);
        write_byte(8'h84);
        write_byte(8'h85);
        write_byte(8'h86);
        write_byte(8'h87);
        
        #100 read();
        #100 read();
        #100 read();
        #100 read();
        #100 read();
        #100 read();
        #100 read();
        #100 read();
        #100 read();
        
        #100
        
        #100 cnv <= 1;
        #50 cnv <= 0;
        
        sdi <= 0;
        
        #600
        
        write_byte(8'h85);
        write_byte(8'h00);
        write_byte(8'h00);
        
        #100 read();
        #100 read();
    end
    
endmodule
