module axi_ram_wrapper(	
	input clk_i,
	input rst_i,

	//// AXI interface
	// Read Address (AR) channel
	input  arvalid_i,
	output aready_o,
	input  [31:0] araddr_i,

	// Read Data (R) channel
	output rvalid_o,
	input  rready_i,
	output [31:0] rdata_o,
	output [1:0] rresp_o,

	// Write Address (AW) channel
	input  awvalid_i,
	output awready_o,
	input  [31:0] awaddr_i,

	// Write Data (W) channel
	input  wvalid_i,
	output wready_o,
	input  [31:0] wdata_i,
	input  [3:0] wstrb_i,

	// Write Response (B) channel
	output bvalid_o,
	input  bready_i,
	output [1:0] bresp_o
);

reg  ram_ready_s;
wire ram_rd_en_s, ram_wr_en_s;
wire [31:0] ram_addr_s, ram_data_o_s, ram_data_i_s;
wire [3:0] ram_byte_select_s;

axi_slave inst_axi_slave (
	.clk_i(clk_i),
	.rst_i(rst_i),
	//// AXI interface
	// Read Address (AR) channel
	.arvalid_i(arvalid_i),
	.aready_o(aready_o),
	.araddr_i(araddr_i),
	// Read Data (R) channel
	.rvalid_o(rvalid_o),
	.rready_i(rready_i),
	.rdata_o(rdata_o),
	.rresp_o(rresp_o),
	// Write Address (AW) channel
	.awvalid_i(awvalid_i),
	.awready_o(awready_o),
	.awaddr_i(awaddr_i),
	// Write Data (W) channel
	.wvalid_i(wvalid_i),
	.wready_o(wready_o),
	.wdata_i(wdata_i),
	.wstrb_i(wstrb_i),
	// Write Response (B) channel
	.bvalid_o(bvalid_o),
	.bready_i(bready_i),
	.bresp_o(bresp_o),
	// Handshake interface
	.hs_read_o(ram_rd_en_s),
	.hs_write_o(ram_wr_en_s),
	.hs_addr_o(ram_addr_s),
	.hs_data_o(ram_data_i_s),
	.hs_ready_i(ram_ready_s),
	.hs_data_i(ram_data_o_s),
	.byte_select_o(ram_byte_select_s)
);


reg mem_ready_r;
always @(posedge clk_i) begin
	if(rst_i == 1'd0) begin
		mem_ready_r <= 1'd0;
		ram_ready_s <= 1'd0;
	end else begin
		mem_ready_r <= (ram_rd_en_s || ram_wr_en_s);
		ram_ready_s <= mem_ready_r;
	end
end

// SRAM Macro
ram inst_ram (
	.clk0(clk_i), 
	.csb0(~(ram_rd_en_s | ram_wr_en_s)), 
	.web0(~ram_wr_en_s), 
	.addr0(ram_addr_s[16:2]), 
	.din0(ram_data_i_s), 
	.dout0(ram_data_o_s),
	.wmask0(ram_byte_select_s)
);
			
endmodule


