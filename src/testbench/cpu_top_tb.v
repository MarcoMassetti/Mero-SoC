//`timescale  1ns/1ps

module cpu_top_tb ();

parameter CLOCK = 20;
reg clk_i_s, rst_i_s;
wire merged_mem_ready_i_s, merged_mem_rd_o_s, merged_mem_wr_o_s;
wire [31:0] merged_mem_data_i_s, merged_mem_addr_o_s, merged_mem_data_o_s;
wire [3:0]  byte_select_s;
wire trap_s;


cpu_top DUT(
	.clk_i(clk_i_s),
    .rst_i(rst_i_s),
	.trap_o(trap_s),

	// Common memory IOs
	.merged_mem_ready_i(merged_mem_ready_i_s),
	.merged_mem_data_i(merged_mem_data_i_s),
	.merged_mem_rd_o(merged_mem_rd_o_s),
	.merged_mem_wr_o(merged_mem_wr_o_s),
	.merged_mem_addr_o(merged_mem_addr_o_s),
	.merged_mem_data_o(merged_mem_data_o_s),
	.byte_select_o(byte_select_s)
);

ram_wrapper inst_ram_wrapper(	
	.clk_i(clk_i_s),
	.read_i(merged_mem_rd_o_s),
	.write_i(merged_mem_wr_o_s),
	.addr_i(merged_mem_addr_o_s[16:2]),
	.data_i(merged_mem_data_o_s),
	
	.mem_ready_o(merged_mem_ready_i_s),
	.data_o(merged_mem_data_i_s),
	.byte_select_i(byte_select_s)
);


//Generation of the clock signal
always begin
	#(CLOCK/2)
	// Toggling clock
	clk_i_s = ~clk_i_s;
end

initial begin
	// Setting reset and initial clock value
	rst_i_s <= 1'b0;
	clk_i_s <= 1'b0;

	#(CLOCK*5)
	// Releasing reset
	rst_i_s <= 1'b1;
end

endmodule
