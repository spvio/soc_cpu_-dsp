//tx_clock - 3.429(board runs x29.1)
//notes sda => serial data line 

module i2s_fifo#(parameter FIFO_LEN = 256)(
    input  logic clk,
    input  logic tx_clk,
    input  logic wl,
    input  logic sda,
    input  logic read_enable,
    output logic [15:0] read_data,
    output logic fifo_full,
    output logic fifo_empty,
    output logic read_valid
);
//i2s 

logic[15:0] l_pcm;
logic ready_l;
//fifo


i2s i2s_inst(.tx_clk(tx_clk), .wl(wl), .sda(sda), .l_pcm(l_pcm), .r_pcm(), .ready_l(ready_l), .ready_r());
FIFO #(.FIFO_LEN(FIFO_LEN)) l_FIFO (
    .clk(clk),
    .tx_clk(tx_clk),
    .val(l_pcm),
    .write_enable(ready_l),
    .read_enable(read_enable),
    .o_pcm(read_data),
    .fifo_full(fifo_full),
    .fifo_empty(fifo_empty),
    .read_valid(read_valid)
);

endmodule 


module i2s(input tx_clk, input wl, input sda, output logic ready_r, output logic ready_l, output logic[15:0] l_pcm, output logic[15:0] r_pcm);
logic[7:0] counter;
logic r_wl;
logic[1:0] STATE;

//for now
initial begin 
    counter = 0;
    r_pcm = 0;
    l_pcm = 0;
    STATE   = 0;
    r_wl = 0;
    ready_l = 0;
    ready_r = 0;

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
            ready_l <= 1'b0;
            ready_r <= 1'b0;
        end

        sample_l: begin 

            if(counter != 16) begin 
                l_pcm <= {l_pcm[14:0], sda};
                counter <= counter + 1;
                ready_l <= 1'b0;
        
            end
            else begin   
                counter <= 0;
                ready_l <= 1'b1;
            end
 
            if(r_wl != wl)   STATE <= sample_r;
            ready_r <= 1'b0;

            end
    

    sample_r: begin 
            if(counter != 16) begin 
                counter <= counter + 1;
                r_pcm <= {r_pcm[14:0], sda};
                ready_r <= 1'b0;
            end
            else begin 
                    counter <= 0;
                    ready_r <= 1'b1;
            end 
            if(r_wl != wl) STATE <= sample_l;
            ready_l <= 1'b0;
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
//TODO: FIX ASYCHRONOUS FIFO

*/
module FIFO #(parameter FIFO_LEN = 256)(input clk, input tx_clk, input logic[15:0] val,  input logic write_enable,  output logic[15:0] o_pcm,
input  logic read_enable,
output logic read_valid,
output logic fifo_empty,
output logic fifo_full);

logic[15:0] FIFO[(FIFO_LEN-1):0];

logic[8:0] wr_ptr;
logic[8:0] wr_ptr_next;
logic[8:0] wire_ptr;
logic[8:0] wr_ptr_gray;
logic[8:0] wr_ptr_bin;

logic[8:0] rd_ptr;
logic[8:0] rd_ptr_next;
logic[8:0] wire_rd_ptr;
logic[8:0] rd_ptr_gray;
logic[8:0] rd_ptr_bin;




//synchronizer flip-flop-1:
logic[8:0] wr_sync_1;
logic[8:0] wr_sync_2;

logic[8:0] rd_sync_1;
logic[8:0] rd_sync_2;

initial begin 
    fifo_empty = 1'b1;
    fifo_full = 1'b0;
    read_valid = 1'b0;
    wr_ptr = '0;
    rd_ptr = '0;
    wr_sync_1 = '0;
    wr_sync_2 = '0;
    rd_sync_1 = '0;
    rd_sync_2 = '0;
    o_pcm = '0;

end


//slave writes(ic chip)
//(counter != (100000)/SAMPLE_RATE --> correct formula
always@(posedge tx_clk) begin: write
        if(write_enable && !fifo_full) begin 
            FIFO[wr_ptr[7:0]] <= val;
            wr_ptr <= wr_ptr_next;
        end
        //sync_flipflops
     rd_sync_1 <= rd_ptr_gray;
     rd_sync_2 <= rd_sync_1;
     fifo_full <= (wr_ptr_next[8] != rd_ptr_bin[8]) && (wr_ptr_next[7:0] == rd_ptr_bin[7:0]);


    end


always_comb begin 

    wr_ptr_next = wr_ptr + (write_enable && !fifo_full);

    //bin -> gray-code conversion
    wire_ptr = (wr_ptr >> 1) ^ wr_ptr;
    wr_ptr_gray = wire_ptr;

    //gray -> bin
    rd_ptr_bin[8] = rd_sync_2[8];
    for (int i = 7; i >= 0; i--) begin
        rd_ptr_bin[i] = rd_sync_2[i] ^ rd_ptr_bin[i+1];
    end


end

   

always@(posedge clk) begin: read
    wr_sync_1 <= wr_ptr_gray;
    wr_sync_2 <= wr_sync_1;
    //reading
    if(read_enable && !fifo_empty) begin 
        o_pcm <=  FIFO[rd_ptr[7:0]];
        rd_ptr <= rd_ptr_next;
        read_valid <= 1'b1;
    end
    else read_valid <= 1'b0;
    fifo_empty <= (rd_ptr_next == wr_ptr_bin);


end



always_comb begin //clk
    rd_ptr_next = rd_ptr + (read_enable && !fifo_empty);

    wr_ptr_bin[8] = wr_sync_2[8];
    for (int i = 7; i >= 0; i--) begin
        wr_ptr_bin[i] = wr_sync_2[i] ^ wr_ptr_bin[i+1];
    end
   
    //bin -> gray
    wire_rd_ptr = (rd_ptr >> 1) ^ rd_ptr;
    rd_ptr_gray = wire_rd_ptr;

    end



endmodule
