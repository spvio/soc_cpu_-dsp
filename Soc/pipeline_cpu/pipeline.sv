//reg_w is only 1'b1 during a LOAD


//rst in pipeline(logic signal)
module pipeline(
input clk, 
input rst,
input logic[31:0] ir, 
input logic[31:0] alu_bus,
input logic[31:0] pc,
input logic branch,
output logic branch_taken,
output logic ir_load,  
output logic[15:0] decode_ctrl_out,
output logic[15:0] execute_ctrl_out,
output logic[15:0] memory_ctrl_out,
output logic[15:0] writeback_ctrl_out,
output logic[31:0] r_execute, 
output logic[31:0] r_memory,
output logic[31:0] r_writeback,
output logic[31:0] alu_mem,
output logic[31:0] alu_wb,
output logic[31:0] imm_execute,
output logic[31:0] execute_pc,
output logic reg_w1,
output logic[1:0] src1_fwd_out,
output logic[1:0] src2_fwd_out,
output logic[31:0] mem_pc_out,
output logic stall);




typedef struct packed {
logic isjmp;
logic[2:0] branch_func3;
logic[3:0] alu_func4;
logic reg_wr;q

logic mem_enable;
logic rd_wr;    //(1: rd, 0: wr)
logic isbranch;
logic src1; //(1: rs1, 0: pc)
logic src2; //(1: rs2, 0: imm)
logic[1:0] wb_s; //(00: alu_imm, 01: data_out,  10:pc_mem )
}control_t;
localparam control_t NOP_ctrl = '0;

//pipeline for control signals:
control_t decode_ctrl;
control_t execute_ctrl;
control_t memory_ctrl;
control_t writeback_ctrl;

typedef struct packed {
    logic MEM_EXEC;
    logic EXEC_WB;
} forward_t;

forward_t src1_fwd;
forward_t src2_fwd;

assign decode_ctrl_out    = decode_ctrl;
assign execute_ctrl_out   = execute_ctrl;
assign memory_ctrl_out    = memory_ctrl;
assign writeback_ctrl_out = writeback_ctrl;
assign src1_fwd_out       = src1_fwd;
assign src2_fwd_out       = src2_fwd;
assign branch_taken       = (execute_ctrl.isbranch && branch) || execute_ctrl.isjmp;




//pipeline registers(sake of simplicity going to carry IR)
logic[31:0]imm_decode;
//logic[31:0]r_decode;
//logic[31:0]r_execute;
//control signal pipeline
logic[8:0] r_1;

//pc pipeline:
logic[31:0] fetch_pc;
logic[31:0] requested_pc;
logic[31:0] memory_pc;
logic[31:0] writeback_pc;

assign mem_pc_out = memory_pc;

always@(posedge clk) begin: track_rst
    ir_load <= !(rst);
end

//
always_ff @(posedge clk) begin: FETCH_PC
    if (rst)
        fetch_pc <= 32'd0;
    else if (ir_load && !stall)
        fetch_pc <= pc;
end
               
//ir is written into the register at this point
always_comb begin: decode
            decode_ctrl = '0;

            //load
            case(ir[6:0])
            7'h03: begin: LW_I_TYPE
                decode_ctrl.alu_func4  = 4'b0000;
                decode_ctrl.reg_wr     = 1'b1;
                decode_ctrl.mem_enable = 1'b1;
                decode_ctrl.rd_wr      = 1'b1;
                decode_ctrl.isbranch   = 1'b0;
                decode_ctrl.src1       = 1'b1;
                decode_ctrl.src2       = 1'b0;
                decode_ctrl.wb_s       = 2'b01;
            end

            7'h23: begin: SW_S_TYPE
                decode_ctrl.alu_func4   = 4'b0000;
                decode_ctrl.reg_wr  = 1'b0;
                decode_ctrl.mem_enable = 1'b1;
                decode_ctrl.rd_wr  = 1'b0;
                decode_ctrl.isbranch = 1'b0;
                decode_ctrl.src1   = 1'b1;
                decode_ctrl.src2   = 1'b0;
            end


            //tells alu how to behave
            7'h13: begin: ALU_I_Type
                // Bit 30 selects SRLI/SRAI only. For every other I-type ALU
                // instruction it is part of the immediate, not the ALU op.
                decode_ctrl.alu_func4   = {
                    (ir[14:12] == 3'b101) && ir[30],
                    ir[14:12]
                };
                decode_ctrl.reg_wr      = 1'b1;
                decode_ctrl.mem_enable  = 1'b0;
                decode_ctrl.isbranch      = 1'b0;
                decode_ctrl.src1        = 1'b1;
                decode_ctrl.src2        = 1'b0;
                decode_ctrl.wb_s        = 2'b00;
        

            end
            7'h33: begin : ALU_R_Type
                decode_ctrl.alu_func4   = {ir[30], ir[14:12]};
                decode_ctrl.reg_wr      = 1'b1;
                decode_ctrl.mem_enable  = 1'b0;
                decode_ctrl.isbranch  = 1'b0;
                decode_ctrl.src1    = 1'b1;
                decode_ctrl.src2    = 1'b1;
                decode_ctrl.wb_s    = 2'b00;


            end

            7'h63: begin : BRANCH_B_TYPE
                decode_ctrl.branch_func3 = ir[14:12];
                decode_ctrl.alu_func4    =  4'b0000; //ADD
                decode_ctrl.reg_wr       =  1'b0;
                decode_ctrl.mem_enable   =  1'b0;
                decode_ctrl.isbranch     =  1'b1;
                decode_ctrl.src1         =  1'b0;
                decode_ctrl.src2         =  1'b0;
            end

            default: begin 
                decode_ctrl = '0;
            end


            //jal stays in add
            7'h6f: begin: JAL_J_TYPE
                decode_ctrl.branch_func3 = 3'bxxx;
                decode_ctrl.alu_func4    = 4'b0000; //add
                decode_ctrl.reg_wr       = 1'b1;
                decode_ctrl.mem_enable   = 1'b0;
                decode_ctrl.isbranch     = 1'b0;
                decode_ctrl.isjmp        = 1'b1;
                decode_ctrl.src1         = 1'b0; //pc
                decode_ctrl.src2         = 1'b0; //immm
                decode_ctrl.wb_s         = 2'b10;
            end

            7'h67: begin: JAL_I_TYPE
                decode_ctrl.branch_func3 = 3'bxxx;
                decode_ctrl.alu_func4    = 4'b0000;
                decode_ctrl.reg_wr       = 1'b1;
                decode_ctrl.mem_enable   = 1'b0;
                decode_ctrl.isbranch     = 1'b0;
                decode_ctrl.isjmp        = 1'b1;
                decode_ctrl.src1         = 1'b1; //rs1
                decode_ctrl.src2         = 1'b0; //immm
                decode_ctrl.wb_s         = 2'b10;//pc_mem;
            end

            endcase
end

always_comb begin: immediate_decode
    case (ir[6:0])
        // I-type immediates: LW and ALU-immediate instructions.
        7'h03, 7'h13:
            imm_decode = {{20{ir[31]}}, ir[31:20]};

        // S-type immediate: stores.
        7'h23:
            imm_decode = {{20{ir[31]}}, ir[31:25], ir[11:7]};
        
        

        7'h63:
            imm_decode = {{19{ir[31]}}, ir[31], ir[7], ir[30:25],
                          ir[11:8], 1'b0};

        // J-type immediate: JAL.
        7'h6F:
            imm_decode = {{11{ir[31]}}, ir[31], ir[19:12],
                          ir[20], ir[30:21], 1'b0};
        7'h67:
            imm_decode = {{20{ir[31]}},ir[31:20]};

        default:
            imm_decode = 32'd0;
    endcase
end

always_ff@(posedge clk) begin: execute
//keep og pc_val
    if (rst) begin
        r_execute    <= 32'b0;
        execute_ctrl <= NOP_ctrl;
        imm_execute  <= 32'b0;
        execute_pc   <= 32'b0;
    end
    else if(!(stall ^ branch_taken)) begin
        r_execute    <= ir;
        execute_ctrl <= decode_ctrl;
        imm_execute  <= imm_decode;
        execute_pc   <= fetch_pc;
    end
    else begin  
        r_execute    <=  32'b0;
        execute_ctrl <= NOP_ctrl;
        imm_execute  <= 32'd0;
        execute_pc   <= fetch_pc;
    end
end  


always_ff@(posedge clk) begin: memory
    if (rst) begin
        memory_pc   <= 32'b0;
        memory_ctrl <= NOP_ctrl;
        r_memory    <= 32'b0;
        alu_mem     <= 32'b0;
    end
    else begin
        memory_pc      <= execute_pc;
        memory_ctrl    <= execute_ctrl;
        r_memory       <= r_execute;
        alu_mem        <= alu_bus;
    end
end


//store mem_pc
always_ff@(posedge clk) begin: writeback
    if (rst) begin
        alu_wb         <= 32'b0;
        writeback_ctrl <= NOP_ctrl;
        writeback_pc   <= 32'b0;
        r_writeback    <= 32'b0;
    end
    else begin
        alu_wb          <= alu_mem;
        writeback_ctrl  <= memory_ctrl;
        writeback_pc    <= memory_pc;
        r_writeback     <= r_memory;
    end
end






always_comb begin: STALL
    stall = 1'b0;

    if (execute_ctrl.mem_enable &&
        execute_ctrl.rd_wr &&
        (r_execute[11:7] != 5'd0) &&
        (((decode_ctrl.src1 || decode_ctrl.isbranch) &&
          (ir[19:15] == r_execute[11:7])) ||
         ((decode_ctrl.src2 || decode_ctrl.isbranch ||
           ir[6:0] == 7'h23) &&
          (ir[24:20] == r_execute[11:7])))) begin
        stall = 1'b1;
    end
end




//FORWARD
always_comb begin: FORWARD
    // Default to the register-file operands.
    src1_fwd = '0;
    src2_fwd = '0;

    // EX/MEM has priority because it contains the newer result.
    if (memory_ctrl.reg_wr &&
        (r_memory[11:7] != 5'd0) &&
        (r_execute[19:15] == r_memory[11:7])) begin
        src1_fwd.MEM_EXEC = 1'b1;
        src1_fwd.EXEC_WB  = 1'b0;
    end
    else if (writeback_ctrl.reg_wr &&
             (r_writeback[11:7] != 5'd0) &&
             (r_execute[19:15] == r_writeback[11:7])) begin
        src1_fwd.MEM_EXEC = 1'b0;
        src1_fwd.EXEC_WB  = 1'b1;
    end

    // An immediate instruction does not use rs2 as an ALU operand.
    if (execute_ctrl.src2 || r_execute[6:0] == 7'h23 || execute_ctrl.isbranch) begin
        if (memory_ctrl.reg_wr &&
            (r_memory[11:7] != 5'd0) &&
            (r_execute[24:20] == r_memory[11:7])) begin
            src2_fwd.MEM_EXEC = 1'b1;
            src2_fwd.EXEC_WB  = 1'b0;
        end
        else if (writeback_ctrl.reg_wr &&
                 (r_writeback[11:7] != 5'd0) &&
                 (r_execute[24:20] == r_writeback[11:7])) begin
            src2_fwd.MEM_EXEC = 1'b0;
            src2_fwd.EXEC_WB  = 1'b1;
        end
    end
end







endmodule
