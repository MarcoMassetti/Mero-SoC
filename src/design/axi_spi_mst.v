module axi_spi_mst(	
	input  clk_i,
	input  rst_i,

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
	output [1:0] bresp_o,

	// SPI interface
	output sck_o,
	output cs_no,
	output mosi_o,
	input  miso_i 
);

wire spi_rd_en_s, spi_wr_en_s, spi_ready_s;
wire [31:0] spi_addr_s, spi_data_i_s;
wire [7:0] spi_data_o_s;

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
	.hs_read_o(spi_rd_en_s),
	.hs_write_o(spi_wr_en_s),
	.hs_addr_o(spi_addr_s),
	.hs_data_o(spi_data_i_s),
	.hs_ready_i(spi_ready_s),
	.hs_data_i({24'd0, spi_data_o_s}),
	.byte_select_o()
);

spi_mst inst_spi_mst(	
	.clk_i(clk_i),
	.rst_i(rst_i),
	// Handshake interface
	.hs_read_i(spi_rd_en_s),
	.hs_write_i(spi_wr_en_s),
	.hs_addr_i(spi_addr_s[4:0]),
	.hs_data_i(spi_data_i_s[7:0]),
	.hs_ready_o(spi_ready_s),
	.hs_data_o(spi_data_o_s),
	// SPI interface
	.sck_o(sck_o),
	.cs_no(cs_no),
	.mosi_o(mosi_o),
	.miso_i(miso_i) 
);

endmodule
