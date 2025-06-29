module cpu_top (
	input  clk_i,
	input  rst_i,
	// UART
	output tx_o,
	input  rx_i,
	// SPI
	//output spi_sck_o,
	output spi_cs_no,
	output spi_mosi_o,
	input  spi_miso_i,
	output wp_no,
	output hold_no,
	// PLL
	output locked_o
	/*,
	// DDR
	output [13:0] ddr3_addr,
    output [2:0] ddr3_ba,
    output ddr3_cas_n,
    output ddr3_ck_n,
    output ddr3_ck_p,
    output ddr3_cke,
    output ddr3_ras_n,
    output ddr3_reset_n,
    output ddr3_we_n,
    inout  [15:0] ddr3_dq,
    inout  [1:0] ddr3_dqs_n,
    inout  [1:0] ddr3_dqs_p,
	output ddr3_cs_n,
    output [1:0] ddr3_dm,
    output ddr3_odt,
	output init_calib_complete_o
	*/
);
wire spi_sck_o;
// Signals between cpu and memory arbitrer
// Intruction memory interface
wire instr_mem_ready_s, instr_mem_rd_s, instr_mem_wr_s;
wire [31:0] instr_mem_data_i_s, instr_mem_data_o_s, instr_mem_addr_s;
// Data memory interface
wire data_mem_ready_s, data_mem_rd_s, data_mem_wr_s;
wire [31:0] data_mem_data_i_s, data_mem_addr_s, data_mem_data_o_s;
wire [3:0]  data_mem_byte_select_s;

wire mem_ready_s, cpu_instr_mem_rd_s, cpu_data_mem_rd_s, cpu_data_mem_wr_s;
wire [31:0] cpu_instr_mem_data_s, cpu_instr_mem_addr_s;

cpu inst_cpu(
	.clk_i(clk_i),
    .rst_i(rst_i),
	.mem_ready_i(mem_ready_s),
	.trap_o(),
	// Instruction memory IOs
	.instr_mem_data_i(cpu_instr_mem_data_s),
	.instr_mem_addr_o(cpu_instr_mem_addr_s),
	.instr_mem_rd_o(cpu_instr_mem_rd_s),
	// Data memory IOs
	.data_mem_data_i(data_mem_data_i_s),
	.data_mem_addr_o(data_mem_addr_s),
	.data_mem_data_o(data_mem_data_o_s),
	.data_mem_rd_o(cpu_data_mem_rd_s),
	.data_mem_wr_o(cpu_data_mem_wr_s),
	.byte_select_o(data_mem_byte_select_s)
);

mmu inst_mmu(	
	.clk_i(clk_i),
	.rst_i(rst_i),
	// CPU stall signal
	.mem_ready_o(mem_ready_s),
	//// Instruction memory IOs
	// Towards CPU
	.cpu_instr_mem_rd_i(cpu_instr_mem_rd_s),
	.cpu_instr_mem_addr_i(cpu_instr_mem_addr_s),
	.cpu_instr_mem_data_o(cpu_instr_mem_data_s),
	// Towards BUS
	.bus_instr_mem_ready_i(instr_mem_ready_s),
	.bus_instr_mem_rd_o(instr_mem_rd_s),
	.bus_instr_mem_wr_o(instr_mem_wr_s),
	.bus_instr_mem_addr_o(instr_mem_addr_s),
	.bus_instr_mem_data_i(instr_mem_data_i_s),
	.bus_instr_mem_data_o(instr_mem_data_o_s),
	// Data memory IOs
	.cpu_data_mem_rd_i(cpu_data_mem_rd_s),
	.cpu_data_mem_wr_i(cpu_data_mem_wr_s),
	.bus_data_mem_rd_o(data_mem_rd_s),
	.bus_data_mem_wr_o(data_mem_wr_s),
	.bus_data_mem_ready_i(data_mem_ready_s)
);

wire ram_rd_en_s, ram_wr_en_s, ram_ready_s;
wire [31:0] ram_addr_s, ram_data_o_s, ram_data_i_s;
wire [3:0] ram_byte_select_s;

//// INSTRUCTION MEMORY AXI SIGNALS
// Read Address (AR) channel
wire instr_arvalid_s, instr_aready_s;
wire [31:0] instr_araddr_s;
// Read Data (R) channel
wire instr_rvalid_s, instr_rready_s;
wire [31:0] instr_rdata_s;
wire [1:0] instr_rresp_s;
// Write Address (AW) channel
wire instr_awvalid_s, instr_awready_s;
wire [31:0] instr_awaddr_s;
// Write Data (W) channel
wire instr_wvalid_s, instr_wready_s;
wire [31:0] instr_wdata_s;
wire [3:0] instr_wstrb_s;
// Write Response (B) channel
wire instr_bvalid_s, instr_bready_s;
wire [1:0] instr_bresp_s;

//// DATA MEMORY AXI SIGNALS
// Read Address (AR) channel
wire data_arvalid_s, data_aready_s;
wire [31:0] data_araddr_s;
// Read Data (R) channel
wire data_rvalid_s, data_rready_s;
wire [31:0] data_rdata_s;
wire [1:0] data_rresp_s;
// Write Address (AW) channel
wire data_awvalid_s, data_awready_s;
wire [31:0] data_awaddr_s;
// Write Data (W) channel
wire data_wvalid_s, data_wready_s;
wire [31:0] data_wdata_s;
wire [3:0] data_wstrb_s;
// Write Response (B) channel
wire data_bvalid_s, data_bready_s;
wire [1:0] data_bresp_s;

//// UART AXI SIGNALS
// Read Address (AR) channel
wire uart_arvalid_s, uart_aready_s;
wire [31:0] uart_araddr_s;
// Read Data (R) channel
wire uart_rvalid_s, uart_rready_s;
wire [31:0] uart_rdata_s;
wire [1:0] uart_rresp_s;
// Write Address (AW) channel
wire uart_awvalid_s, uart_awready_s;
wire [31:0] uart_awaddr_s;
// Write Data (W) channel
wire uart_wvalid_s, uart_wready_s;
wire [31:0] uart_wdata_s;
wire [3:0] uart_wstrb_s;
// Write Response (B) channel
wire uart_bvalid_s, uart_bready_s;
wire [1:0] uart_bresp_s;

//// DDR AXI SIGNALS (system clock domain)
// Read Address (AR) channel
wire ddr_arvalid_s, ddr_aready_s;
wire [31:0] ddr_araddr_s;
// Read Data (R) channel
wire ddr_rvalid_s, ddr_rready_s;
wire [31:0] ddr_rdata_s;
wire [1:0] ddr_rresp_s;
// Write Address (AW) channel
wire ddr_awvalid_s, ddr_awready_s;
wire [31:0] ddr_awaddr_s;
// Write Data (W) channel
wire ddr_wvalid_s, ddr_wready_s;
wire [31:0] ddr_wdata_s;
wire [3:0] ddr_wstrb_s;
// Write Response (B) channel
wire ddr_bvalid_s, ddr_bready_s;
wire [1:0] ddr_bresp_s;

//// DDR AXI SIGNALS (ref clock domain)
// Read Address (AR) channel
wire ddr_ref_arvalid_s, ddr_ref_aready_s;
wire [31:0] ddr_ref_araddr_s;
// Read Data (R) channel
wire ddr_ref_rvalid_s, ddr_ref_rready_s;
wire [31:0] ddr_ref_rdata_s;
wire [1:0] ddr_ref_rresp_s;
// Write Address (AW) channel
wire ddr_ref_awvalid_s, ddr_ref_awready_s;
wire [31:0] ddr_ref_awaddr_s;
// Write Data (W) channel
wire ddr_ref_wvalid_s, ddr_ref_wready_s;
wire [31:0] ddr_ref_wdata_s;
// Write Response (B) channel
wire ddr_ref_bvalid_s, ddr_ref_bready_s;
wire [1:0] ddr_ref_bresp_s;

//// QSPI AXI SIGNALS
// Read Address (AR) channel
wire qspi_arvalid_s, qspi_aready_s;
wire [31:0] qspi_araddr_s;
// Read Data (R) channel
wire qspi_rvalid_s, qspi_rready_s;
wire [31:0] qspi_rdata_s;
wire [1:0] qspi_rresp_s;
// Write Address (AW) channel
wire qspi_awvalid_s, qspi_awready_s;
wire [31:0] qspi_awaddr_s;
// Write Data (W) channel
wire qspi_wvalid_s, qspi_wready_s;
wire [31:0] qspi_wdata_s;
wire [3:0] qspi_wstrb_s;
// Write Response (B) channel
wire qspi_bvalid_s, qspi_bready_s;
wire [1:0] qspi_bresp_s;

//// RAM AXI SIGNALS
// Read Address (AR) channel
wire ram_arvalid_s, ram_aready_s;
wire [31:0] ram_araddr_s;
// Read Data (R) channel
wire ram_rvalid_s, ram_rready_s;
wire [31:0] ram_rdata_s;
wire [1:0] ram_rresp_s;
// Write Address (AW) channel
wire ram_awvalid_s, ram_awready_s;
wire [31:0] ram_awaddr_s;
// Write Data (W) channel
wire ram_wvalid_s, ram_wready_s;
wire [31:0] ram_wdata_s;
wire [3:0] ram_wstrb_s;
// Write Response (B) channel
wire ram_bvalid_s, ram_bready_s;
wire [1:0] ram_bresp_s;

axi_master inst_instr_mem_axi_master(	
	.clk_i(clk_i),
	.rst_i(rst_i),
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
	.arvalid_o(instr_arvalid_s),
	.aready_i(instr_aready_s),
	.araddr_o(instr_araddr_s),
	// Read Data (R) channel
	.rvalid_i(instr_rvalid_s),
	.rready_o(instr_rready_s),
	.rdata_i(instr_rdata_s),
	.rresp_i(instr_rresp_s),
	// Write Address (AW) channel
	.awvalid_o(instr_awvalid_s),
	.awready_i(instr_awready_s),
	.awaddr_o(instr_awaddr_s),
	// Write Data (W) channel
	.wvalid_o(instr_wvalid_s),
	.wready_i(instr_wready_s),
	.wdata_o(instr_wdata_s),
	.wstrb_o(instr_wstrb_s),
	// Write Response (B) channel
	.bvalid_i(instr_bvalid_s),
	.bready_o(instr_bready_s),
	.bresp_i(instr_bresp_s)
);

axi_master inst_data_mem_axi_master(	
	.clk_i(clk_i),
	.rst_i(rst_i),
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
	.arvalid_o(data_arvalid_s),
	.aready_i(data_aready_s),
	.araddr_o(data_araddr_s),
	// Read Data (R) channel
	.rvalid_i(data_rvalid_s),
	.rready_o(data_rready_s),
	.rdata_i(data_rdata_s),
	.rresp_i(data_rresp_s),
	// Write Address (AW) channel
	.awvalid_o(data_awvalid_s),
	.awready_i(data_awready_s),
	.awaddr_o(data_awaddr_s),
	// Write Data (W) channel
	.wvalid_o(data_wvalid_s),
	.wready_i(data_wready_s),
	.wdata_o(data_wdata_s),
	.wstrb_o(data_wstrb_s),
	// Write Response (B) channel
	.bvalid_i(data_bvalid_s),
	.bready_o(data_bready_s),
	.bresp_i(data_bresp_s)
);

//// Packed AXI master interfaces
localparam N_MST = 2;
// Read Address (AR) channel
wire [N_MST-1:0] mst_arvalid_s, mst_aready_s;
wire [(32*N_MST)-1:0] mst_araddr_s;
// Read Data (R) channel
wire [N_MST-1:0] mst_rvalid_s, mst_rready_s;
wire [(32*N_MST)-1:0] mst_rdata_s;
wire [(2*N_MST)-1:0] mst_rresp_s;
// Write Address (AW) channel
wire [N_MST-1:0] mst_awvalid_s, mst_awready_s;
wire [(32*N_MST)-1:0] mst_awaddr_s;
// Write Data (W) channel
wire [N_MST-1:0] mst_wvalid_s, mst_wready_s;
wire [(32*N_MST)-1:0] mst_wdata_s;
wire [(4*N_MST)-1:0] mst_wstrb_s;
// Write Response (B) channel
wire [N_MST-1:0] mst_bvalid_s, mst_bready_s;
wire [(2*N_MST)-1:0] mst_bresp_s;

//// Packing/Unpacking of master interfaces
// Read Address (AR) channel
assign mst_arvalid_s = {data_arvalid_s, instr_arvalid_s};
assign instr_aready_s = mst_aready_s[0];
assign data_aready_s = mst_aready_s[1];
assign mst_araddr_s = {data_araddr_s, instr_araddr_s};
// Read Data (R) channel
assign instr_rvalid_s = mst_rvalid_s[0];
assign data_rvalid_s = mst_rvalid_s[1];
assign mst_rready_s = {data_rready_s ,instr_rready_s};
assign instr_rdata_s = mst_rdata_s[(0*32)+31:0*32];
assign data_rdata_s = mst_rdata_s[(1*32)+31:1*32];
assign instr_rresp_s = mst_rresp_s[(0*2)+1:0*2];
assign data_rresp_s = mst_rresp_s[(1*2)+1:1*2];
// Write Address (AW) channel
assign mst_awvalid_s = {data_awvalid_s, instr_awvalid_s};
assign instr_awready_s = mst_awready_s[0];
assign data_awready_s = mst_awready_s[1];
assign mst_awaddr_s = {data_awaddr_s, instr_awaddr_s};
// Write Data (W) channel
assign mst_wvalid_s = {data_wvalid_s, instr_wvalid_s};
assign instr_wready_s = mst_wready_s[0];
assign data_wready_s = mst_wready_s[1];
assign mst_wdata_s = {data_wdata_s, instr_wdata_s};
assign mst_wstrb_s = {data_wstrb_s, instr_wstrb_s};
// Write Response (B) channel
assign instr_bvalid_s = mst_bvalid_s[0];
assign data_bvalid_s = mst_bvalid_s[1];
assign mst_bready_s = {data_bready_s, instr_bready_s};
assign instr_bresp_s = mst_bresp_s[(0*2)+1:0*2];
assign instr_bresp_s = mst_bresp_s[(1*2)+1:1*2];

//// Packed AXI slave interfaces
localparam N_SLV = 4;
// Read Address (AR) channel
wire [N_SLV-1:0] slv_arvalid_s, slv_aready_s;
wire [(32*N_SLV)-1:0] slv_araddr_s;
// Read Data (R) channel
wire [N_SLV-1:0] slv_rvalid_s, slv_rready_s;
wire [(32*N_SLV)-1:0] slv_rdata_s;
wire [(2*N_SLV)-1:0] slv_rresp_s;
// Write Address (AW) channel
wire [N_SLV-1:0] slv_awvalid_s, slv_awready_s;
wire [(32*N_SLV)-1:0] slv_awaddr_s;
// Write Data (W) channel
wire [N_SLV-1:0] slv_wvalid_s, slv_wready_s;
wire [(32*N_SLV)-1:0] slv_wdata_s;
wire [(4*N_SLV)-1:0] slv_wstrb_s;
// Write Response (B) channel
wire [N_SLV-1:0] slv_bvalid_s, slv_bready_s;
wire [(2*N_SLV)-1:0] slv_bresp_s;

//// Packing/Unpacking of slave interfaces
// Read Address (AR) channel
assign uart_arvalid_s = slv_arvalid_s[0];
assign qspi_arvalid_s = slv_arvalid_s[1];
assign ddr_arvalid_s = slv_arvalid_s[2];
assign ram_arvalid_s = slv_arvalid_s[3];
assign slv_aready_s = {ram_aready_s, ddr_aready_s, qspi_aready_s, uart_aready_s};
assign uart_araddr_s = slv_araddr_s[(0*32)+31:0*32];
assign qspi_araddr_s = slv_araddr_s[(1*32)+31:1*32];
assign ddr_araddr_s = slv_araddr_s[(2*32)+31:2*32];
assign ram_araddr_s = slv_araddr_s[(3*32)+31:3*32];
// Read Data (R) channel
assign slv_rvalid_s = {ram_rvalid_s, ddr_rvalid_s, qspi_rvalid_s, uart_rvalid_s};
assign uart_rready_s = slv_rready_s[0];
assign qspi_rready_s = slv_rready_s[1];
assign ddr_rready_s = slv_rready_s[2];
assign ram_rready_s = slv_rready_s[3];
assign slv_rdata_s = {ram_rdata_s, ddr_rdata_s, qspi_rdata_s, uart_rdata_s};
assign slv_rresp_s = {ram_rresp_s, ddr_rresp_s, qspi_rresp_s, uart_rresp_s};
// Write Address (AW) channel
assign uart_awvalid_s = slv_awvalid_s[0];
assign qspi_awvalid_s = slv_awvalid_s[1];
assign ddr_awvalid_s = slv_awvalid_s[2];
assign ram_awvalid_s = slv_awvalid_s[3];
assign slv_awready_s = {ram_awready_s, ddr_awready_s, qspi_awready_s, uart_awready_s};
assign uart_awaddr_s = slv_awaddr_s[(0*32)+31:0*32];
assign qspi_awaddr_s = slv_awaddr_s[(1*32)+31:1*32];
assign ddr_awaddr_s = slv_awaddr_s[(2*32)+31:2*32];
assign ram_awaddr_s = slv_awaddr_s[(3*32)+31:3*32];
// Write Data (W) channel
assign uart_wvalid_s = slv_wvalid_s[0];
assign qspi_wvalid_s = slv_wvalid_s[1];
assign ddr_wvalid_s = slv_wvalid_s[2];
assign ram_wvalid_s = slv_wvalid_s[3];
assign slv_wready_s = {ram_wready_s, ddr_wready_s, qspi_wready_s, uart_wready_s};
assign uart_wdata_s = slv_wdata_s[(0*32)+31:0*32];
assign qspi_wdata_s = slv_wdata_s[(1*32)+31:1*32];
assign ddr_wdata_s = slv_wdata_s[(2*32)+31:2*32];
assign ram_wdata_s = slv_wdata_s[(3*32)+31:3*32];
assign uart_wstrb_s = slv_wstrb_s[(0*4)+3:0*4];
assign qspi_wstrb_s = slv_wstrb_s[(1*4)+3:1*4];
assign ddr_wstrb_s = slv_wstrb_s[(2*4)+3:2*4];
assign ram_wstrb_s = slv_wstrb_s[(3*4)+3:3*4];
// Write Response (B) channel
assign slv_bvalid_s = {ram_bvalid_s, ddr_bvalid_s, qspi_bvalid_s, uart_bvalid_s};
assign uart_bready_s = slv_bready_s[0];
assign qspi_bready_s = slv_bready_s[1];
assign ddr_bready_s = slv_bready_s[2];
assign ram_bready_s = slv_bready_s[3];
assign slv_bresp_s = {ram_bresp_s, ddr_bresp_s, qspi_bresp_s, uart_bresp_s};

axi_interconnect  #(
	.N_MST(N_MST),
	.N_SLV(N_SLV),
	.SLV_SEL_ADDR_BITS(15),
	.SLV_ADDRESSES({15'd0, 15'd4, 15'd3, 15'd2})
	)
	inst_axi_interconnect (	
	.clk_i(clk_i),
	.rst_i(rst_i),
	//// AXI master interface
	// Read Address (AR) channel
	.m_arvalid_i(mst_arvalid_s),
	.m_aready_o(mst_aready_s),
	.m_araddr_i(mst_araddr_s),
	// Read Data (R) channel
	.m_rvalid_o(mst_rvalid_s),
	.m_rready_i(mst_rready_s),
	.m_rdata_o(mst_rdata_s),
	.m_rresp_o(mst_rresp_s),
	// Write Address (AW) channel
	.m_awvalid_i(mst_awvalid_s),
	.m_awready_o(mst_awready_s),
	.m_awaddr_i(mst_awaddr_s),
	// Write Data (W) channel
	.m_wvalid_i(mst_wvalid_s),
	.m_wready_o(mst_wready_s),
	.m_wdata_i(mst_wdata_s),
	.m_wstrb_i(mst_wstrb_s),
	// Write Response (B) channel
	.m_bvalid_o(mst_bvalid_s),
	.m_bready_i(mst_bready_s),
	.m_bresp_o(mst_bresp_s),
	//// AXI slaves interfaces
	// Read Address (AR) channel
	.s_arvalid_o(slv_arvalid_s),
	.s_aready_i(slv_aready_s),
	.s_araddr_o(slv_araddr_s),
	// Read Data (R) channel
	.s_rvalid_i(slv_rvalid_s),
	.s_rready_o(slv_rready_s),
	.s_rdata_i(slv_rdata_s),
	.s_rresp_i(slv_rresp_s),
	// Write Address (AW) channel
	.s_awvalid_o(slv_awvalid_s),
	.s_awready_i(slv_awready_s),
	.s_awaddr_o(slv_awaddr_s),
	// Write Data (W) channel
	.s_wvalid_o(slv_wvalid_s),
	.s_wready_i(slv_wready_s),
	.s_wdata_o(slv_wdata_s),
	.s_wstrb_o(slv_wstrb_s),
	// Write Response (B) channel
	.s_bvalid_i(slv_bvalid_s),
	.s_bready_o(slv_bready_s),
	.s_bresp_i(slv_bresp_s)
);

axi_uart inst_uart (
	.clk_i(clk_i),
	.rst_i(rst_i),
	//// AXI interface
	// Read Address (AR) channel
	.arvalid_i(uart_arvalid_s),
	.aready_o(uart_aready_s),
	.araddr_i(uart_araddr_s),
	// Read Data (R) channel
	.rvalid_o(uart_rvalid_s),
	.rready_i(uart_rready_s),
	.rdata_o(uart_rdata_s),
	.rresp_o(uart_rresp_s),
	// Write Address (AW) channel
	.awvalid_i(uart_awvalid_s),
	.awready_o(uart_awready_s),
	.awaddr_i(uart_awaddr_s),
	// Write Data (W) channel
	.wvalid_i(uart_wvalid_s),
	.wready_o(uart_wready_s),
	.wdata_i(uart_wdata_s),
	.wstrb_i(uart_wstrb_s),
	// Write Response (B) channel
	.bvalid_o(uart_bvalid_s),
	.bready_i(uart_bready_s),
	.bresp_o(uart_bresp_s),
	//// UART interface
	.rx_i(rx_i),
	.tx_o(tx_o)
);

STARTUPE2 #(
   .PROG_USR("FALSE"),  // Activate program event security feature. Requires encrypted bitstreams.
   .SIM_CCLK_FREQ(0.0)  // Set the Configuration Clock Frequency(ns) for simulation.
)
STARTUPE2_inst (
   .CFGCLK(),       // 1-bit output: Configuration main clock output
   .CFGMCLK(),     // 1-bit output: Configuration internal oscillator clock output
   .EOS(),             // 1-bit output: Active high output signal indicating the End Of Startup.
   .PREQ(),           // 1-bit output: PROGRAM request to fabric output
   .CLK(1'b0),             // 1-bit input: User start-up clock input
   .GSR(1'b0),             // 1-bit input: Global Set/Reset input (GSR cannot be used for the port name)
   .GTS(1'b0),             // 1-bit input: Global 3-state input (GTS cannot be used for the port name)
   .KEYCLEARB(1'b0), // 1-bit input: Clear AES Decrypter Key input from Battery-Backed RAM (BBRAM)
   .PACK(1'b0),           // 1-bit input: PROGRAM acknowledge input
   .USRCCLKO(spi_sck_o),   // 1-bit input: User CCLK input
                          // For Zynq-7000 devices, this input must be tied to GND
   .USRCCLKTS(1'b0), // 1-bit input: User CCLK 3-state enable input
                          // For Zynq-7000 devices, this input must be tied to VCC
   .USRDONEO(1'b1),   // 1-bit input: User DONE pin output control
   .USRDONETS(1'b1)  // 1-bit input: User DONE 3-state enable output
);


axi_quad_spi_0 inst_qspi (
  .ext_spi_clk(clk_i),      // input wire ext_spi_clk
  .s_axi_aclk(clk_i),        // input wire s_axi_aclk
  .s_axi_aresetn(rst_i),  // input wire s_axi_aresetn
  .s_axi_awaddr(qspi_awaddr_s[6:0]),    // input wire [6 : 0] s_axi_awaddr
  .s_axi_awvalid(qspi_awvalid_s),  // input wire s_axi_awvalid
  .s_axi_awready(qspi_awready_s),  // output wire s_axi_awready
  .s_axi_wdata(qspi_wdata_s),      // input wire [31 : 0] s_axi_wdata
  .s_axi_wstrb({4{qspi_wvalid_s}}),      // input wire [3 : 0] s_axi_wstrb
  .s_axi_wvalid(qspi_wvalid_s),    // input wire s_axi_wvalid
  .s_axi_wready(qspi_wready_s),    // output wire s_axi_wready
  .s_axi_bresp(qspi_bresp_s),      // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid(qspi_bvalid_s),    // output wire s_axi_bvalid
  .s_axi_bready(qspi_bready_s),    // input wire s_axi_bready
  .s_axi_araddr(qspi_araddr_s[6:0]),    // input wire [6 : 0] s_axi_araddr
  .s_axi_arvalid(qspi_arvalid_s),  // input wire s_axi_arvalid
  .s_axi_arready(qspi_aready_s),  // output wire s_axi_arready
  .s_axi_rdata(qspi_rdata_s),      // output wire [31 : 0] s_axi_rdata
  .s_axi_rresp(qspi_rresp_s),      // output wire [1 : 0] s_axi_rresp
  .s_axi_rvalid(qspi_rvalid_s),    // output wire s_axi_rvalid
  .s_axi_rready(qspi_rready_s),    // input wire s_axi_rready
  .io0_i(1'b0),                  // input wire io0_i
  .io0_o(spi_mosi_o),                  // output wire io0_o
  .io0_t(),                  // output wire io0_t
  .io1_i(spi_miso_i),                  // input wire io1_i
  .io1_o(),                  // output wire io1_o
  .io1_t(),                  // output wire io1_t
  .sck_i(1'b0),
  .sck_o(spi_sck_o),
  .sck_t(),
  .ss_i(1'b0),                    // input wire [0 : 0] ss_i
  .ss_o(spi_cs_no),                    // output wire [0 : 0] ss_o
  .ss_t(),                    // output wire ss_t
  .ip2intc_irpt()    // output wire ip2intc_irpt
);
assign wp_no = 1'b1;
assign hold_no = 1'b1;

axi_slave inst_axi_slave (
	.clk_i(clk_i),
	.rst_i(rst_i),
	//// AXI interface
	// Read Address (AR) channel
	.arvalid_i(ram_arvalid_s),
	.aready_o(ram_aready_s),
	.araddr_i(ram_araddr_s),
	// Read Data (R) channel
	.rvalid_o(ram_rvalid_s),
	.rready_i(ram_rready_s),
	.rdata_o(ram_rdata_s),
	.rresp_o(ram_rresp_s),
	// Write Address (AW) channel
	.awvalid_i(ram_awvalid_s),
	.awready_o(ram_awready_s),
	.awaddr_i(ram_awaddr_s),
	// Write Data (W) channel
	.wvalid_i(ram_wvalid_s),
	.wready_o(ram_wready_s),
	.wdata_i(ram_wdata_s),
	.wstrb_i(ram_wstrb_s),
	// Write Response (B) channel
	.bvalid_o(ram_bvalid_s),
	.bready_i(ram_bready_s),
	.bresp_o(ram_bresp_s),
	// Handshake interface
	.hs_read_o(ram_rd_en_s),
	.hs_write_o(ram_wr_en_s),
	.hs_addr_o(ram_addr_s),
	.hs_data_o(ram_data_o_s),
	.hs_ready_i(ram_ready_s),
	.hs_data_i(ram_data_i_s),
	.byte_select_o(ram_byte_select_s)
);

ram_wrapper inst_ram_wrapper(	
	.clk_i(clk_i),
	.rst_i(rst_i),
	.read_i(ram_rd_en_s),
	.write_i(ram_wr_en_s),
	.addr_i(ram_addr_s[16:2]),
	.data_i(ram_data_o_s),
	.mem_ready_o(ram_ready_s),
	.data_o(ram_data_i_s),
	.byte_select_i(ram_byte_select_s)
);



// 100 MHz -> 200 MHz
wire clk_ref_s; 
clk_wiz_0 inst_clock_mul (
    // Clock out ports
    .clk_out1(clk_ref_s),     // output clk_out1
    // Status and control signals
    .resetn(rst_i), // input resetn
    .locked(locked_o),       // output locked
   // Clock in ports
    .clk_in1(clk_i)      // input clk_in1
);

wire ui_clk_s, ui_rst_s;

axi_cdc inst_axi_cdc (
	//// AXI master interface
	.m_clk_i(clk_i),
	.m_rst_i(rst_i),
	// Read Address (AR) channel
	.m_arvalid_i(ddr_arvalid_s),
	.m_aready_o(ddr_aready_s),
	.m_araddr_i(ddr_araddr_s),
	// Read Data (R) channel
	.m_rvalid_o(ddr_rvalid_s),
	.m_rready_i(ddr_rready_s),
	.m_rdata_o(ddr_rdata_s),
	.m_rresp_o(ddr_rresp_s),
	// Write Address (AW) channel
	.m_awvalid_i(ddr_awvalid_s),
	.m_awready_o(ddr_awready_s),
	.m_awaddr_i(ddr_awaddr_s),
	// Write Data (W) channel
	.m_wvalid_i(ddr_wvalid_s),
	.m_wready_o(ddr_wready_s),
	.m_wdata_i(ddr_wdata_s),
	// Write Response (B) channel
	.m_bvalid_o(ddr_bvalid_s),
	.m_bready_i(ddr_bready_s),
	.m_bresp_o(ddr_bresp_s),
	//// AXI slave interface
	.s_clk_i(ui_clk_s),
	.s_rst_i(init_calib_complete_o),
	// Read Address (AR) channel
	.s_arvalid_o(ddr_ref_arvalid_s),
	.s_aready_i(ddr_ref_aready_s),
	.s_araddr_o(ddr_ref_araddr_s),
	// Read Data (R) channel
	.s_rvalid_i(ddr_ref_rvalid_s),
	.s_rready_o(ddr_ref_rready_s),
	.s_rdata_i(ddr_ref_rdata_s),
	.s_rresp_i(ddr_ref_rresp_s),
	// Write Address (AW) channel
	.s_awvalid_o(ddr_ref_awvalid_s),
	.s_awready_i(ddr_ref_awready_s),
	.s_awaddr_o(ddr_ref_awaddr_s),
	// Write Data (W) channel
	.s_wvalid_o(ddr_ref_wvalid_s),
	.s_wready_i(ddr_ref_wready_s),
	.s_wdata_o(ddr_ref_wdata_s),
	// Write Response (B) channel
	.s_bvalid_i(ddr_ref_bvalid_s),
	.s_bready_o(ddr_ref_bready_s),
	.s_bresp_i(ddr_ref_bresp_s)
);

// Connections to simulate without ddr controller
assign ui_clk_s = clk_i;
assign init_calib_complete_o = 1'b0;

/*
mig_7series_0 inst_ddr_ctrl (

    // Memory interface ports
    .ddr3_addr                      (ddr3_addr),  // output [13:0]		ddr3_addr
    .ddr3_ba                        (ddr3_ba),  // output [2:0]		ddr3_ba
    .ddr3_cas_n                     (ddr3_cas_n),  // output			ddr3_cas_n
    .ddr3_ck_n                      (ddr3_ck_n),  // output [0:0]		ddr3_ck_n
    .ddr3_ck_p                      (ddr3_ck_p),  // output [0:0]		ddr3_ck_p
    .ddr3_cke                       (ddr3_cke),  // output [0:0]		ddr3_cke
    .ddr3_ras_n                     (ddr3_ras_n),  // output			ddr3_ras_n
    .ddr3_reset_n                   (ddr3_reset_n),  // output			ddr3_reset_n
    .ddr3_we_n                      (ddr3_we_n),  // output			ddr3_we_n
    .ddr3_dq                        (ddr3_dq),  // inout [15:0]		ddr3_dq
    .ddr3_dqs_n                     (ddr3_dqs_n),  // inout [1:0]		ddr3_dqs_n
    .ddr3_dqs_p                     (ddr3_dqs_p),  // inout [1:0]		ddr3_dqs_p
    .init_calib_complete            (init_calib_complete_o),  // output			init_calib_complete      
	.ddr3_cs_n                      (ddr3_cs_n),  // output [0:0]		ddr3_cs_n
    .ddr3_dm                        (ddr3_dm),  // output [1:0]		ddr3_dm
    .ddr3_odt                       (ddr3_odt),  // output [0:0]		ddr3_odt

    // Application interface ports
    .ui_clk                         (ui_clk_s),  // output			ui_clk
    .ui_clk_sync_rst                (ui_rst_s),  // output			ui_clk_sync_rst
    .mmcm_locked                    (),  // output			mmcm_locked
    .aresetn                        (rst_i),  // input			aresetn
    .app_sr_req                     (1'd0),  // input			app_sr_req
    .app_ref_req                    (1'd0),  // input			app_ref_req
    .app_zq_req                     (1'd0),  // input			app_zq_req
    .app_sr_active                  (),  // output			app_sr_active
    .app_ref_ack                    (),  // output			app_ref_ack
    .app_zq_ack                     (),  // output			app_zq_ack

    // Slave Interface Write Address Ports
    .s_axi_awid                     (1'd0),  // input [0:0]			s_axi_awid
    .s_axi_awaddr                   (ddr_ref_awaddr_s[27:0]),  // input [27:0]			s_axi_awaddr
    .s_axi_awlen                    (8'd0),  // input [7:0]			s_axi_awlen
    .s_axi_awsize                   (3'd2),  // input [2:0]			s_axi_awsize
    .s_axi_awburst                  (2'd1),  // input [1:0]			s_axi_awburst
    .s_axi_awlock                   (1'd0),  // input [0:0]			s_axi_awlock
    .s_axi_awcache                  (4'd0),  // input [3:0]			s_axi_awcache
    .s_axi_awprot                   (3'd0),  // input [2:0]			s_axi_awprot
    .s_axi_awqos                    (4'd0),  // input [3:0]			s_axi_awqos
    .s_axi_awvalid                  (ddr_ref_awvalid_s),  // input			s_axi_awvalid
    .s_axi_awready                  (ddr_ref_awready_s),  // output			s_axi_awready
    // Slave Interface Write Data Ports
    .s_axi_wdata                    (ddr_ref_wdata_s),  // input [31:0]			s_axi_wdata
    .s_axi_wstrb                    ({4{ddr_ref_wvalid_s}}),  // input [3:0]			s_axi_wstrb
    .s_axi_wlast                    (1'd1),  // input			s_axi_wlast
    .s_axi_wvalid                   (ddr_ref_wvalid_s),  // input			s_axi_wvalid
    .s_axi_wready                   (ddr_ref_wready_s),  // output			s_axi_wready
    // Slave Interface Write Response Ports
    .s_axi_bid                      (),  // output [0:0]			s_axi_bid
    .s_axi_bresp                    (ddr_ref_bresp_s),  // output [1:0]			s_axi_bresp
    .s_axi_bvalid                   (ddr_ref_bvalid_s),  // output			s_axi_bvalid
    .s_axi_bready                   (ddr_ref_bready_s),  // input			s_axi_bready
    // Slave Interface Read Address Ports
    .s_axi_arid                     (1'd0),  // input [0:0]			s_axi_arid
    .s_axi_araddr                   (ddr_ref_araddr_s[27:0]),  // input [27:0]			s_axi_araddr
    .s_axi_arlen                    (8'd0),  // input [7:0]			s_axi_arlen
    .s_axi_arsize                   (3'd2),  // input [2:0]			s_axi_arsize
    .s_axi_arburst                  (2'd1),  // input [1:0]			s_axi_arburst
    .s_axi_arlock                   (1'd0),  // input [0:0]			s_axi_arlock
    .s_axi_arcache                  (4'd0),  // input [3:0]			s_axi_arcache
    .s_axi_arprot                   (3'd0),  // input [2:0]			s_axi_arprot
    .s_axi_arqos                    (4'd0),  // input [3:0]			s_axi_arqos
    .s_axi_arvalid                  (ddr_ref_arvalid_s),  // input			s_axi_arvalid
    .s_axi_arready                  (ddr_ref_aready_s),  // output			s_axi_arready
    // Slave Interface Read Data Ports
    .s_axi_rid                      (),  // output [0:0]			s_axi_rid
    .s_axi_rdata                    (ddr_ref_rdata_s),  // output [31:0]			s_axi_rdata
    .s_axi_rresp                    (ddr_ref_rresp_s),  // output [1:0]			s_axi_rresp
    .s_axi_rlast                    (),  // output			s_axi_rlast
    .s_axi_rvalid                   (ddr_ref_rvalid_s),  // output			s_axi_rvalid
    .s_axi_rready                   (ddr_ref_rready_s),  // input			s_axi_rready
    // System Clock Ports
    .sys_clk_i                       (clk_i),
    // Reference Clock Ports
    .clk_ref_i                      (clk_ref_s),
    .device_temp_i                  (12'd0),  // input [11:0]			device_temp_i
    .device_temp                    (),  // output [11:0] device_temp
    .sys_rst                        (rst_i) // input sys_rst
    );
*/
endmodule