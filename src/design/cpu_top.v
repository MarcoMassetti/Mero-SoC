module cpu_top (
	input  clk_i,
	input  rst_i,
	output reg [3:0] led_o,
	output tx_o,
	input  rx_i
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

wire axi_ready_s;
wire [31:0] axi_data_s;
wire bus_ready_s;
reg [31:0] bus_data_s;

assign bus_ready_s = merged_mem_ready_s && axi_ready_s;

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

reg ram_rd_en_s, ram_wr_en_s;
reg led_wr_en_s;

reg axi_rd_en_s, axi_wr_en_s;

always @(*) begin
	// Default case, no operation
	ram_rd_en_s = 1'b0;
	ram_wr_en_s = 1'b0;
	led_wr_en_s = 1'b0;
	axi_rd_en_s = 1'b0;
	axi_wr_en_s = 1'b0;
	bus_data_s = 32'd0;

  	if (merged_mem_addr_s[31:17] == 15'd0) begin
		// Ram operation
		ram_rd_en_s = merged_mem_rd_s;
		ram_wr_en_s = merged_mem_wr_s;
		bus_data_s = merged_mem_data_i_s;
	end else if (merged_mem_addr_s[31:17] == 15'd1) begin
		// Led operation
		led_wr_en_s = merged_mem_wr_s;
		bus_data_s = merged_mem_data_i_s;
	end else if (merged_mem_addr_s[31:17] == 15'd2) begin
		// AXI operation
		axi_rd_en_s = merged_mem_rd_s;
		axi_wr_en_s = merged_mem_wr_s;
		bus_data_s = axi_data_s;
	end
end

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

always @(posedge clk_i) begin
	if (rst_i == 1'd0) begin
    	led_o <= 4'd0;
	end else if (led_wr_en_s) begin
		led_o <= merged_mem_data_o_s[3:0];
	end
end

// Read Address (AR) channel
wire uart_arvalid_s, uart_aready_s;
wire [31:0] uart_araddr_s;

// Read Data (R) channel
wire uart_rvalid_s, uart_rready_s, uart_rlast_s;
wire [31:0] uart_rdata_s;
wire [1:0] uart_rresp_s;

// Write Address (AW) channel
wire uart_awvalid_s, uart_awready_s;
wire [31:0] uart_awaddr_s;

// Write Data (W) channel
wire uart_wvalid_s, uart_wready_s, uart_wlast_s;
wire [31:0] uart_wdata_s;

// Write Response (B) channel
wire uart_bvalid_s, uart_bready_s;
wire [1:0] uart_bresp_s;

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
		.arvalid_o(uart_arvalid_s),
		.aready_i(uart_aready_s),
		.araddr_o(uart_araddr_s),

		// Read Data (R) channel
		.rvalid_i(uart_rvalid_s),
		.rready_o(uart_rready_s),
		.rlast_i(uart_rlast_s),
		.rdata_i(uart_rdata_s),
		.rresp_i(uart_rresp_s),

		// Write Address (AW) channel
		.awvalid_o(uart_awvalid_s),
		.awready_i(uart_awready_s),
		.awaddr_o(uart_awaddr_s),

		// Write Data (W) channel
		.wvalid_o(uart_wvalid_s),
		.wready_i(uart_wready_s),
		.wlast_o(uart_wlast_s),
		.wdata_o(uart_wdata_s),

		// Write Response (B) channel
		.bvalid_i(uart_bvalid_s),
		.bready_o(uart_bready_s),
		.bresp_i(uart_bresp_s)
);

axi_uartlite_0 inst_uart (
  .s_axi_aclk(clk_i),        // input wire s_axi_aclk
  .s_axi_aresetn(rst_i),  // input wire s_axi_aresetn
  .interrupt(),          // output wire interrupt
  .s_axi_awaddr(uart_awaddr_s[3:0]),    // input wire [3 : 0] s_axi_awaddr
  .s_axi_awvalid(uart_awvalid_s),  // input wire s_axi_awvalid
  .s_axi_awready(uart_awready_s),  // output wire s_axi_awready
  .s_axi_wdata(uart_wdata_s),      // input wire [31 : 0] s_axi_wdata
  .s_axi_wstrb({4{uart_wvalid_s}}),      // input wire [3 : 0] s_axi_wstrb
  .s_axi_wvalid(uart_wvalid_s),    // input wire s_axi_wvalid
  .s_axi_wready(uart_wready_s),    // output wire s_axi_wready
  .s_axi_bresp(uart_bresp_s),      // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid(uart_bvalid_s),    // output wire s_axi_bvalid
  .s_axi_bready(uart_bready_s),    // input wire s_axi_bready
  .s_axi_araddr(uart_araddr_s[3:0]),    // input wire [3 : 0] s_axi_araddr
  .s_axi_arvalid(uart_arvalid_s),  // input wire s_axi_arvalid
  .s_axi_arready(uart_aready_s),  // output wire s_axi_arready
  .s_axi_rdata(uart_rdata_s),      // output wire [31 : 0] s_axi_rdata
  .s_axi_rresp(uart_rresp_s),      // output wire [1 : 0] s_axi_rresp
  .s_axi_rvalid(uart_rvalid_s),    // output wire s_axi_rvalid
  .s_axi_rready(uart_rready_s),    // input wire s_axi_rready
  .rx(rx_i),                        // input wire rx
  .tx(tx_o)                        // output wire tx
);

assign uart_rlast_s = 1'b1; 

endmodule