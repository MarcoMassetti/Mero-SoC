module axi_cdc (	
		//// AXI master interface
		input  m_clk_i,
		input  m_rst_i,
		// Read Address (AR) channel
		input  m_arvalid_i,
		output m_aready_o,
		input [31:0] m_araddr_i,
		// Read Data (R) channel
		output m_rvalid_o,
		input  m_rready_i,
		output [31:0] m_rdata_o,
		output [1:0] m_rresp_o,
		// Write Address (AW) channel
		input  m_awvalid_i,
		output m_awready_o,
		input  [31:0] m_awaddr_i,
		// Write Data (W) channel
		input  m_wvalid_i,
		output m_wready_o,
		input  [31:0] m_wdata_i,
		// Write Response (B) channel
		output m_bvalid_o,
		input  m_bready_i,
		output [1:0] m_bresp_o,
		
		//// AXI slaves interface
		input  s_clk_i,
		input  s_rst_i,
		// Read Address (AR) channel
		output s_arvalid_o,
		input  s_aready_i,
		output [31:0] s_araddr_o,
		// Read Data (R) channel
		input  s_rvalid_i,
		output s_rready_o,
		input  [31:0] s_rdata_i,
		input  [1:0] s_rresp_i,
		// Write Address (AW) channel
		output s_awvalid_o,
		input  s_awready_i,
		output [31:0] s_awaddr_o,
		// Write Data (W) channel
		output s_wvalid_o,
		input  s_wready_i,
		output [31:0] s_wdata_o,
		// Write Response (B) channel
		input  s_bvalid_i,
		output s_bready_o,
		input  [1:0] s_bresp_i
);

//// Read Address (AR) channel CDC
// m_arvalid_i and empty_wr_o rising edge detectors
reg m_arvalid_r, fifo_ar_empty_wr_r;
wire fifo_ar_wr_s, fifo_ar_empty_wr_s;
always @(posedge m_clk_i) begin
	if(m_rst_i == 1'd0) begin
		m_arvalid_r  <= 1'b0;
		fifo_ar_empty_wr_r <= 1'b0;
	end else begin
		m_arvalid_r  <= m_arvalid_i;
		fifo_ar_empty_wr_r <= fifo_ar_empty_wr_s;
	end
end
assign fifo_ar_wr_s = (m_arvalid_i && !m_arvalid_r);
assign m_aready_o = (fifo_ar_empty_wr_s && !fifo_ar_empty_wr_r);
// CDC fifo
async_fifo  #(
	.DEPTH(4),
	.DATA_WIDTH(32),
	.PTR_WIDTH(2)
	)
	inst_async_fifo_ar (	
	// Write port
	.wr_clk_i(m_clk_i), 
	.wr_rst_i(m_rst_i),
	.wr_en_i(fifo_ar_wr_s),
  	.wr_data_i(m_araddr_i),
	.full_o(),
	.empty_wr_o(fifo_ar_empty_wr_s),
	// Read port
  	.rd_clk_i(s_clk_i), 
	.rd_rst_i(s_rst_i),
  	.rd_en_i(s_aready_i),
  	.rd_data_o(s_araddr_o),
  	.empty_o(),
	.not_empty_o(s_arvalid_o)
);


//// Read Data (R) channel
// s_rvalid_i and empty_wr_o edge detectors
reg s_rvalid_r, fifo_r_empty_wr_r;
wire fifo_r_wr_s, fifo_r_empty_wr_s;
always @(posedge s_clk_i) begin
	if(s_rst_i == 1'd0) begin
		s_rvalid_r  <= 1'b0;
		fifo_r_empty_wr_r <= 1'b0;
	end else begin
		s_rvalid_r  <= s_rvalid_i;
		fifo_r_empty_wr_r <= fifo_r_empty_wr_s;
	end
end
assign fifo_r_wr_s = (s_rvalid_i && !s_rvalid_r);
assign s_rready_o = (fifo_r_empty_wr_s && !fifo_r_empty_wr_r);
// Unpacking of rd_data
wire [(32+2)-1:0] fifo_r_data_s;
assign m_rresp_o = fifo_r_data_s[33:32];
assign m_rdata_o = fifo_r_data_s[31:0];
// CDC fifo
async_fifo  #(
	.DEPTH(4),
	.DATA_WIDTH(32+2),
	.PTR_WIDTH(2)
	)
	inst_async_fifo_r (	
	// Write port
	.wr_clk_i(s_clk_i), 
	.wr_rst_i(s_rst_i),
	.wr_en_i(fifo_r_wr_s),
  	.wr_data_i({s_rresp_i,s_rdata_i}),
	.full_o(),
	.empty_wr_o(fifo_r_empty_wr_s),
	// Read port
  	.rd_clk_i(m_clk_i), 
	.rd_rst_i(m_rst_i),
  	.rd_en_i(m_rready_i),
  	.rd_data_o(fifo_r_data_s),
  	.empty_o(),
	.not_empty_o(m_rvalid_o)
);


//// Write Address (AW) channel CDC
// m_awvalid_i and empty_wr_o rising edge detectors
reg m_awvalid_r, fifo_aw_empty_wr_r;
wire fifo_aw_wr_s, fifo_aw_empty_wr_s;
always @(posedge m_clk_i) begin
	if(m_rst_i == 1'd0) begin
		m_awvalid_r  <= 1'b0;
		fifo_aw_empty_wr_r <= 1'b0;
	end else begin
		m_awvalid_r  <= m_awvalid_i;
		fifo_aw_empty_wr_r <= fifo_aw_empty_wr_s;
	end
end
assign fifo_aw_wr_s = (m_awvalid_i && !m_awvalid_r);
assign m_awready_o = (fifo_aw_empty_wr_s && !fifo_aw_empty_wr_r);
// CDC fifo
async_fifo  #(
	.DEPTH(4),
	.DATA_WIDTH(32),
	.PTR_WIDTH(2)
	)
	inst_async_fifo_aw (	
	// Write port
	.wr_clk_i(m_clk_i), 
	.wr_rst_i(m_rst_i),
	.wr_en_i(fifo_aw_wr_s),
  	.wr_data_i(m_awaddr_i),
	.full_o(),
	.empty_wr_o(fifo_aw_empty_wr_s),
	// Read port
  	.rd_clk_i(s_clk_i), 
	.rd_rst_i(s_rst_i),
  	.rd_en_i(s_awready_i),
  	.rd_data_o(s_awaddr_o),
  	.empty_o(),
	.not_empty_o(s_awvalid_o)
);


//// Write Data (W) channel CDC
// m_wvalid_i and empty_wr_o rising edge detectors
reg m_wvalid_r, fifo_w_empty_wr_r;
wire fifo_w_wr_s, fifo_w_empty_wr_s;
always @(posedge m_clk_i) begin
	if(m_rst_i == 1'd0) begin
		m_wvalid_r  <= 1'b0;
		fifo_w_empty_wr_r <= 1'b0;
	end else begin
		m_wvalid_r  <= m_wvalid_i;
		fifo_w_empty_wr_r <= fifo_w_empty_wr_s;
	end
end
assign fifo_w_wr_s = (m_wvalid_i && !m_wvalid_r);
assign m_wready_o = (fifo_w_empty_wr_s && !fifo_w_empty_wr_r);
// CDC fifo
async_fifo  #(
	.DEPTH(4),
	.DATA_WIDTH(32),
	.PTR_WIDTH(2)
	)
	inst_async_fifo_w (	
	// Write port
	.wr_clk_i(m_clk_i), 
	.wr_rst_i(m_rst_i),
	.wr_en_i(fifo_w_wr_s),
  	.wr_data_i(m_wdata_i),
	.full_o(),
	.empty_wr_o(fifo_w_empty_wr_s),
	// Read port
  	.rd_clk_i(s_clk_i), 
	.rd_rst_i(s_rst_i),
  	.rd_en_i(s_wready_i),
  	.rd_data_o(s_wdata_o),
  	.empty_o(),
	.not_empty_o(s_wvalid_o)
);


//// Write Response (B) channel
// s_bvalid_i and empty_wr_o edge detectors
reg s_bvalid_r, fifo_b_empty_wr_r;
wire fifo_b_wr_s, fifo_b_empty_wr_s;
always @(posedge s_clk_i) begin
	if(s_rst_i == 1'd0) begin
		s_bvalid_r  <= 1'b0;
		fifo_b_empty_wr_r <= 1'b0;
	end else begin
		s_bvalid_r  <= s_bvalid_i;
		fifo_b_empty_wr_r <= fifo_b_empty_wr_s;
	end
end
assign fifo_b_wr_s = (s_bvalid_i && !s_bvalid_r);
assign s_bready_o = (fifo_b_empty_wr_s && !fifo_b_empty_wr_r);
// CDC fifo
async_fifo  #(
	.DEPTH(4),
	.DATA_WIDTH(2),
	.PTR_WIDTH(2)
	)
	inst_async_fifo_b (	
	// Write port
	.wr_clk_i(s_clk_i), 
	.wr_rst_i(s_rst_i),
	.wr_en_i(fifo_b_wr_s),
  	.wr_data_i(s_bresp_i),
	.full_o(),
	.empty_wr_o(fifo_b_empty_wr_s),
	// Read port
  	.rd_clk_i(m_clk_i), 
	.rd_rst_i(m_rst_i),
  	.rd_en_i(m_bready_i),
  	.rd_data_o(m_bresp_o),
  	.empty_o(),
	.not_empty_o(m_bvalid_o)
);

endmodule
