//consolidation
module registers(input clk, input rst, input logic ir_load, input logic branch_taken, input logic stall, input logic[1:0] src2_fwd, input logic[15:0] writeback_ctrl, input logic[31:0] r_writeback, input logic[31:0] r_execute, input logic[31:0] alu_result, input logic[31:0] alu_bus, input logic[31:0] alu_mem, output logic[31:0] data_in, output logic[31:0] rs1val, output logic[31:0] rs2val, output logic[31:0] pc);
  pc pc_inst(.clk(clk), .rst(rst), .ir_load(ir_load), .branch_taken(branch_taken), .stall(stall), .alu_bus(alu_bus), .r_execute(r_execute), .pc(pc));
  register_file register_file_inst(.clk(clk), .src2_fwd(src2_fwd), .writeback_ctrl(writeback_ctrl), .r_writeback(r_writeback), .r_execute(r_execute), .alu_wb(alu_result), .alu_mem(alu_mem), .strval(data_in), .rs1val(rs1val), .rs2val(rs2val));
endmodule 

                                                        //memory(LD)          //alu(ADD,etc)               
module register_file(
input  logic        clk,  
input  logic[1:0]   src2_fwd,
input  logic[15:0]  writeback_ctrl,
input  logic[31:0]  r_writeback,
input  logic[31:0]  r_execute,
input  logic[31:0]  alu_wb,
input  logic[31:0]  alu_mem,
output logic[31:0]  strval, 
output logic[31:0]  rs1val, 
output logic[31:0]  rs2val);

logic[31:0] REGISTERS[0:31];
logic[31:0] out;
initial begin 
    for(integer i =0; i < 32; i = i+1) REGISTERS[i] = i;
end

//TODO protect against garbage.. : && writing into the zeroth register)
always_ff@(posedge clk) begin 
    if(writeback_ctrl[7] && (r_writeback[11:7] != 5'b0)) begin 
        //3 input mux
        REGISTERS[r_writeback[11:7]] <= alu_wb;
    
    end 

end




always_comb begin : STORE
    out = REGISTERS[r_execute[24:20]];
    case (src2_fwd)
        2'b10: out = alu_mem;
        2'b01: out = alu_wb;
        default: ;
    endcase
end

always_ff @(posedge clk) begin
    strval <= out;
end


assign rs1val     = REGISTERS[r_execute[19:15]];
assign rs2val     = REGISTERS[r_execute[24:20]];

endmodule 


module pc(input clk, 
input rst, 
input ir_load,
input logic branch_taken, 
input logic stall, 
input logic[31:0] alu_bus, 
input logic[31:0] r_execute, 
output logic[31:0] pc);

//use priority encoder again
always_ff @(posedge clk) begin
    if (rst) begin
        pc <= 32'd0;
    end //rst = 0;
    else begin 
        if (branch_taken) begin
            pc <= (r_execute[6:0] == 7'h67)
            ? (alu_bus & 32'hffff_fffe)
            : alu_bus;
        end

        else begin 
            if (ir_load && !stall) begin
                pc <= pc + 32'd4;
            end
        end
    end  
end
endmodule;


 
