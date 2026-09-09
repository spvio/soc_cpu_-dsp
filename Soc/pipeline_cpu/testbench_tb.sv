//QuickNotes:
//Task freezes the line until the delays execute

`timescale 1ns/1ps
module testbench();




logic clk;
logic sw;
integer program_address;
initial     clk = 0;

always  #1   clk = ~clk;    //sake of simplicity of reset 

cpu dut(.clk(clk), .sw(sw));
initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, testbench);

    program_address = 0;
    test_flushing();
    //test_st_ld();
    $finish;

end

task start();
begin 
sw = 1'b1; #2;
sw = 1'b0; #3;
sw = 1'b1; #1;
sw = 1'b0; #5;
sw = 1'b1; #26;
sw = 1'b0; #1;
end
endtask


function automatic logic[31:0] rv_lw(
    input logic [4:0] rd,
    input logic [4:0] rs1,
    input logic [11:0] imm
);
begin 
    rv_lw = {
    imm,
    rs1,
    3'b010,
    rd,
    7'h03
    };

end
endfunction


function automatic logic[31:0] rv_sw(
    input logic [4:0]  rs2,
    input logic [4:0]  rs1,
    input logic [11:0] imm
);
begin
    rv_sw = {
        imm[11:5],
        rs2,
        rs1,
        3'b010,
        imm[4:0],
        7'h23
    };
end
endfunction


function automatic logic[31:0] rv_add(
    input logic [4:0] rd,
    input logic [4:0] rs1,
    input logic [4:0] rs2
);
begin 
    rv_add = {
    7'b0000000,
    rs2,
    rs1,
    3'b000,
    rd,
    7'b0110011
};
end
endfunction

function automatic logic[31:0] rv_jal(
    input logic [4:0] rd,
    input logic [20:0] imm
);
begin
    rv_jal = {
        imm[20],
        imm[10:1],
        imm[11],
        imm[19:12],
        rd,
        7'h6f
    };
end
endfunction

function automatic logic[31:0] addi(
    input logic[4:0] rd,
    input logic[4:0] rs1,
    input logic[11:0] imm
);
begin 
    addi = {
        imm,
        rs1,
        3'b000,
        rd,
        7'h13};
end
endfunction


function automatic logic[31:0] rv_nop();
begin 
        rv_nop = 32'h00000000;

end
endfunction

//func3
function automatic logic[31:0]  rv_branch(
    input logic[13:0] imm12,
    input logic[4:0] rs2,
    input logic[4:0] rs1,
    input logic[2:0] func3
);
begin 
    rv_branch = {imm12[12],
               imm12[10:5],
               rs2, 
               rs1,
               func3, 
               imm12[4:1],
               imm12[11],
               7'h63};
end
begin 




end


endfunction


task automatic put_instruction(
    input integer address,
    input logic [31:0] instruction
);
begin
    dut.memory_inst.BRAM[address]     = instruction[31:24];
    dut.memory_inst.BRAM[address + 1] = instruction[23:16];
    dut.memory_inst.BRAM[address + 2] = instruction[15:8];
    dut.memory_inst.BRAM[address + 3] = instruction[7:0];
end
endtask

task automatic emit(input logic[31:0] instruction);
begin 
    
    put_instruction(program_address, instruction);
    program_address = program_address + 4;
end
endtask

task automatic expect_writeback(
    input logic [31:0] instruction,
    input logic [4:0] expected_rd,
    input logic [31:0] expected_value
);
    integer cycles;
    logic found;
begin 
    found = 1'b0;
    for(cycles = 0; cycles < 50; cycles = cycles + 1) begin 
        @(posedge clk);
        if(dut.r_writeback === instruction) begin 
            #1ps;
            @(posedge clk)
            assert (dut.register_inst.register_file_inst.REGISTERS[expected_rd] === expected_value) begin
                $display("PASS: x%0d = %0d", expected_rd, expected_value);
                $display("CYCLE:%d", cycles);
            end
            else 

                $fatal(
                    1,
                    "FAIL: x%0d was %0d, expected %0d , CYCLE:%d, instruction:%h", 
                    expected_rd,
                    dut.register_inst.register_file_inst.REGISTERS[expected_rd],
                    expected_value,
                    cycles,
                    instruction
                );

            found = 1'b1;
            break;
        end
    end
    
    if (!found)
        $fatal(
            1,
            "TIMEOUT: instruction %h never reached writeback",
            instruction
        );
end
endtask



task automatic expect_store(
    input logic [31:0] instruction,
    input logic [31:0] expected_address,
    input logic [31:0] expected_value
);
    integer cycles;
    logic found;
    logic [31:0] stored_value;
begin
    found = 1'b0;

    for(cycles = 0; cycles < 100; cycles = cycles + 1) begin
        @(posedge clk);

        if(dut.r_memory === instruction) begin
            @(posedge clk);
            #1ps;
            stored_value = {
                dut.memory_inst.BRAM[expected_address],
                dut.memory_inst.BRAM[expected_address + 1],
                dut.memory_inst.BRAM[expected_address + 2],
                dut.memory_inst.BRAM[expected_address + 3]
            };

            assert(stored_value === expected_value) begin
                $display(
                    "PASS: SW memory[%0d] = %0d",
                    expected_address,
                    stored_value
                );
                $display("CYCLE:%d", cycles);
            end

            else
                $fatal(
                    1,
                    "FAIL: SW memory[%0d] was %0d, expected %0d",
                    expected_address,
                    stored_value,
                    expected_value
                );

            found = 1'b1;
            break;
        end
    end

    if(!found)
        $fatal(
            1,
            "TIMEOUT: SW instruction %h never reached memory",
            instruction
        );
end
endtask

task automatic expect_load(
    input logic [31:0] instruction,
    input logic [4:0]  expected_rd,
    input logic [31:0] expected_value
);
    integer cycles;
    logic found;
begin
    found = 1'b0;

    for (cycles = 0; cycles < 1000; cycles = cycles + 1) begin
        @(posedge clk);

        if (dut.r_memory === instruction) begin
            @(posedge clk);
            #1ps;

            assert (
                dut.register_inst.register_file_inst.REGISTERS[expected_rd]
                === expected_value
            ) begin
                $display(
                    "PASS: LW x%0d = %0d, CYCLE:%0d",
                    expected_rd,
                    expected_value,
                    cycles
                );
            end
            else
                $fatal(
                    1,
                    "FAIL: LW x%0d was %0d, expected %0d",
                    expected_rd,
                    dut.register_inst.register_file_inst.REGISTERS[expected_rd],
                    expected_value
                );

            found = 1'b1;
            break;
        end
    end

    if (!found)
        $fatal(
            1,
            "TIMEOUT: LW instruction %h never reached memory",
            instruction
        );
end
endtask

task correct_alu();


endtask



task automatic test_fw_alu();
    emit(rv_add(5, 1, 3));
    emit(rv_add(6, 5, 1));
    emit(rv_add(1, 6, 5));
    start();
    fork
    expect_writeback(rv_add(5,1,3), 5, 4);
    expect_writeback(rv_add(6,5,1), 6, 5);
    expect_writeback(rv_add(1,6,5), 1, 9);
    join
endtask

task automatic test_fw_st(); //mem<--wb
    emit(rv_add(1,3,4));
    emit(rv_add(7,1,8));
    emit(rv_sw (7,4,16));
    start();
    fork
    expect_writeback(rv_add(7,1,8), 7, 15);
    expect_store(rv_sw(7,4,16), 20, 15);
    join

endtask


task automatic test_st_ld();
    emit(rv_sw(20, 4, 16));
    emit(rv_lw(7, 4, 16));
    emit(rv_add(1, 6, 7)); 
    start();
    fork
    expect_store(rv_sw(20,4,16), 20, 20);
    expect_load(rv_lw(7,4,16), 7, 20);
    expect_writeback(rv_add(1,6,7), 1, 26);
    join
endtask 



task automatic test_flushing();

    emit(rv_add(1, 1, 2)); //(0-3)
    emit(rv_branch(4, 1, 3, 3'b000)); //offset shoudl ne 8 (4-7)
    emit(rv_add(1,1,4)); //(8-b)
    emit(rv_add(1,1,4)); //(12-15)
    emit(rv_add(1,1,4));
    emit(rv_add(1,1,4));
    emit(rv_add(1,1,5));
    emit(rv_add(2,3,4));
    fork 
    start();
    expect_writeback(rv_add(1,1,2), 1, 3);
    expect_writeback(rv_add(1,1,4), 1, 7);
    //$display("REIGISTER_rs1:%d", dut.pipeline_inst.r_execute[24:20]);
    join
    //$display("REGISTER 1:%d", dut.register_inst.register_file_inst.REGISTERS[1]);
    //$display("REIGISTER_rs1:%d", dut.pipeline_inst.r_execute[24:20]);
endtask 
endmodule
