module cpu_top (
	input  clk_i,
	input  rst_i,

	// Common memory IOs
	input  merged_mem_ready_i,
	input  [31:0] merged_mem_data_i,
	output merged_mem_rd_o,
	output merged_mem_wr_o,
	output [31:0] merged_mem_addr_o,
	output [31:0] merged_mem_data_o
);

wire instr_mem_ready_s, instr_mem_rd_s;
wire [31:0] instr_mem_data_s, instr_mem_addr_s;

wire data_mem_ready_s, data_mem_rd_s, data_mem_wr_s;
wire [31:0] data_mem_data_i_s, data_mem_addr_s, data_mem_data_o_s;
wire [3:0] byte_select_s;

cpu inst_cpu(
	.clk_i(clk_i),
    .rst_i(rst_i),
	
	// Instruction memory IOs
	.instr_mem_ready_i(instr_mem_ready_s),
	.instr_mem_data_i(instr_mem_data_s),
	.instr_mem_addr_o(instr_mem_addr_s),
	.instr_mem_rd_o(instr_mem_rd_s),

	// Data memory IOs
	.data_mem_ready_i(data_mem_ready_s),
	.data_mem_data_i(data_mem_data_i_s),
	.data_mem_addr_o(data_mem_addr_s),
	.data_mem_data_o(data_mem_data_o_s),
	.data_mem_rd_o(data_mem_rd_s),
	.data_mem_wr_o(data_mem_wr_s),
	.byte_select_o(byte_select_s)
);

memory_arbiter inst_memory_arbiter(
	.clk_i(clk_i),
	.rst_i(rst_i),

	// Instruction memory IOs
	.instr_mem_rd_i(instr_mem_rd_s),
	.instr_mem_addr_i(instr_mem_addr_s),
	.instr_mem_ready_o(instr_mem_ready_s),
	.instr_mem_data_o(instr_mem_data_s),

	// Data memory IOs
	.data_mem_rd_i(data_mem_rd_s),
	.data_mem_wr_i(data_mem_wr_s),
	.data_mem_addr_i(data_mem_addr_s),
	.byte_select_i(byte_select_s),
	.data_mem_data_i(data_mem_data_o_s),
	.data_mem_ready_o(data_mem_ready_s),
	.data_mem_data_o(data_mem_data_i_s),

	// Common memory IOs
	.merged_mem_ready_i(merged_mem_ready_i),
	.merged_mem_data_i(merged_mem_data_i),
	.merged_mem_rd_o(merged_mem_rd_o),
	.merged_mem_wr_o(merged_mem_wr_o),
	.merged_mem_addr_o(merged_mem_addr_o),
	.merged_mem_data_o(merged_mem_data_o)
);

endmodule