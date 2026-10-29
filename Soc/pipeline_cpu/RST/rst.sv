module rst #(parameter MAX = 10)(input logic clk,input logic sw, output logic rst);

logic[15:0] counter;
logic flip_f1;
logic flip_f2;


//preecnt metastability:
always_ff @(posedge clk) begin: meta
flip_f1 <= sw;
flip_f2 <= flip_f1; 
end

always_ff @(posedge clk) begin: debounce
if(!flip_f2) counter <= 0;
//have to hold button continously 
else begin 
        if(counter < (MAX+5) )counter <= counter + 1;
        else counter <= counter;
    end
end

always_comb begin 
//priority mux
if(counter < MAX) rst = 1'b0;
else if(counter >= MAX && counter < (MAX+5)) rst = 1'b1;
else rst = 1'b0;
end

endmodule
