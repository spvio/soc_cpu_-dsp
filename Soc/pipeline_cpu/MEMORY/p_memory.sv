
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

logic[7:0] BRAM[0:4095];
parameter NOP = 32'b0;


always_ff@(posedge clk) begin 
        
    if(memory_ctrl[6]) begin
        if(memory_ctrl[5]) begin
            case (memory_ctrl[14:12])
                3'b000: data_out <= {{24{BRAM[address_bus][7]}}, BRAM[address_bus]};
                3'b001: data_out <= {{16{BRAM[address_bus][7]}},
                                      BRAM[address_bus], BRAM[address_bus + 1]};
                3'b010: data_out <= {BRAM[address_bus],
                                      BRAM[address_bus + 1],
                                      BRAM[address_bus + 2],
                                      BRAM[address_bus + 3]};
                3'b100: data_out <= {24'b0, BRAM[address_bus]};
                3'b101: data_out <= {16'b0, BRAM[address_bus],
                                      BRAM[address_bus + 1]};
                default: data_out <= 32'b0;
            endcase
        end
        else begin
            case (memory_ctrl[14:12])
                3'b000: BRAM[address_bus] <= data_in[7:0];
                3'b001: {BRAM[address_bus],
                          BRAM[address_bus + 1]} <= data_in[15:0];
                3'b010: {BRAM[address_bus],
                          BRAM[address_bus + 1],
                          BRAM[address_bus + 2],
                          BRAM[address_bus + 3]} <= data_in;
                default: ;
            endcase
        
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
