//tying everything together
module cpu(input clk, input sw);
logic[31:0] ir;
logic[31:0] pc;
logic ir_load;

//RST(POWER_UP).. 
logic rst;

//CPU <--> MEMORY
logic[31:0] data_out;
logic[31:0] data_in;
//internal bus
logic[31:0] alu_bus;

logic mem_enable;
logic r_w;
logic branch_taken;
logic branch;
logic stall;

//REGISTER --> ALU
logic[31:0] rs1val;
logic[31:0] rs2val;


//important register forwarding:
logic[31:0] alu_out;



//important.. pipeline registers
logic[31:0] r_decode;
logic[31:0] r_execute;
logic[31:0] r_memory;
logic[31:0] r_writeback;
logic[31:0] alu_mem;
logic[31:0] alu_wb;
logic[31:0] wb_value;
logic[31:0] imm_execute;
logic[31:0] execute_pc;
logic[31:0] mem_pc;
logic[1:0] src1_fwd;
logic[1:0] src2_fwd;

//control signal pipeline:
logic[15:0] execute_ctrl;
logic[15:0] memory_ctrl;
logic[15:0] writeback_ctrl;
logic[15:0] decode_ctrl;

//signals explicit
logic reg_w;


//F_ALU
logic[1:0] F_ALU;

// Select the value that the MEM/WB stage actually writes back.
always_comb begin
    case (writeback_ctrl[1:0])
        2'b01:   wb_value = data_out;
        2'b10:   wb_value = mem_pc;
        default: wb_value = alu_wb;
    endcase
end


rst rst_inst(.clk(clk), .sw(sw), .rst(rst));
pipeline pipeline_inst(.clk(clk), .rst(rst), .ir(ir), .alu_bus(alu_bus), .pc(pc), .branch(branch), .branch_taken(branch_taken), .ir_load(ir_load), .decode_ctrl_out(decode_ctrl), .execute_ctrl_out(execute_ctrl), .memory_ctrl_out(memory_ctrl), .writeback_ctrl_out(writeback_ctrl), .r_execute(r_execute), .r_memory(r_memory), .r_writeback(r_writeback), .alu_mem(alu_mem), .alu_wb(alu_wb), .imm_execute(imm_execute), .execute_pc(execute_pc), .reg_w1(reg_w), .src1_fwd_out(src1_fwd), .src2_fwd_out(src2_fwd), .mem_pc_out(mem_pc), .stall(stall));
memory memory_inst(.clk(clk), .rst(rst), .stall(stall), .branch_taken(branch_taken), .ir_load(ir_load), .memory_ctrl(memory_ctrl), .pc_bus(pc), .address_bus(alu_mem), .data_in(data_in), .data_out(data_out), .ir(ir));
registers register_inst(.clk(clk), .rst(rst), .ir_load(ir_load), .branch_taken(branch_taken), .stall(stall), .src2_fwd(src2_fwd), .writeback_ctrl(writeback_ctrl), .r_writeback(r_writeback), .r_execute(r_execute), .r_memory(r_memory), .alu_result(wb_value), .data_out(data_out), .alu_bus(alu_bus), .alu_mem(alu_mem), .mem_pc(mem_pc), .data_in(data_in), .pc(pc), .rs1val(rs1val), .rs2val(rs2val));
alu alu_inst(.clk(clk), .execute_pc(execute_pc), .execute_ctrl(execute_ctrl), .r_execute(r_execute), .imm_execute(imm_execute), .rs1val(rs1val), .rs2val(rs2val), .src1_fwd(src1_fwd), .src2_fwd(src2_fwd), .alu_mem(alu_mem), .alu_wb(wb_value), .alu_out(alu_bus), .branch(branch));
endmodule
