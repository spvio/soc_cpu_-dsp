//pwm modulation of 16 bit numbers
//Left -> Right 

`timescale  1ns/1ps
module testbench();
parameter FIFO_LEN = 256;
logic clk;
logic tx_clk; 
logic wl;
logic sda;
logic[4:0] counter;
logic fifo_full;
logic fifo_empty;
logic result_valid;
logic signed[31:0] BINS_R[(FIFO_LEN-1):0];
logic signed[31:0] BINS_I[(FIFO_LEN-1):0];

dsp_unit#(.FIFO_LEN(FIFO_LEN)) dut (
.clk(clk), 
.tx_clk(tx_clk),
.wl(wl), 
.sda(sda),
.fifo_full(fifo_full),
.fifo_empty(fifo_empty),
.result_valid(result_valid),
.BINS_R(BINS_R),
.BINS_I(BINS_I));

//initial clk values 
initial begin 
tx_clk = 1'b1;
clk = 1'b1;
counter = 1'b0;
wl = 1'b0;
sda = 1'b0;
end

always #5  tx_clk = ~tx_clk; //(actually 29 but keep it 5 simplicity)
always #1   clk = ~clk;

initial begin: word_select
    generate_wl();
end

always @(posedge clk) begin
    if(result_valid)
        $display("FFT frame complete: bin 0 = %0d + j%0d", BINS_R[0], BINS_I[0]);
end


initial begin: data_line
    generate_sda();
end

initial begin: t_limit
    #250000;
    $finish;
end




task generate_wl();
forever begin 
    @(posedge tx_clk)
    if(counter != 16) counter = counter + 1;
    else begin 
        wl = ~wl;
        counter = 0;
    end 
end
endtask

task generate_sda();
forever begin 
    @(posedge tx_clk) begin 
        sda <= $urandom % 2;
    end

end
endtask








endmodule
