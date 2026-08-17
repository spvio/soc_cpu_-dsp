//pwm modulation of 16 bit numbers
//Left -> Right 

`timescale  1ns/1ps
bit rand_bit;

module testbench();
logic tx_clk; 
logic wl;
logic sda;
logic[4:0] counter;
logic[15:0] l_pcm;
logic[15:0] r_pcm;

i2s i2s_init(.tx_clk(tx_clk), .wl(wl), .sda(sda), .l_val(l_pcm), .r_val(r_pcm));

//initial clk values 
initial begin 
tx_clk = 1'b1;
counter = 1'b0;
wl = 1'b0;
end

always #29  tx_clk = ~tx_clk;

initial begin: word_select
    $dumpfile("wave.vcd");
    $dumpvars(0, i2s_init);
    generate_wl();
end


initial begin: data_line
    generate_sda();
end

initial begin: t_limit
    #40000;
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