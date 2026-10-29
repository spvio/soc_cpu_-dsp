//alu_out,(wire) --> alu_out(register)

//consildations stage
module alu(
input logic[31:0] execute_pc,
input logic[15:0] execute_ctrl,
input logic[31:0] r_execute,
input logic[31:0] imm_execute,
input logic[31:0] rs1val,
input logic[31:0] rs2val,
input logic[1:0] src1_fwd,
input logic[1:0] src2_fwd,
input logic[31:0] alu_mem,
input logic[31:0] alu_wb,
output logic[31:0] alu_out,
output logic branch);
//intermediate wires
logic[31:0] w_val1;
logic[31:0] w_val2;
logic[31:0] val1_fwd;
logic[31:0] val2_fwd;

mux_forward mux_forward_inst(
    .execute_ctrl(execute_ctrl),
    .rs1val(rs1val),
    .rs2val(rs2val),
    .src1_fwd(src1_fwd),
    .src2_fwd(src2_fwd),
    .alu_mem(alu_mem),
    .alu_wb(alu_wb),
    .val1_fwd(val1_fwd),
    .val2_fwd(val2_fwd)
);

mux_select mux_select_inst(
    .execute_ctrl(execute_ctrl),
    .val1_fwd(val1_fwd),
    .val2_fwd(val2_fwd),
    .imm(imm_execute),
    .execute_pc(execute_pc),
    .val1(w_val1),
    .val2(w_val2)
);

alu_main alu_main_inst(.execute_ctrl(execute_ctrl), .r_execute(r_execute), .val1(w_val1), .val2(w_val2), .alu_out(alu_out));
condition_code condition_code_inst(
    .rs1val(val1_fwd),
    .rs2val(val2_fwd),
    .branch(branch),
    .exec_ctrl(execute_ctrl[14:12])
);


endmodule 




//* TODO: Forwarding
module mux_forward(
 input  logic[15:0] execute_ctrl,
 input  logic[31:0] rs1val, 
 input  logic[31:0] rs2val,
 input  logic[1:0] src1_fwd,
 input  logic[1:0] src2_fwd, 
 input  logic[31:0] alu_mem,
 input  logic[31:0] alu_wb, 
 output logic[31:0] val1_fwd, 
 output logic[31:0] val2_fwd);

always_comb begin
    val1_fwd = rs1val;
    val2_fwd = rs2val;
    if (execute_ctrl[3] || execute_ctrl[4]) begin
        case (src1_fwd)
            2'b10: val1_fwd = alu_mem;
            2'b01: val1_fwd = alu_wb;
            default: ;
        endcase
    end

    if (execute_ctrl[2] || execute_ctrl[4]) begin
        case (src2_fwd)
            2'b10: val2_fwd = alu_mem;
            2'b01: val2_fwd = alu_wb;
            default: ;
        endcase
    end
end

endmodule 

module mux_select( 
    input  logic[15:0] execute_ctrl,
    input  logic[31:0] val1_fwd,
    input  logic[31:0] val2_fwd,
    input  logic[31:0] imm,
    input  logic[31:0] execute_pc,
    output logic[31:0] val1,
    output logic[31:0] val2
);

always_comb begin
    val1 = execute_ctrl[3] ? val1_fwd : execute_pc;

    if(!execute_ctrl[2]) val2 = imm;
    else val2 = val2_fwd;

end

endmodule



//execution state: outputs an alu register
module alu_main(
input   logic[15:0] execute_ctrl,
input   logic[31:0] r_execute, 
input   logic[31:0] val1, 
input   logic[31:0] val2, 
output  logic[31:0] alu_out);






always_comb begin : ALU_DECODE
    alu_out = 32'b0;
    if (r_execute[6:0] == 7'h37)
        alu_out = val2;
    else case(execute_ctrl[11:8])
        4'b0000: alu_out = val1 + val2;
        //STLI 2: ouputs a 1 if less than
        4'b1000: alu_out = val1 - val2;
        4'b0010: alu_out = ($signed(val1) < $signed(val2)) ? 32'd1 : 32'd0;
        //usigned im tal
        4'b0011: alu_out = (val1 < val2) ? 32'd1 : 32'd0;
        4'b0100: alu_out = val1 ^ val2;
        4'b0110: alu_out = val1 | val2;
        4'b0111: alu_out = val1 & val2;
        //left shift 
        4'b0001: alu_out = val1 << val2[4:0];
        //right shift
        4'b0101: begin
            if (r_execute[30])
                alu_out = $signed(val1) >>> val2[4:0];
            else
                alu_out = val1 >> val2[4:0];
        end
        default: alu_out = 32'b0;
    endcase
end



endmodule

module condition_code( 
    input logic[2:0] exec_ctrl,
    input logic[31:0] rs1val,
    input logic[31:0] rs2val,
    output logic branch
);
logic[32:0]  subs_res;
typedef struct packed{
    logic eq;    
    logic ovrflw;
    logic carry;
    logic sign;

} branch_t;

branch_t cc_ctrl; //control codes

//setting imp ortant register values
always_comb begin: CONTROL_CODE
    subs_res       = {1'b1, rs1val} - {1'b0, rs2val};
    cc_ctrl.eq     = (subs_res[31:0] == '0);
    cc_ctrl.sign   =  subs_res[31];
    cc_ctrl.carry  = (!subs_res[32]);
    cc_ctrl.ovrflw = (rs1val[31] ^ rs2val[31]) &
                     (rs1val[31] ^ subs_res[31]);
end

//*if usinged brnach if overflow -> less than 
//else 

always_comb begin: BRANCH_DECODE
        branch = 1'b0;
        case(exec_ctrl)
                3'b000:  branch = cc_ctrl.eq;                         // BEQ
                3'b001:  branch = !cc_ctrl.eq;                        // BNE
                3'b100:  branch = cc_ctrl.ovrflw ^ cc_ctrl.sign;      // BLT
                3'b101:  branch = !(cc_ctrl.ovrflw ^ cc_ctrl.sign);   // BGE
                3'b110:  branch = cc_ctrl.carry;                      // BLTU
                3'b111:  branch = !cc_ctrl.carry;                     // BGEU
                default: branch = 1'b0;
        endcase
end
endmodule
