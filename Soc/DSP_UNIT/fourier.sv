
/*
-implementing the bare bones discrete fourier transform
-breaking it up in 256 samples for entire wave audio
-doing O(N^2), sampling at 44.4 KHz.
-everytime 
GETI -> (write to register)
     -> n(sample)

VARIABLES:
k     = bin 
n     = nth sample (n = GETI)
val   = f(n)


GOAL: o(n^2)

*/
module fourier(input clk, input val, input n);
logic[15:0]LUT_sin[255:0];
logic[15:0]LUT_cos[255:0];
logic[15:0]OUT[255:0];

logic[7:0] val;

logic[7:0] counter_i;
logic[7:0] counter_j;

//pipeline flipflops
logic[7:0]  reg1_s;
logic[7:0]  reg2_s;

logic[7:0] reg1_c;
logic[7:0] reg2_c;



initial begin  
$readmemb('sin_lut.txt', LUT_sin);
$readmemb('cos_lut.txt', LUT_cos);
end



always@(posedge clk) begin
   if(counter_j > 256) begin 
      if(counter_i > 128) counter_i <= 0;
      else  counter_i <= counter_i + 1;
      counter_j <= 0;
      OUT[counter_i]<= reg2_s*reg2_s + reg2_c*reg2_c;
      
   end
   else begincounter_j <= counter_j + 1;



   reg1_s <= LUT_sin[val] * MEM[counter_i];
   reg2_s <= reg2_s + reg1_s;

   reg1_c <= LUT_cos[val] * MEM[counter_i];
   reg2_c <= reg1_c + reg2_c;

end



always_comb begin 
if(counter_i * counter_j > 128) begin 
   val  = counter_i* counter_j >> 7
end
else  val = counter_i * counter_j;

end

endmodule




