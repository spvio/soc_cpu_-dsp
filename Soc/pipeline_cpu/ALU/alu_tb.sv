`timescale 1ns/1ps

module alu_test;
logic        clk;
logic [31:0] execute_pc;
logic [15:0] execute_ctrl;
logic [31:0] r_execute;
logic [31:0] imm_execute;
logic [31:0] rs1val;
logic [31:0] rs2val;
logic [1:0]  src1_fwd;
logic [1:0]  src2_fwd;
logic [31:0] alu_mem;
logic [31:0] alu_wb;
logic [31:0] alu_out;
logic        branch;

alu dut (
    .clk(clk),
    .execute_pc(execute_pc),
    .execute_ctrl(execute_ctrl),
    .r_execute(r_execute),
    .imm_execute(imm_execute),
    .rs1val(rs1val),
    .rs2val(rs2val),
    .src1_fwd(src1_fwd),
    .src2_fwd(src2_fwd),
    .alu_mem(alu_mem),
    .alu_wb(alu_wb),
    .alu_out(alu_out),
    .branch(branch)
);

always #5 clk = ~clk;

task automatic check_branch(
    input logic [2:0] funct3,
    input logic [31:0] lhs,
    input logic [31:0] rhs,
    input logic expected
);
begin
    execute_ctrl[14:12] = funct3;
    rs1val = lhs;
    rs2val = rhs;
    #1;
    if (branch !== expected)
        $error("funct3=%b lhs=%h rhs=%h branch=%b expected=%b",
               funct3, lhs, rhs, branch, expected);
end
endtask

initial begin
    clk          = 1'b0;
    execute_pc   = 32'h0000_0100;
    execute_ctrl = '0;
    r_execute    = '0;
    imm_execute  = 32'd8;
    rs1val       = '0;
    rs2val       = '0;
    src1_fwd     = '0;
    src2_fwd     = '0;
    alu_mem      = '0;
    alu_wb       = '0;

    check_branch(3'b000, 32'd5, 32'd5, 1'b1);          // BEQ
    check_branch(3'b001, 32'd5, 32'd6, 1'b1);          // BNE
    check_branch(3'b100, 32'hffff_ffff, 32'd1, 1'b1);  // BLT
    check_branch(3'b101, 32'd1, 32'hffff_ffff, 1'b1);  // BGE
    check_branch(3'b110, 32'd1, 32'hffff_ffff, 1'b1);  // BLTU
    check_branch(3'b111, 32'hffff_ffff, 32'd1, 1'b1);  // BGEU

    $display("ALU branch-condition tests passed");
    $finish;
end

endmodule
