module axi_cpu_interface_ctrl(	
	input  clk_i,
	input  rst_ni,

	// Boot source strapping pins
	// 0:SPI, 1:SRAM, 2:DDR
	input [1:0] boot_source_i,

	//// Boot controller AXI interface
	// Read Address (AR) channel
	input  boot_ctrl_arvalid_i,
	output boot_ctrl_aready_o,
	input  [31:0] boot_ctrl_araddr_i,
	// Read Data (R) channel
	output boot_ctrl_rvalid_o,
	input  boot_ctrl_rready_i,
	output [31:0] boot_ctrl_rdata_o,
	output [1:0] boot_ctrl_rresp_o,
	// Write Address (AW) channel
	input  boot_ctrl_awvalid_i,
	output boot_ctrl_awready_o,
	input  [31:0] boot_ctrl_awaddr_i,
	// Write Data (W) channel
	input  boot_ctrl_wvalid_i,
	output boot_ctrl_wready_o,
	input  [31:0] boot_ctrl_wdata_i,
	input  [3:0] boot_ctrl_wstrb_i,
	// Write Response (B) channel
	output boot_ctrl_bvalid_o,
	input  boot_ctrl_bready_i,
	output [1:0] boot_ctrl_bresp_o,

	// CPU stall signal
	output mem_ready_o,

	// Instruction memory IOs towards CPU
	input  cpu_instr_mem_rd_i,
	input  [31:0] cpu_instr_mem_addr_i,
	output [31:0] cpu_instr_mem_data_o,

	// Data memory IOs towards CPU
	input  cpu_data_mem_rd_i,
	input  cpu_data_mem_wr_i,
	input  [31:0] cpu_data_mem_addr_i,
	input  [31:0] cpu_data_mem_data_i,
	output [31:0] cpu_data_mem_data_o,
	input  [3:0] cpu_byte_select_i,

	//// Instruction memory AXI interface
	// Read Address (AR) channel
	output instr_arvalid_o,
	input  instr_aready_i,
	output [31:0] instr_araddr_o,
	// Read Data (R) channel
	input  instr_rvalid_i,
	output instr_rready_o,
	input [31:0] instr_rdata_i,
	input [1:0] instr_rresp_i,
	// Write Address (AW) channel
	output instr_awvalid_o,
	input instr_awready_i,
	output [31:0] instr_awaddr_o,
	// Write Data (W) channel
	output instr_wvalid_o,
	input instr_wready_i,
	output [31:0] instr_wdata_o,
	output [3:0] instr_wstrb_o,
	// Write Response (B) channel
	input instr_bvalid_i,
	output instr_bready_o,
	input [1:0] instr_bresp_i,

	//// Data memory AXI interface
	// Read Address (AR) channel
	output data_arvalid_o,
	input  data_aready_i,
	output [31:0] data_araddr_o,
	// Read Data (R) channel
	input  data_rvalid_i,
	output data_rready_o,
	input [31:0] data_rdata_i,
	input [1:0] data_rresp_i,
	// Write Address (AW) channel
	output data_awvalid_o,
	input data_awready_i,
	output [31:0] data_awaddr_o,
	// Write Data (W) channel
	output data_wvalid_o,
	input data_wready_i,
	output [31:0] data_wdata_o,
	output [3:0] data_wstrb_o,
	// Write Response (B) channel
	input data_bvalid_i,
	output data_bready_o,
	input [1:0] data_bresp_i
);

//// Hand-shake to AXI conversion signals
// Intruction memory interface
wire instr_mem_ready_s, instr_mem_rd_s, instr_mem_wr_s;
wire [31:0] instr_mem_data_i_s, instr_mem_data_o_s, instr_mem_addr_s;
// Data memory interface
wire data_mem_ready_s, data_mem_rd_s, data_mem_wr_s;
wire [31:0] data_mem_data_i_s, data_mem_addr_s, data_mem_data_o_s;
wire [3:0] data_mem_byte_select_s;

cpu_interface_ctrl inst_cpu_interface_ctrl(	
	.clk_i(clk_i),
	.rst_ni(rst_ni),
	// Boot source strapping pins
	// 0:SPI, 1:SRAM, 2:DDR
	.boot_source_i(boot_source_i),
	//// AXI interface
	// Read Address (AR) channel
	.arvalid_i(boot_ctrl_arvalid_i),
	.aready_o(boot_ctrl_aready_o),
	.araddr_i(boot_ctrl_araddr_i),
	// Read Data (R) channel
	.rvalid_o(boot_ctrl_rvalid_o),
	.rready_i(boot_ctrl_rready_i),
	.rdata_o(boot_ctrl_rdata_o),
	.rresp_o(boot_ctrl_rresp_o),
	// Write Address (AW) channel
	.awvalid_i(boot_ctrl_awvalid_i),
	.awready_o(boot_ctrl_awready_o),
	.awaddr_i(boot_ctrl_awaddr_i),
	// Write Data (W) channel
	.wvalid_i(boot_ctrl_wvalid_i),
	.wready_o(boot_ctrl_wready_o),
	.wdata_i(boot_ctrl_wdata_i),
	.wstrb_i(boot_ctrl_wstrb_i),
	// Write Response (B) channel
	.bvalid_o(boot_ctrl_bvalid_o),
	.bready_i(boot_ctrl_bready_i),
	.bresp_o(boot_ctrl_bresp_o),
	// CPU stall signal
	.mem_ready_o(mem_ready_o),
	//// Instruction memory IOs
	// Towards CPU
	.cpu_instr_mem_rd_i(cpu_instr_mem_rd_i),
	.cpu_instr_mem_addr_i(cpu_instr_mem_addr_i),
	.cpu_instr_mem_data_o(cpu_instr_mem_data_o),
	// Towards BUS
	.bus_instr_mem_ready_i(instr_mem_ready_s),
	.bus_instr_mem_rd_o(instr_mem_rd_s),
	.bus_instr_mem_wr_o(instr_mem_wr_s),
	.bus_instr_mem_addr_o(instr_mem_addr_s),
	.bus_instr_mem_data_i(instr_mem_data_i_s),
	.bus_instr_mem_data_o(instr_mem_data_o_s),
	// Data memory IOs
	// Towards CPU
	.cpu_data_mem_rd_i(cpu_data_mem_rd_i),
	.cpu_data_mem_wr_i(cpu_data_mem_wr_i),
	.cpu_data_mem_addr_i(cpu_data_mem_addr_i),
	.cpu_data_mem_data_i(cpu_data_mem_data_i),
	.cpu_data_mem_data_o(cpu_data_mem_data_o),
	.cpu_byte_select_i(cpu_byte_select_i),
	// Towards BUS
	.bus_data_mem_ready_i(data_mem_ready_s),
	.bus_data_mem_rd_o(data_mem_rd_s),
	.bus_data_mem_wr_o(data_mem_wr_s),
	.bus_data_mem_addr_o(data_mem_addr_s),
	.bus_data_mem_data_i(data_mem_data_i_s),
	.bus_data_mem_data_o(data_mem_data_o_s),
	.bus_byte_select_o(data_mem_byte_select_s)
);

hs_2_axi inst_instr_mem_axi_master(	
	.clk_i(clk_i),
	.rst_ni(rst_ni),
	// Handshake interface
	.hs_read_i(instr_mem_rd_s),
	.hs_write_i(instr_mem_wr_s),
	.hs_addr_i(instr_mem_addr_s),
	.hs_data_i(instr_mem_data_o_s),
	.hs_ready_o(instr_mem_ready_s),
	.hs_data_o(instr_mem_data_i_s),
	.byte_select_i(4'd1),
	//// AXI interface
	// Read Address (AR) channel
	.arvalid_o(instr_arvalid_o),
	.aready_i(instr_aready_i),
	.araddr_o(instr_araddr_o),
	// Read Data (R) channel
	.rvalid_i(instr_rvalid_i),
	.rready_o(instr_rready_o),
	.rdata_i(instr_rdata_i),
	.rresp_i(instr_rresp_i),
	// Write Address (AW) channel
	.awvalid_o(instr_awvalid_o),
	.awready_i(instr_awready_i),
	.awaddr_o(instr_awaddr_o),
	// Write Data (W) channel
	.wvalid_o(instr_wvalid_o),
	.wready_i(instr_wready_i),
	.wdata_o(instr_wdata_o),
	.wstrb_o(instr_wstrb_o),
	// Write Response (B) czannel
	.bvalid_i(instr_bvalid_i),
	.bready_o(instr_bready_o),
	.bresp_i(instr_bresp_i)
);

hs_2_axi inst_data_mem_axi_master(	
	.clk_i(clk_i),
	.rst_ni(rst_ni),
	// Handshake interface
	.hs_read_i(data_mem_rd_s),
	.hs_write_i(data_mem_wr_s),
	.hs_addr_i(data_mem_addr_s),
	.hs_data_i(data_mem_data_o_s),
	.hs_ready_o(data_mem_ready_s),
	.hs_data_o(data_mem_data_i_s),
	.byte_select_i(data_mem_byte_select_s),
	//// AXI interface
	// Read Address (AR) channel
	.arvalid_o(data_arvalid_o),
	.aready_i(data_aready_i),
	.araddr_o(data_araddr_o),
	// Read Data (R) channel
	.rvalid_i(data_rvalid_i),
	.rready_o(data_rready_o),
	.rdata_i(data_rdata_i),
	.rresp_i(data_rresp_i),
	// Write Address (AW) channel
	.awvalid_o(data_awvalid_o),
	.awready_i(data_awready_i),
	.awaddr_o(data_awaddr_o),
	// Write Data (W) channel
	.wvalid_o(data_wvalid_o),
	.wready_i(data_wready_i),
	.wdata_o(data_wdata_o),
	.wstrb_o(data_wstrb_o),
	// Write Response (B) channel
	.bvalid_i(data_bvalid_i),
	.bready_o(data_bready_o),
	.bresp_i(data_bresp_i)
);


endmodule
