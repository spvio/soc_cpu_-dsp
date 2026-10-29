module dsp_unit#(
parameter FIFO_LEN = 256,
parameter SIN_LUT_FILE = "DSP_UNIT/sin_lut.txt",
parameter COS_LUT_FILE = "DSP_UNIT/cos_lut.txt"
)(
input  logic clk,
input  logic tx_clk,
input  logic wl,
input  logic sda,
output logic fifo_full,
output logic fifo_empty,
output logic result_valid,
output logic signed[31:0] BINS_R[(FIFO_LEN-1):0],
output logic signed[31:0] BINS_I[(FIFO_LEN-1):0]);

logic[15:0] read_data;
logic read_enable;
logic read_valid;

i2s_fifo#(.FIFO_LEN(FIFO_LEN)) i2s_fifo_inst(
    .clk(clk),
    .tx_clk(tx_clk),
    .wl(wl),
    .sda(sda),
    .read_enable(read_enable),
    .read_data(read_data),
    .fifo_full(fifo_full),
    .fifo_empty(fifo_empty),
    .read_valid(read_valid)
);

fourier#(
    .FIFO_LEN(FIFO_LEN),
    .SIN_LUT_FILE(SIN_LUT_FILE),
    .COS_LUT_FILE(COS_LUT_FILE)
) fourier_inst(
    .clk(clk),
    .fifo_empty(fifo_empty),
    .read_valid(read_valid),
    .pcm_value(read_data),
    .read_enable(read_enable),
    .result_valid(result_valid),
    .BINS_R(BINS_R),
    .BINS_I(BINS_I)
);

endmodule
