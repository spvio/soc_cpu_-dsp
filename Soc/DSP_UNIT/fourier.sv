

//2 DATA TYPES: Q1.15 & Q16.0
module fourier#(parameter FIFO_LEN = 256)(
input  logic clk, 
input  logic fifo_empty,
input  logic read_valid,
input  logic[15:0] pcm_value, 
output logic read_enable);

//ping-pong memory
logic data_valid;
logic signed[31:0] bank_a_r[255:0];
logic signed[31:0] bank_b_r[255:0];
logic signed[31:0] bank_a_i[255:0];
logic signed[31:0] bank_b_i[255:0];

logic[31:0]BINS_R[(FIFO_LEN-1):0];
logic[31:0]BINS_I[(FIFO_LEN-1):0];
logic signed [15:0] LUT_sin[255:0];
logic signed [15:0] LUT_cos[255:0];

logic[1:0] state;
logic[7:0] index;
parameter IDLE   = 2'b00;
parameter COPY   = 2'b01;
parameter EXEC   = 2'b10;
parameter RESULT = 2'b11;

//fft_variables
logic signed[32:0] even_r;
logic signed[32:0] odd_r;
logic signed[32:0] even_i;
logic signed[32:0] odd_i;
logic signed[32:0] val_1_r;
logic signed[32:0] val_2_r;
logic signed[32:0] val_1_i;
logic signed[32:0] val_2_i;
logic signed[31:0] w_even_r;
logic signed[31:0] w_odd_r;
logic signed[31:0] w_even_i;
logic signed[31:0] w_odd_i;
logic[15:0] addr;
logic signed [15:0] s1_r;
logic signed [15:0] s2_r;
logic signed [15:0] s1_i;
logic signed [15:0] s2_i;


//general iterative loop
logic[15:0] dft_p;
logic[15:0] r_s;
logic[15:0] pivot;
logic[15:0] k;
logic[15:0] x;

//comb variables
logic signed [47:0] cos_r;
logic sgined[47:0] cos_i;
logic signed[47:0] sin_r;
logic signed[47:0] sin_i;
logic signed[48:0] w1;
logic signed[48:0] w2;



//shadow pipeline variables
logic[2:0] ready; //(3 bits)
logic[15:0] addr_1;
logic[15:0] addr_2;


initial begin
end

always@(posedge clk) begin 
   case(state)  
      COPY: begin
         if(read_valid) begin 
            bank_a_r[index] <= {{16{pcm_value[15]}}, pcm_value};
            bank_a_i[index] <= 0;
            if(index == 255) begin 
               state <= EXEC;
               index <= 0;
            end
            else begin
               index <= index + 1;
            end
         end

      end

      EXEC:  begin 
         if(k < (dft_p >> 1)) begin 
            val_1_r <= w_even_r + (w1 >>> 15);
            val_1_i <= w_even_i + (w2 >>> 15);
            val_2_r <= w_even_r - (w1 >>> 15);
            val_2_i <= w_even_i - (w2 >>> 15);

   
            data_valid <= 1'b1;     
            addr       <=  pivot*dft_p + k;    
            if(pivot != ((r_s)-1)) begin
               pivot <= pivot + 1;
            end
            else begin
               pivot <= 0;
               k <= k + 1;
            end

         end
         else begin 
            k <= 0;
            pivot <= 0;
            data_valid <= 0;

            if(x == 7) begin
               state <= RESULT;
               index <= 0;
            end
            else begin
               x <= x + 1;
               r_s <= r_s >> 1;
               dft_p <= dft_p << 1;
            end
         end
         
         //writeback
         if(data_valid) begin 
            if(!x[0]) begin 
               bank_b_r[addr] <= val_1_r;
               bank_b_r[addr+(dft_p >> 1)] <= val_2_r;
               bank_b_i[addr] <= val_1_i;
               bank_b_i[addr + (dft_p >> 1)] <= val_2_i;
            end
            else begin 
               bank_a_r[addr] <= val_1_r;
               bank_a_r[addr+(dft_p >> 1)] <= val_2_r;
               bank_a_i[addr] <= val_1_i;
               bank_a_i[addr + (dft_p >> 1)] <= val_2_i;


            end
         end

      end

      RESULT: begin 
         BINS_R[index] <= bank_a_r[index];
         BINS_I[index] <= bank_a_i[index];

         if(index == 255) begin
            index <= 0;
            state <= IDLE;
         end
         else begin 
            index <= index + 1;
         end

      end
   endcase
end


always_comb begin 
   read_enable = (!fifo_empty && state == COPY);

   if(!x[0]) begin 
      //read
      w_even_r = bank_a_r[pivot*(dft_p >>1) + k];
      w_odd_r  = bank_a_r[pivot*(dft_p >> 1) + k + 128];
      w_even_i = bank_a_i[pivot*(dft_p >>1) + k];
      w_odd_i  = bank_a_i[pivot*(dft_p >> 1) + k + 128];



   end

   else begin 
      w_even_r = bank_b_r[pivot*(dft_p>>1) + k];
      w_odd_r  = bank_b_r[pivot*(dft_p >> 1) + k + 128];
      w_even_i = bank_b_i[pivot*(dft_p>>1) + k];
      w_odd_i  = bank_b_i[pivot*(dft_p >> 1) + k + 128];
   end

   //temporary multiplication needs 48 bits
   cos_r = LUT_cos[k*r_s] * w_odd_r;
   cos_i = LUT_cos[k*r_s] * w_odd_i;
   sin_r = LUT_sin[k*r_s] * w_odd_r;
   sin_i = LUT_sin[k*r_s] * w_odd_i;
   
   w1 =  cos_r - sin_i;
   w2 =  cos_i + sin_r;
end


initial begin  
   $readmemb("sin_lut.txt", LUT_sin);
   $readmemb("cos_lut.txt", LUT_cos);
   data_valid = 0;
   state = COPY;
   r_s = 128;
   pivot = 0;
   index = 0;
   x = 0;
   k = 0;
   dft_p = 2;
   addr = 0;
   val_1_r = 0;

end

endmodule
