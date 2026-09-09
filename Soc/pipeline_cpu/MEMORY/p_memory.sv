
module memory(
input clk, 
input rst, 
input stall,
input branch_taken,
input ir_load,
input   logic[15:0] memory_ctrl,
input   logic[31:0] pc_bus,
input   logic[31:0] address_bus, 
input   logic[31:0] data_in, 
output  logic[31:0] data_out, 
output  logic[31:0] ir);

logic[7:0] BRAM[0:127];
parameter NOP = 32'b0;


always_ff@(posedge clk) begin 
        
    if(memory_ctrl[6]) begin
        if(memory_ctrl[5]) begin
            data_out <= {BRAM[address_bus],
                         BRAM[address_bus + 1],
                         BRAM[address_bus + 2],
                         BRAM[address_bus + 3]};  //load word
        end
        else begin
            {BRAM[address_bus],
             BRAM[address_bus + 1],
             BRAM[address_bus + 2],
             BRAM[address_bus + 3]} <= data_in;  //store word
        
    end
end
end

always_ff@(posedge clk) begin : FETCH
    if (rst) begin
        ir <= NOP;
    end
    else if(branch_taken) begin 
        ir <= NOP;
    end

    else begin 
    if(ir_load && !(stall)) begin 
        ir  <=  {BRAM[pc_bus], 
        BRAM[pc_bus+1],
        BRAM[pc_bus +2], 
        BRAM[pc_bus +3]};
    end


    end
end



endmodule
