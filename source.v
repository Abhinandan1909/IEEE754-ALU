`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////

module source(output reg [31:0] Out,
    output reg  cout1,
    output reg  cout2,
    output reg  cout3, 
    input [31:0] A,
    input [31:0] B,
    input [2:0] select,
    input  clk
   
    );
 
wire [31:0] output1,output2,output3,output5;
wire output4,output6,output7;
 
reg [31:0] BS;
Float_multi fm1(output1,A,B);
float_add fa1(output2,A,B,select);
FloatingDivision fd1(A,B,select,output3);
comp_32 c1 (A,B,clk,output4,output6,output7);
float_add fs1(output5,A,BS,select);
 
always@(*)
begin
 
 
    case(select)
 
    3'b000: 
        begin
        Out = output1 ; 
        cout1 = 0;
        cout2 = 0;
        cout3 = 0;      
        end
        
    3'b001:
    begin
        Out = output2;
        cout1 = 0;
        cout2 = 0;
        cout3 = 0;
    end 
       
    3'b010:
    begin
        Out = output3;
        cout1 = 0;//sign
        cout2 = 0;
        cout3 = 0;
    end   
     
    3'b011:
    begin
        Out = 0;
        cout1 = output4;
        cout2 = output6;
        cout3 = output7;
    end 


    3'b100:
        begin
        BS[31] = ~B[31];
        BS[30:0] = B[30:0];
        Out = output5;
        cout1 = 0;
        cout2 = 0;
        cout3 = 0;
        end   
        
       /* default:
        begin 
        Out=32'b0;
        
        BS[31:0] = 0;
        cout1 = 1'b1;
        cout2 = 1'b1;
        cout3 = 1'b1;
        end*/
    endcase
end
   
endmodule

/////////Division////
module FloatingDivision(A,B,select,result);
input [31:0]A;
 input [31:0]B;

 input [2:0] select;
 output [31:0] result;
                         

wire [31:0] temp1,temp2,temp3,temp4,temp5,temp6,temp7,debug;
wire [7:0] Exponent;
wire [31:0] reciprocal;
wire [31:0] x0,x1,x2,x3;


Float_multi M1(.Out(temp1),.A({{1'b0,8'd126,B[22:0]}}),.B(32'h3ff0f0f1)); //verified
assign debug = {1'b1,temp1[30:0]};
float_add A1(.Out(x0),.A(32'h4034b4b5),.B({1'b1,temp1[30:0]}),.select(select));


Float_multi M2(.Out(temp2),.A({{1'b0,8'd126,B[22:0]}}),.B(x0));
float_add A2(.Out(temp3),.A(32'h40000000),.B({!temp2[31],temp2[30:0]}),.select(select));
Float_multi M3(.Out(x1),.A(x0),.B(temp3));


Float_multi M4(.Out(temp4),.A({1'b0,8'd126,B[22:0]}),.B(x1));
float_add A3(.Out(temp5),.A(32'h40000000),.B({!temp4[31],temp4[30:0]}),.select(select));
Float_multi M5(.Out(x2),.A(x1),.B(temp5));


Float_multi M6(.Out(temp6),.A({1'b0,8'd126,B[22:0]}),.B(x2));
float_add A4(.Out(temp7),.A(32'h40000000),.B({!temp6[31],temp6[30:0]}),.select(select));
Float_multi M7(.Out(x3),.A(x2),.B(temp7));


assign Exponent = x3[30:23]+8'd126-B[30:23];
assign reciprocal = {B[31],Exponent,x3[22:0]};


Float_multi M8(.Out(result),.A(A),.B(reciprocal));
endmodule

///////Add_sub/////
module float_add(
    output [31:0]  Out,
    input [31:0] A,
    input [31:0] B,
    input [2:0] select
    );
  
       reg [23:0] A_man,B_man;
       reg [24:0] man_final;
       reg [5:0] add1=0 ; reg [5:0]norm=0;
       reg sign = 0 ;
       reg [7:0] exp_final =0 ;
       wire [7:0] exp_diff,xA,xB;
       wire [23:0] mA,mB;
       wire check,ismsame;
       reg [4:0] i;
       
       
        
       assign mA = {1'b1,A[22:0]};
       assign mB = {1'b1,B[22:0]};
       assign xA = A[30:23];
       assign xB = B[30:23];
               
       assign exp_diff = (xA > xB)? (xA- xB) : (xB - xA);
       assign check = ( mA > mB ) ? 1'b1:1'b0;
       assign ismsame = (mA == mB);
       
       
       always @(*)
       begin
       
        if(A[31] == 0 && B[31] == 0)
        begin  
                    
                    if ((A[30:23] > B[30:23]))
                    begin 
                        A_man <= mA;       
                        B_man <=  mB >> exp_diff;   
                        exp_final = xA;
                    end      
                    else       
                    begin
                            B_man <= mB;
                            A_man <=  mA >> exp_diff;
                            exp_final = xB;
                    end
            
         man_final = A_man + B_man ;         
         
                  if(man_final[24]) 
                  begin
                 add1 = 1;
            man_final =  man_final >> 1;
                  end
                 else
            add1 = 0;
        end
    
        else if (A[31] == 1 && B[31] == 0)
        begin
          
        
            if(A[30:23] == B[30:23])
            begin
                A_man <= mA;
                B_man <= mB;
                exp_final = xA;                
                if( check )
                begin
                    sign = 1;
                    man_final = A_man - B_man;
                end
                else if(ismsame)
                begin
                    
                     man_final = 23'b0;
                     exp_final = 0;
                 end  
                 else
                 begin
                      
                      man_final = B_man - A_man;
                  end
              end
          
              else if ((A[30:23] > B[30:23]))
              begin 
                   A_man <= mA;       
                   B_man <=  mB >> exp_diff;   
                   exp_final = xA;
                   if(A_man > B_man)
                        man_final = A_man - B_man ;
                   else
                        man_final = B_man - A_man ;
                   sign = 1;
              end       
              
                else if(A[30:23]<B[30:23])          
                  begin
                B_man <= mB;
                   A_man <=  mA >> exp_diff;
                   exp_final = xB;
                   
                   if(A_man > B_man)
                   man_final = A_man - B_man ;
                   else
                   man_final = B_man - A_man ;
                   
                   end
// Normalization
      
      
       if(man_final[24]) 
                   begin
                    add1 = 1 ;
                   man_final =  man_final >> 1;
                   end
                else
                   add1 = 0;
  if(man_final[24] == 0 && man_final[23] == 0)
            
            for(i = 0; i < 23 ; i = i+1)    
                begin
                    if(man_final[i] == 1)
                     begin   
                        norm = (23 - i);
                        
                    end
                end                    
    man_final = man_final << norm;                                                                                                                                                                                                            
  end                                  
                                                                                                                                                                                                                                                                 
                
        
                 
    else if (A[31] == 0 && B[31] == 1)
        
          begin  
          
                if(A[30:23] == B[30:23])
                    begin
                    A_man <= mA;
                    B_man <= mB;
                    exp_final = xA;    
                        if( check )
                            begin
                           
                            man_final = A_man - B_man;
                            end
                         else if(ismsame)
                            begin
                            
                            man_final = 23'b0;
                            exp_final = 0;
                            end  
                        else
                            begin
                            sign = 1;
                            man_final = B_man - A_man;
                            end
                    end
          
               else if ((A[30:23] > B[30:23]))
                   begin 
                   A_man <= mA;       
                   B_man <=  mB >> exp_diff;   
                   exp_final = xA;
                   if(A_man > B_man)
                   man_final = A_man - B_man ;
                   else
                   man_final = B_man - A_man ;
                  
                   end      
              
                else if(A[30:23]<B[30:23])      
                   begin
                   B_man <= mB;
                   A_man <=  mA >> exp_diff;
                   exp_final = xB;
                   sign = 1;
                   if(A_man > B_man)
                   man_final = A_man - B_man ;
                   else
                   man_final = B_man - A_man ;
                   
                   end
            
                                                                      
               if(man_final[24]) 
                   begin
                    add1 = 1;
                   man_final =  man_final >> 1;
                   end
                else
                   add1 = 0;
                   
               if(man_final[24] == 0 && man_final[23] == 0)
                  
               for(i = 0; i < 23 ; i = i+1)    
                               begin
                                   if(man_final[i] == 1)
                                    begin   
                                       norm = (23- i);
                                       
                                   end
                               end                    
                   man_final = man_final << norm;             
                          
        end
     
     
     else if(A[31] == 1 && B[31] == 1)
        begin  
        sign = 1;
         if((A[30:23] == B[30:23]) && (ismsame) && (select == 3'b100))
           begin
           
           man_final = 23'b0;
           exp_final = 0;
           end             
        else begin   
          if ((A[30:23] > B[30:23]))
            begin 
            A_man <= mA;       
            B_man <=  mB >> exp_diff;   
            exp_final = xA;
            end      
       
         else       
            begin
            B_man <= mB;
            A_man <=  mA >> exp_diff;
            exp_final = xB;
            end
            
         man_final = A_man + B_man ;
         
           
        if(man_final[24]) 
            begin
             add1 = 1;
            man_final =  man_final >> 1;
            end
         else
            add1 = 0;
        end
        end
   end
              
      assign Out[22:0] = man_final[22:0];
        assign Out[30:23] = exp_final - norm + add1;
        assign Out[31] = sign;
     
   endmodule
   
 ////////Multiplier/////
   
  module Float_multi(
    output [31:0] Out,
    input [31:0] A,
    input [31:0] B
    );
 
reg [47:0] out;
reg [7:0]add;
 
 
wire [23:0] A_man ;
wire [23:0] B_man ;
 
assign A_man[23] = 1;
assign B_man[23] = 1;
 
assign A_man[22:0] = A[22:0];
assign B_man[22:0] = B[22:0];
wire chk = |A;
wire chk2 = |B;
 
 
assign Out[31] = A[31]^B[31];
 
always  @(*)
begin
 
if( chk == 0 )
begin
    out = 48'h0000_0000_0000;
    add = -110 ;
end
  else
    begin
    out[47:0] = A_man * B_man;
   
        if(out[47])
            add = 1;
        else
            add = 0;
    end
end
assign Out[22:0] = (out[47])? out[46:24] : out[45:23] ;
 
//wire [7:0] test = A[30:23] + B[30:23]+add-127;
assign Out[30:23] = A[30:23] + B[30:23]+add-127;
 
endmodule


//////Comparator////
module comp_32(input [31:0] A,
    input [31:0] B,
input clk,
    output reg AequalB,
    output reg AgreaterB,
    output reg AlessB
);
/*
reg [7:0] AE;
reg [7:0] BE;
reg [22:0] AM;
reg [22:0] BM;
*/

always @(posedge clk) begin
    /*AE = A[31:24];
    BE = B[31:24];
    AM = A[23:0];
    BM = B[23:0];
    */

    // Comparing sign bits
    if (A[31] == B[31]) begin
        if (A[31] == 1'b1) begin
            // A and B are both negative
            if (A > B) begin
                AgreaterB = 1'b1;
                AlessB = 1'b0;
                AequalB = 1'b0;
            end else if (A < B) begin
                AgreaterB = 1'b0;
                AlessB = 1'b1;
                AequalB = 1'b0;
            end else begin
                AgreaterB = 1'b0;
                AlessB = 1'b0;
                AequalB = 1'b1;
            end
        end else begin
            // A and B are both positive
            if (A > B) begin
                AgreaterB = 1'b1;
                AlessB = 1'b0;
                AequalB = 1'b0;
            end else if (A < B) begin
                AgreaterB = 1'b0;
                AlessB = 1'b1;
                AequalB = 1'b0;
            end else begin
                AgreaterB = 1'b0;
                AlessB = 1'b0;
                AequalB = 1'b1;
            end
        end
    end else begin
        // Signs are different
        if (A[31] == 1'b1) begin
            // A is negative, B is positive
            AgreaterB = 1'b0;
            AlessB = 1'b1;
            AequalB = 1'b0;
        end else begin
            // A is positive, B is negative
            AgreaterB = 1'b1;
            AlessB = 1'b0;
            AequalB = 1'b0;
        end
    end
end
endmodule
