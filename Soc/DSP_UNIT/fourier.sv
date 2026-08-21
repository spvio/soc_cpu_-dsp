
/*
-implementing FFT
-1st butterfly stage on FIFO

*/
// Match the FIFO's descending unpacked-array index range.  Using [0:FIFO_LEN-1]
// here maps element positions in reverse when this port is connected to FIFO[255:0].
module fourier#(parameter FIFO_LEN = 256)(input clk, input logic[15:0] value);
logic signed [15:0] LUT_sin[255:0];
logic signed [15:0] LUT_cos[255:0];

parameter IDLE = 2'b00;
parameter COPY = 2'b01;
parameter EXEC = 2'b10;
parameter MOVE = 2'b11;


logic[15:0]ARRAY_R[255:0];
logic[15:0]ARRAY_I[255:0];
logic[15:0]BINS_R[(FIFO_LEN-1):0];
logic[15:0]BINS_I[(FIFO_LEN-1):0];

logic signed [15:0] s1_r;
logic signed [15:0] s2_r;
logic signed [15:0] s1_i;
logic signed [15:0] s2_i;

initial begin  
$readmemb("sin_lut.txt", LUT_sin);
$readmemb("cos_lut.txt", LUT_cos);
counter = 0;
end

//general iterative loop
logic[15:0] dft_p;
logic[15:0] r_s;
logic[15:0] e_pivot;
logic[15:0] k;
logic[15:0] stages;
logic       in_ready;
logic[15:0] index;

//shadow pipeline variables
logic[2:0] ready; //(3 bits)
logic[15:0] addr_1;
logic[15:0] addr_2;


initial begin
   x = 0;
   dft_p = 4;
   e_pivot = 0;
   r_s = 64;
   stage = COPY;
   index = 0;
end

always@(posedge clk) begin 
   case(state)  

      COPY: begin 
         ARRAY_R[GETI] <= FIFO[GETI]; 
         ARRAY_I[GETI] <= 0;
         if(GETI == 255) state <= EXEC;
      end

      EXEC:  begin 
         if( k< (dft >> 1) ) begin 
            even_r <= ARRAY_R[e_pivot*(dft_p >> 1) + k];
            odd_r  <= ARRAY_R[e_pivot*(dft_p >> 1) + k + 128];
            even_i <= ARRAY_I[e_pivot*(dft_p >> 1) + k];
            odd_i <=  ARRAY_R[e_pivot*(dft_p >> 1) + k + 128];
            addr_1 <= e_pivot * dft_p;
            ready[0] <= 1;


            s1_r  <= signed'(even_r)  +  signed'(r_LUT[k*r_s]*odd_r) - signed'(i_LUT[k*r_s]*odd_i);
            s2_r  <= signed'(even_r)  -  signed'(r_LUT[k*r_s]*odd_r) - signed'(i_LUT[k*r_s]*odd_i);
            s1_i  <= signed'(even_i)  +  signed'(i_LUT[k*r_s]*odd_r) + signed'(r_LUT[k*r_s]*odd_i);
            s2_i  <= signed'(even_i)  -  signed'(i_LUT[k*r_s]*odd_r) + signed'(r_LUT[k*r_s]*odd_i);
            addr_2 <= addr_1 + k; 
            ready[2] <= ready[1];


         //writeback
            if(ready[2] == 1'b1) begin 
               ARRAY_R[addr_2] <= s1_r;
               ARRAY_R[addr_2 + (l_s >> 1)] <= s2_r;
               ARRAY_I[addr_2] <= s1_i;
               ARRAY_I[addr_2 + (l_s >> 1)] <= s2_i;

            end

            if(addr_2 + (l_s >> 1) != 255 ) begin 
               e_pivot <= e_pivot + 1;
            end

            else begin 
               e_pivot <= 0;
               k <= k + 1;
            end
      end

      else begin 
         x <= x + 1;
         k <= 0;
         e_pivot <= 0;
         r_s <= r_s >> 1;
         dft_p <= dft_p << 1;
         ready <= 0;
      end
      if(x == 8) stage <= MOVE;

   end

      MOVE: begin 
         if(index != FIFO_LEN) index = index + 1;
         else begin 
            index <= 0;
            STATE <= IDLE;
         end
         BINS_R[index] <= ARRAY_R[index];
         BINS_I[index] <= ARRAY_I[index];

      end
   endcase
end



endmodule
