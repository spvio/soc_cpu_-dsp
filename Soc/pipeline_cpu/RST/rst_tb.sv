`timescale 1ps/1ps

module reset();
logic clk;
logic sw;
logic rst;

initial begin 
clk = 1'b1;
sw = 1'b0;
end

rst dut(.clk(clk), .sw(sw), .rst(rst));
always #1 clk = ~clk;
//mimiking switch debounce
initial begin 
$dumpfile("wave.vcd");
$dumpvars(0, reset);

sw = 1'b1; #1;
sw = 1'b0; #2;
sw = 1'b1; #1;
sw = 1'b0; #1;
sw = 1'b1; #20;
sw = 1'b0;

$finish;
end



endmodule 