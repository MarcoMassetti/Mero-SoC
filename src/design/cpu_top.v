module cpu_top (
	input  clk_i,
	input  rst_i
);

// Signals between cpu and memory arbitrer
// Intruction memory interface
wire instr_mem_ready_s, instr_mem_rd_s;
wire [31:0] instr_mem_data_s, instr_mem_addr_s;
// Data memory interface
wire data_mem_ready_s, data_mem_rd_s, data_mem_wr_s;
wire [31:0] data_mem_data_i_s, data_mem_addr_s, data_mem_data_o_s;


// Signals between memory arbitrer and memory
wire merged_mem_ready_s, merged_mem_rd_s, merged_mem_wr_s;
wire [31:0] merged_mem_data_i_s, merged_mem_addr_s, merged_mem_data_o_s;
wire [3:0]  byte_select_s;


//// Signals used for AXI master interface
// Read Address (AR) channel
wire arvalid_s, aready_s;
wire [31:0] araddr_s;
// Read Data (R) channel
wire rvalid_s, rready_s, rlast_s;
wire [31:0] rdata_s;
wire [1:0] rresp_s;
// Write Address (AW) channel
wire awvalid_s, awready_s;
wire [31:0] awaddr_s;
// Write Data (W) channel
wire wvalid_s, wready_s, wlast_s;
wire [31:0] wdata_s;
// Write Response (B) channel
wire bvalid_s, bready_s;
wire [1:0] bresp_s;


// Signals for memory/axi handling
wire axi_ready_s;
wire bus_ready_s;
wire [31:0] axi_data_s;
reg  [31:0] bus_data_s;
reg  axi_rd_en_s, axi_wr_en_s;
reg  ram_rd_en_s, ram_wr_en_s;


// CPU instantiation
cpu inst_cpu(
	.clk_i(clk_i),
    .rst_i(rst_i),
	.trap_o(),
	
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


// Merging of instrunction and data memory interfaces
//  into a single interface
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
	.data_mem_data_i(data_mem_data_o_s),
	.data_mem_ready_o(data_mem_ready_s),
	.data_mem_data_o(data_mem_data_i_s),

	// Common memory IOs
	.merged_mem_ready_i(bus_ready_s),
	.merged_mem_data_i(bus_data_s),
	.merged_mem_rd_o(merged_mem_rd_s),
	.merged_mem_wr_o(merged_mem_wr_s),
	.merged_mem_addr_o(merged_mem_addr_s),
	.merged_mem_data_o(merged_mem_data_o_s)
);


// Handling of bus requests
assign bus_ready_s = merged_mem_ready_s && axi_ready_s;
always @(*) begin
	// Default case, no operation
	ram_rd_en_s = 1'b0;
	ram_wr_en_s = 1'b0;
	axi_rd_en_s = 1'b0;
	axi_wr_en_s = 1'b0;
	bus_data_s = 32'd0;

  	if (merged_mem_addr_s[31:17] == 15'd0) begin
		// Ram operation
		ram_rd_en_s = merged_mem_rd_s;
		ram_wr_en_s = merged_mem_wr_s;
		bus_data_s = merged_mem_data_i_s;
	end else if (merged_mem_addr_s[31:17] == 15'd2) begin
		// AXI operation
		axi_rd_en_s = merged_mem_rd_s;
		axi_wr_en_s = merged_mem_wr_s;
		bus_data_s = axi_data_s;
	end
end


// Integrated ram
ram_wrapper inst_ram_wrapper(	
	.clk_i(clk_i),
	.rst_i(rst_i),
	.read_i(ram_rd_en_s),
	.write_i(ram_wr_en_s),
	.addr_i(merged_mem_addr_s[16:2]),
	.data_i(merged_mem_data_o_s),
	
	.mem_ready_o(merged_mem_ready_s),
	.data_o(merged_mem_data_i_s),
	.byte_select_i(byte_select_s)
);


// AXI master interface
axi_master inst_axi_master(	
		.clk_i(clk_i),
		.rst_i(rst_i),

		// Handshake interface
		.hs_read_i(axi_rd_en_s),
		.hs_write_i(axi_wr_en_s),
		.hs_addr_i(merged_mem_addr_s),
		.hs_data_i(merged_mem_data_o_s),
		.hs_ready_o(axi_ready_s),
		.hs_data_o(axi_data_s),
		
		//// AXI interface
		// Read Address (AR) channel
		.arvalid_o(arvalid_s),
		.aready_i(1'b1),
		.araddr_o(araddr_s),

		// Read Data (R) channel
		.rvalid_i(1'b1),
		.rready_o(rready_s),
		.rlast_i(rlast_s),
		.rdata_i(32'd0),
		.rresp_i(rresp_s),

		// Write Address (AW) channel
		.awvalid_o(awvalid_s),
		.awready_i(1'b1),
		.awaddr_o(awaddr_s),

		// Write Data (W) channel
		.wvalid_o(wvalid_s),
		.wready_i(1'b1),
		.wlast_o(wlast_s),
		.wdata_o(wdata_s),

		// Write Response (B) channel
		.bvalid_i(1'b1),
		.bready_o(bready_s),
		.bresp_i(bresp_s)
);

endmodule