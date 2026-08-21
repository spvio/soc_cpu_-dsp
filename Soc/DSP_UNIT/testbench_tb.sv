//pwm modulation of 16 bit numbers
//Left -> Right 

`timescale  1ns/1ps
bit rand_bit;

module testbench();
parameter FIFO_LEN = 256;
logic clk;
logic tx_clk; 
logic wl;
logic sda;
logic[4:0] counter;
logic[15:0] l_pcm;
logic[15:0] r_pcm;
logic[15:0] PUTI;
logic[15:0] FIFO[(FIFO_LEN-1):0];

i2s_fifo#(.FIFO_LEN(FIFO_LEN)) dut1 (
.clk(clk), 
.tx_clk(tx_clk),
.wl(wl), 
.sda(sda),
.FIFO(FIFO),
.PUTI(PUTI)); 

fourier#(.FIFO_LEN(FIFO_LEN)) dut2(.clk(clk), .FIFO(FIFO), .PUTI(PUTI));

//initial clk values 
initial begin 
tx_clk = 1'b1;
clk = 1'b1;
counter = 1'b0;
wl = 1'b0;
end

always #5  tx_clk = ~tx_clk; //(actually 29 but keep it 5 simplicity)
always #1   clk = ~clk;

initial begin: word_select
    $dumpfile("wave.vcd");
    $dumpvars(0, dut1);
    $dumpvars(0, dut2);
    generate_wl();
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