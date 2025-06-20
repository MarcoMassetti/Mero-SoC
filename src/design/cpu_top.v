module cpu_top (
	input  clk_i,
	input  rst_i,
	output reg [3:0] led_o,
	// UART
	output tx_o,
	input  rx_i,
	// SPI
	output spi_cs_no,
	output spi_mosi_o,
	input  spi_miso_i,
	output wp_no,
	output hold_no,
	// PLL
	output locked_o,
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
	end else begin
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

//// MASTER AXI SIGNALS
// Read Address (AR) channel
wire mst_arvalid_s, mst_aready_s;
wire [31:0] mst_araddr_s;
// Read Data (R) channel
wire mst_rvalid_s, mst_rready_s;
wire [31:0] mst_rdata_s;
wire [1:0] mst_rresp_s;
// Write Address (AW) channel
wire mst_awvalid_s, mst_awready_s;
wire [31:0] mst_awaddr_s;
// Write Data (W) channel
wire mst_wvalid_s, mst_wready_s;
wire [31:0] mst_wdata_s;
// Write Response (B) channel
wire mst_bvalid_s, mst_bready_s;
wire [1:0] mst_bresp_s;


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
// Write Response (B) channel
wire qspi_bvalid_s, qspi_bready_s;
wire [1:0] qspi_bresp_s;

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
		.arvalid_o(mst_arvalid_s),
		.aready_i(mst_aready_s),
		.araddr_o(mst_araddr_s),

		// Read Data (R) channel
		.rvalid_i(mst_rvalid_s),
		.rready_o(mst_rready_s),
		.rdata_i(mst_rdata_s),
		.rresp_i(mst_rresp_s),

		// Write Address (AW) channel
		.awvalid_o(mst_awvalid_s),
		.awready_i(mst_awready_s),
		.awaddr_o(mst_awaddr_s),

		// Write Data (W) channel
		.wvalid_o(mst_wvalid_s),
		.wready_i(mst_wready_s),
		.wdata_o(mst_wdata_s),

		// Write Response (B) channel
		.bvalid_i(mst_bvalid_s),
		.bready_o(mst_bready_s),
		.bresp_i(mst_bresp_s)
);


// Packed AXI slave interfaces
localparam N_SLV = 3;
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
// Write Response (B) channel
wire [N_SLV-1:0] slv_bvalid_s, slv_bready_s;
wire [(2*N_SLV)-1:0] slv_bresp_s;


//// Packing/Unpacking of slave interfaces
// Read Address (AR) channel
assign uart_arvalid_s = slv_arvalid_s[0];
assign qspi_arvalid_s = slv_arvalid_s[1];
assign ddr_arvalid_s = slv_arvalid_s[2];
assign slv_aready_s = {ddr_aready_s, qspi_aready_s, uart_aready_s};
assign uart_araddr_s = slv_araddr_s[(0*32)+31:0*32];
assign qspi_araddr_s = slv_araddr_s[(1*32)+31:1*32];
assign ddr_araddr_s = slv_araddr_s[(2*32)+31:2*32];
// Read Data (R) channel
assign slv_rvalid_s = {ddr_rvalid_s, qspi_rvalid_s, uart_rvalid_s};
assign uart_rready_s = slv_rready_s[0];
assign qspi_rready_s = slv_rready_s[1];
assign ddr_rready_s = slv_rready_s[2];
assign slv_rdata_s = {ddr_rdata_s, qspi_rdata_s, uart_rdata_s};
assign slv_rresp_s = {ddr_rresp_s, qspi_rresp_s, uart_rresp_s};
// Write Address (AW) channel
assign uart_awvalid_s = slv_awvalid_s[0];
assign qspi_awvalid_s = slv_awvalid_s[1];
assign ddr_awvalid_s = slv_awvalid_s[2];
assign slv_awready_s = {ddr_awready_s, qspi_awready_s, uart_awready_s};
assign uart_awaddr_s = slv_awaddr_s[(0*32)+31:0*32];
assign qspi_awaddr_s = slv_awaddr_s[(1*32)+31:1*32];
assign ddr_awaddr_s = slv_awaddr_s[(2*32)+31:2*32];
// Write Data (W) channel
assign uart_wvalid_s = slv_wvalid_s[0];
assign qspi_wvalid_s = slv_wvalid_s[1];
assign ddr_wvalid_s = slv_wvalid_s[2];
assign slv_wready_s = {ddr_wready_s, qspi_wready_s, uart_wready_s};
assign uart_wdata_s = slv_wdata_s[(0*32)+31:0*32];
assign qspi_wdata_s = slv_wdata_s[(1*32)+31:1*32];
assign ddr_wdata_s = slv_wdata_s[(2*32)+31:2*32];
// Write Response (B) channel
assign slv_bvalid_s = {ddr_bvalid_s, qspi_bvalid_s, uart_bvalid_s};
assign uart_bready_s = slv_bready_s[0];
assign qspi_bready_s = slv_bready_s[1];
assign ddr_bready_s = slv_bready_s[2];
assign slv_bresp_s = {ddr_bresp_s, qspi_bresp_s, uart_bresp_s};

axi_interconnect  #(
	.N_MST(1),
	.N_SLV(N_SLV),
	.SLV_SEL_ADDR_BITS(15),
	.SLV_ADDRESSES({15'd4, 15'd3, 15'd2})
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

	// Write Response (B) channel
	.s_bvalid_i(slv_bvalid_s),
	.s_bready_o(slv_bready_s),
	.s_bresp_i(slv_bresp_s)
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
  .ss_i(1'b0),                    // input wire [0 : 0] ss_i
  .ss_o(spi_cs_no),                    // output wire [0 : 0] ss_o
  .ss_t(),                    // output wire ss_t
  .cfgclk(),                // output wire cfgclk
  .cfgmclk(),              // output wire cfgmclk
  .eos(),                      // output wire eos
  .preq(),                    // output wire preq
  .ip2intc_irpt()    // output wire ip2intc_irpt
);
assign wp_no = 1'b1;
assign hold_no = 1'b1;



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

endmodule