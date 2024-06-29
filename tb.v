`timescale 1ns / 1ps



module tb();
  reg [31:0] A,B;
 reg [2:0] select ;
 wire [31:0] Out;
 wire cout1 ,cout2 , cout3 ;
reg clk;


 initial
 begin
 clk=0;
 forever #5
 clk = ~clk;

 end

 source A1(Out ,cout1 ,cout2 ,cout3 ,A,B,select,clk);
 initial
 begin
 #100;

 A = 32'hC04CCCCD ; B = 32'hC04CCCCD ; select = 0;
 #30;
A = 32'hC04CCCCD ; B = 32'hC04CCCCD ; select = 4;

 #30;
 /*
 A = 32'hC04CCCCD ; B = 32'hC04CCCCD ; select = 2;
 #30;

 A = 32'hC04CCCCD ; B = 32'hC04CCCCD ; select = 3;
 #30;
 A = 32'hC04CCCCD ; B = 32'hC04CCCCD ; select = 4;
 #30;*/
 
//  A = 32'hC04CCCCD ; B = 32'h404CCCCD ; select = 0;
// #30;
// A = 32'h404CCCCD ; B = 32'h404CCCCD ; select = 2;
// #30;
// A = 32'hC04CCCCD ; B = 32'h404CCCCD ; select = 3;
// #30;
// A = 32'h404CCCCD ; B = 32'hC04CCCCD ; select = 4;

// #30;

 $finish ;

 end 
 
endmodule