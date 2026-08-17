//tx_clock - 3.429(board runs x29.1)
//notes sda => serial data line 

module i2s_fifo();
//i2s 
logic clk;
logic tx_clk;
logic wl;
logic sda;
logic l_val;
logic r_val;

//fifo
logic[7:0]  GETI; //for noww
logic       HAZARD;
logic       l_pcm;
logic       r_pcm;

i2s i2s_inst(.tx_clk(tx_clk), .wl(wl), .sda(sda), .l_val(l_val), .r_val(r_val));
FIFO l_FIFO(.clk(clk), .tx_clk(tx_clk),.val(l_val),  .GETI(GETI), .HAZARD(HAZARD), .pcm_val(l_pcm));
FIFO r_FIFO(.clk(clk), .tx_clk(tx_clk), .val(r_val), .GETI(GETI), .HAZARD(HAZARD), .pcm_val(r_pcm));

endmodule 


module i2s(input tx_clk, input wl, input sda, output logic[15:0] l_val, output logic[15:0] r_val);
logic[7:0] counter;
logic[15:0] l_pcm;
logic[15:0] r_pcm;
logic r_wl;
logic[1:0] STATE;

//for now
initial begin 
    counter = 0;
    r_pcm = 0;
    l_pcm = 0;
    STATE   = 0;

end

//states
parameter sync     =    0;
parameter sample_l =    1;
parameter sample_r =    2;

always @(posedge tx_clk) begin: i2s_protocol
    case(STATE) 
        sync: begin 
            if(wl != r_wl)   begin 
                if(wl == 0) STATE <= sample_l;
            
                else  STATE    <= sample_r;
                counter <= 0;
            end

            else STATE <= sync;
        end

        sample_l: begin 
            if(counter != 16) begin 
                l_pcm <= {l_pcm[14:0], sda};
                counter <= counter + 1;
            end
            else begin   
                counter <= 0;
                l_val <= l_pcm;
            end
 
            if(r_wl != wl)   STATE <= sample_r;

            end
    

    sample_r: begin 
            if(counter != 16) begin 
                counter <= counter + 1;
                r_pcm <= {r_pcm[14:0], sda};
            end
            else begin 
                    r_val <= r_pcm;
                    counter <= 0;
            end 
            if(r_wl != wl) STATE <= sample_l;
        end


    endcase

end

always @(posedge tx_clk) begin: trace_wl
r_wl <= wl; 
end
endmodule

/*NOTES:
-input FIFO_W
-FIFO is 256
-SAMPLE_RATE: 44.4 kHZ 
-MODULE ONLY WRITES
//TODO: make the FIFO_LEN a parameter 

*/
module FIFO #(parameter FIFO_LEN = 256, parameter SAMPLE_RATE = 48)(input clk, input tx_clk, input logic[15:0] val, input logic[15:0] GETI, output logic HAZARD, output logic[15:0] pcm_val);
logic[7:0]  PUTI;
logic[15:0] counter;
logic[15:0] FIFO[(FIFO_LEN-1):0]

initial begin 
PUTI = 0;
counter = 0;
end


//slave writes(ic chip)
//(counter != (100000)/SAMPLE_RATE --> correct formula
always@(posedge tx_clk) begin 
    if(counter != 30) begin 
        if(PUTI != FIFO_LEN) begin 
            FIFO[PUTI] <= val;
            PUTI <= PUTI + 1;

        end
        else PUTI <= 0;
    end

    else counter <= counter + 1;
end


//FPGA reads
always@(posedge clk) begin 
    pcm_val <= FIFO[GETI]
end


always_comb begin 
    if(PUTI == GETI) HAZARD = 1'b1;
end


endmodule