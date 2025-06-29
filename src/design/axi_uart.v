module axi_uart(	
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

	//// UART interface
	input  rx_i,
	output tx_o
);

wire uart_rd_en_s, uart_wr_en_s, uart_ready_s;
wire [31:0] uart_addr_s, uart_data_i_s;
wire [7:0] uart_data_o_s;

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
	.hs_read_o(uart_rd_en_s),
	.hs_write_o(uart_wr_en_s),
	.hs_addr_o(uart_addr_s),
	.hs_data_o(uart_data_i_s),
	.hs_ready_i(uart_ready_s),
	.hs_data_i({24'd0, uart_data_o_s}),
	.byte_select_o()
);

uart inst_uart(	
	.clk_i(clk_i),
	.rst_i(rst_i),
	// Handshake interface
	.hs_read_i(uart_rd_en_s),
	.hs_write_i(uart_wr_en_s),
	.hs_addr_i(uart_addr_s[4:0]),
	.hs_data_i(uart_data_i_s[7:0]),
	.hs_ready_o(uart_ready_s),
	.hs_data_o(uart_data_o_s),
	//// UART interface
	.rx_i(rx_i),
	.tx_o(tx_o)
);

endmodule
