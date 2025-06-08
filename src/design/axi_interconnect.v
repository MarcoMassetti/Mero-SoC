module axi_interconnect #(
		parameter N_MST = 1,
		parameter N_SLV = 4,
		parameter SLV_SEL_ADDR_BITS = 16,
  		parameter [(SLV_SEL_ADDR_BITS*N_SLV)-1:0] SLV_ADDRESSES = 'd0
		) (	
		input  clk_i,
		input  rst_i,
		
		//// AXI master interface
		// Read Address (AR) channel
		input  [N_MST-1:0] m_arvalid_i,
		output reg [N_MST-1:0] m_aready_o,
		input  [(32*N_MST)-1:0] m_araddr_i,

		// Read Data (R) channel
		output reg [N_MST-1:0] m_rvalid_o,
		input  [N_MST-1:0] m_rready_i,
		output [(32*N_MST)-1:0] m_rdata_o,
		output [(2*N_MST)-1:0] m_rresp_o,

		// Write Address (AW) channel
		input  [N_MST-1:0] m_awvalid_i,
		output reg [N_MST-1:0] m_awready_o,
		input  [(32*N_MST)-1:0] m_awaddr_i,

		// Write Data (W) channel
		input  [N_MST-1:0] m_wvalid_i,
		output reg [N_MST-1:0] m_wready_o,
		input  [(32*N_MST)-1:0] m_wdata_i,

		// Write Response (B) channel
		output reg [N_MST-1:0] m_bvalid_o,
		input  [N_MST-1:0] m_bready_i,
		output [(2*N_MST)-1:0] m_bresp_o,
		
		
		//// AXI slaves interfaces
		// Read Address (AR) channel
		output reg [N_SLV-1:0] s_arvalid_o,
		input  [N_SLV-1:0] s_aready_i,
		output [(32*N_SLV)-1:0] s_araddr_o,

		// Read Data (R) channel
		input  [N_SLV-1:0] s_rvalid_i,
		output reg [N_SLV-1:0] s_rready_o,
		input  [(32*N_SLV)-1:0] s_rdata_i,
		input  [(2*N_SLV)-1:0] s_rresp_i,

		// Write Address (AW) channel
		output reg [N_SLV-1:0] s_awvalid_o,
		input  [N_SLV-1:0] s_awready_i,
		output [(32*N_SLV)-1:0] s_awaddr_o,

		// Write Data (W) channel
		output reg [N_SLV-1:0] s_wvalid_o,
		input  [N_SLV-1:0] s_wready_i,
		output [(32*N_SLV)-1:0] s_wdata_o,

		// Write Response (B) channel
		input  [N_SLV-1:0] s_bvalid_i,
		output reg [N_SLV-1:0] s_bready_o,
		input  [(2*N_SLV)-1:0] s_bresp_i
);

// Variables for for loops
integer i, j;

// Unpcked addresses for the slave interfaces
wire [SLV_SEL_ADDR_BITS-1:0] SLV_ADDRESSES_UNPACKED [N_SLV-1:0];

// Unpacked arrays of master interfaces
wire [31:0] m_araddr_i_unpacked [N_MST-1:0];
reg  [31:0] m_rdata_o_unpacked  [N_MST-1:0];
reg  [1:0]  m_rresp_o_unpacked  [N_MST-1:0];
wire [31:0] m_awaddr_i_unpacked [N_MST-1:0];
wire [31:0] m_wdata_i_unpacked  [N_MST-1:0];
reg  [1:0]  m_bresp_o_unpacked  [N_MST-1:0];

// Unpacked arrays of slave interfaces
reg  [31:0] s_araddr_o_unpacked [N_SLV-1:0];
wire [31:0] s_rdata_i_unpacked  [N_SLV-1:0];
wire [1:0]  s_rresp_i_unpacked  [N_SLV-1:0];
reg  [31:0] s_awaddr_o_unpacked [N_SLV-1:0];
reg  [31:0] s_wdata_o_unpacked  [N_SLV-1:0];
wire [1:0]  s_bresp_i_unpacked  [N_SLV-1:0];

// Packing/Unpacking of master interfaces
genvar mst_pck;
generate
	for (mst_pck = 0; mst_pck < N_MST; mst_pck = mst_pck + 1) begin : gen_mst_pack
		// Unpacking of inputs
		assign m_araddr_i_unpacked[mst_pck] = m_araddr_i[(mst_pck*32)+31:mst_pck*32];
		assign m_awaddr_i_unpacked[mst_pck] = m_awaddr_i[(mst_pck*32)+31:mst_pck*32];
		assign m_wdata_i_unpacked[mst_pck]  = m_wdata_i[(mst_pck*32)+31:mst_pck*32];
		// Packing of outputs
		assign m_rdata_o[(mst_pck*32)+31:mst_pck*32] = m_rdata_o_unpacked[mst_pck];
		assign m_rresp_o[(mst_pck*2)+1:mst_pck*2]    = m_rresp_o_unpacked[mst_pck];
		assign m_bresp_o[(mst_pck*2)+1:mst_pck*2]    = m_bresp_o_unpacked[mst_pck];
	end
endgenerate

// Packing/Unpacking of slave interfaces
genvar slv_pck;
generate
	for (slv_pck = 0; slv_pck < N_SLV; slv_pck = slv_pck + 1) begin : gen_slv_pack
		// Unpacking of addresses
		assign SLV_ADDRESSES_UNPACKED[slv_pck] = SLV_ADDRESSES[(slv_pck*SLV_SEL_ADDR_BITS)+(SLV_SEL_ADDR_BITS-1):slv_pck*SLV_SEL_ADDR_BITS];
		// Unpacking of inputs
		assign s_rdata_i_unpacked[slv_pck] = s_rdata_i[(slv_pck*32)+31:slv_pck*32];
		assign s_rresp_i_unpacked[slv_pck] = s_rresp_i[(slv_pck*2)+1:slv_pck*2];
		assign s_bresp_i_unpacked[slv_pck] = s_bresp_i[(slv_pck*2)+1:slv_pck*2];
		// Packing of outputs
		assign s_araddr_o[(slv_pck*32)+31:slv_pck*32] = s_araddr_o_unpacked[slv_pck];
		assign s_awaddr_o[(slv_pck*32)+31:slv_pck*32] = s_awaddr_o_unpacked[slv_pck];
		assign s_wdata_o[(slv_pck*32)+31:slv_pck*32]  = s_wdata_o_unpacked[slv_pck];
	end
endgenerate


// Signals and encoding for FSM status
reg [3:0] current_state_r [N_MST-1:0];
reg [3:0] next_state_s [N_MST-1:0];
localparam IDLE    = 4'd0;
localparam AR_TR   = 4'd1;
localparam R_TR    = 4'd2;
localparam W_TR    = 4'd3;
localparam WAIT_AW = 4'd4;
localparam WAIT_W  = 4'd5;
localparam B_TR    = 4'd6;

// Signals to indicate if a slave is busy
reg [0:N_MST-1] slv_sel_s [N_SLV-1:0];
reg [0:N_MST-1] slv_clr_s [N_SLV-1:0];
reg [0:N_SLV-1] slv_busy_r;

// Register to store the slave selected by each master
localparam WIDTH_SLV = $clog2(N_SLV);
reg [WIDTH_SLV-1:0] selected_slv_r [N_MST-1:0];

// Register to store wich master has selected a slave
localparam WIDTH_MST = $clog2(N_MST);
reg [WIDTH_MST-1:0] selecting_mst_r [N_SLV-1:0];

// Other registers
always @(posedge clk_i) begin
	if(rst_i == 1'd0) begin
		slv_busy_r <= 'b0;
		for (i = 0; i < N_MST; i = i + 1) begin
			selected_slv_r[i] <= 'b0;
		end
		for (i = 0; i < N_SLV; i = i + 1) begin
			selecting_mst_r[i] <= 'b0;
		end
	end else begin
		// Update slaves busy/selected flags 
		for (i = 0; i < N_SLV; i = i + 1) begin
			for (j = 0; j < N_MST; j = j + 1) begin
				if (slv_sel_s[i][j]) begin
					slv_busy_r[i] <= 'b1;
					selected_slv_r[j] <= i;
					selecting_mst_r[i] <= j;
				end else if (slv_clr_s[i][j]) begin
					slv_busy_r[i] <= 'b0;
					selected_slv_r[j] <= 'b0;
					selecting_mst_r[i] <= 'b0;
				end
			end
		end
	end
end

// Generation of FSMs towards master interfaces
genvar mst_fsm;
generate
	for (mst_fsm = 0; mst_fsm < N_MST; mst_fsm = mst_fsm + 1) begin : gen_mst_fsm
		// FSM present state update
		always @(posedge clk_i) begin
			if(rst_i == 1'd0) begin
				current_state_r[mst_fsm] <= IDLE;
			end else begin
				current_state_r[mst_fsm] <= next_state_s[mst_fsm];
			end
		end

		// FSM next state calculation
		always @(*) begin
			// Default next state
			next_state_s[mst_fsm] = current_state_r[mst_fsm];
			// Do not select/clear any slave by default
			for (i = 0; i < N_SLV; i = i + 1) begin
				slv_sel_s[i][mst_fsm] = 1'b0;
				slv_clr_s[i][mst_fsm] = 1'b0;
			end

			case(current_state_r[mst_fsm])
				// Idle: wait for new request from master interface
				IDLE : begin
					if (m_arvalid_i[mst_fsm]) begin
						// Master requesting read transaction
						// Decode slave address
						for (i = 0; i < N_SLV; i = i + 1) begin
							if (m_araddr_i_unpacked[mst_fsm][31:(32-SLV_SEL_ADDR_BITS)] == SLV_ADDRESSES_UNPACKED[i]) begin
								// Check if slave is not busy and not selected by higher priority master
								if (slv_busy_r[i] == 1'b0 && slv_sel_s[i][mst_fsm:0] == 'd0) begin
									// Mark slave as busy
									slv_sel_s[i][mst_fsm] = 1'b1;
									// Start read transaction
									next_state_s[mst_fsm] = AR_TR;
								end // if (slv_busy_r[i] == 1'b0 && ...
							end // if (m_araddr_i_unpacked[mst_fsm][...
						end // for (i = 0; i < N_SLV; i = i + 1)
					end else if (m_awvalid_i[mst_fsm]) begin
						// Master requesting write transaction
						for (i = 0; i < N_SLV; i = i + 1) begin
							if (m_awaddr_i_unpacked[mst_fsm][31:(32-SLV_SEL_ADDR_BITS)] == SLV_ADDRESSES_UNPACKED[i]) begin
								// Check if slave is not busy and not selected by higher priority master
								if (slv_busy_r[i] == 1'b0 && slv_sel_s[i][mst_fsm:0] == 'd0) begin
									// Mark slave as busy
									slv_sel_s[i][mst_fsm] = 1'b1;
									// Start write transaction
									next_state_s[mst_fsm] = W_TR;	
								end // if (slv_busy_r[i] == 1'b0 && ...
							end // if (m_awaddr_i_unpacked[mst_fsm][...
						end // for (i = 0; i < N_SLV; i = i + 1)
					end // if (m_arvalid_i[mst_fsm])
				end // IDLE
				
				// Read address transfer
				AR_TR : begin
					if (s_aready_i[selected_slv_r[mst_fsm]] && m_arvalid_i[mst_fsm]) begin
						next_state_s[mst_fsm] = R_TR;
					end
				end

				// Read data transfer
				R_TR : begin
					if (s_rvalid_i[selected_slv_r[mst_fsm]] && m_rready_i[mst_fsm]) begin
						next_state_s[mst_fsm] = IDLE;
						// Clear slave busy flag
						slv_clr_s[selected_slv_r[mst_fsm]][mst_fsm] = 1'b1;
					end
				end

				// Write address/data transfer
				W_TR : begin
					// Check if one or both transfers have ended
					if (s_awready_i[selected_slv_r[mst_fsm]] && m_awvalid_i[mst_fsm] &&
					    	s_awready_i[selected_slv_r[mst_fsm]] && m_wvalid_i[mst_fsm]) begin
						next_state_s[mst_fsm] = B_TR;
					end else if (s_awready_i[selected_slv_r[mst_fsm]] && m_awvalid_i[mst_fsm]) begin
						next_state_s[mst_fsm] = WAIT_W;
					end else if (s_awready_i[selected_slv_r[mst_fsm]] && m_wvalid_i[mst_fsm]) begin
						next_state_s[mst_fsm] = WAIT_AW;
					end
				end
				
				// Wait end of write address transfer
				WAIT_AW : begin
					if (s_awready_i[selected_slv_r[mst_fsm]] && m_awvalid_i[mst_fsm]) begin
						next_state_s[mst_fsm] = B_TR;
					end
				end

				// Wait end of write data transfer
				WAIT_W : begin
					if (s_awready_i[selected_slv_r[mst_fsm]] && m_wvalid_i[mst_fsm]) begin
						next_state_s[mst_fsm] = B_TR;
					end
				end

				// Write response transfer
				B_TR : begin
					if (s_bvalid_i[selected_slv_r[mst_fsm]] && m_bvalid_o[mst_fsm]) begin
						next_state_s[mst_fsm] = IDLE;
						// Clear slave busy flag
						slv_clr_s[selected_slv_r[mst_fsm]][mst_fsm] = 1'b1;
					end
				end

				default : next_state_s[mst_fsm] = IDLE;
			endcase
		end


		// FSM output calculation
		// Routing of signals from selected slave to master
		always @(*) begin
			// Default values
			m_aready_o[mst_fsm] = 'd0;
			m_rvalid_o[mst_fsm] = 'd0;
			m_rdata_o_unpacked[mst_fsm] = 'd0;
			m_rresp_o_unpacked[mst_fsm] = 'd0;
			m_awready_o[mst_fsm] = 'd0;
			m_wready_o[mst_fsm] = 'd0;
			m_bvalid_o[mst_fsm] = 'd0;
			m_bresp_o_unpacked[mst_fsm] = 'd0;

			// Connect signals only when not in idle state
			if (current_state_r[mst_fsm] != IDLE) begin
				m_aready_o[mst_fsm] = s_aready_i[selected_slv_r[mst_fsm]];
				m_rvalid_o[mst_fsm] = s_rvalid_i[selected_slv_r[mst_fsm]];
				m_rdata_o_unpacked[mst_fsm] = s_rdata_i_unpacked[selected_slv_r[mst_fsm]];
				m_rresp_o_unpacked[mst_fsm] = s_rresp_i_unpacked[selected_slv_r[mst_fsm]];
				m_awready_o[mst_fsm] = s_awready_i[selected_slv_r[mst_fsm]];
				m_wready_o[mst_fsm] = s_wready_i[selected_slv_r[mst_fsm]];
				m_bvalid_o[mst_fsm] = s_bvalid_i[selected_slv_r[mst_fsm]];
				m_bresp_o_unpacked[mst_fsm] = s_bresp_i_unpacked[selected_slv_r[mst_fsm]];
			end
		end

	end // for (mst_fsm = 0; mst_fsm < N_MST ...
endgenerate

// Routing of signals from master to slave
genvar slv_idx;
generate
	for (slv_idx = 0; slv_idx < N_SLV; slv_idx = slv_idx + 1) begin : gen_slv_mux
		always @(*) begin
			// Default values
			s_arvalid_o[slv_idx] = 'd0;
			s_araddr_o_unpacked[slv_idx] = 'd0;
			s_rready_o[slv_idx] = 'd0;
			s_awvalid_o[slv_idx] = 'd0;
			s_awaddr_o_unpacked[slv_idx] = 'd0;
			s_wvalid_o[slv_idx] = 'd0;
			s_wdata_o_unpacked[slv_idx] = 'd0;
			s_bready_o[slv_idx] = 'd0;

			// Connect signals only when not in idle
			if (slv_busy_r[slv_idx]) begin
				s_arvalid_o[slv_idx] = m_arvalid_i[selecting_mst_r[slv_idx]];
				s_araddr_o_unpacked[slv_idx] = m_araddr_i_unpacked[selecting_mst_r[slv_idx]];
				s_rready_o[slv_idx] = m_rready_i[selecting_mst_r[slv_idx]];
				s_awvalid_o[slv_idx] = m_awvalid_i[selecting_mst_r[slv_idx]];
				s_awaddr_o_unpacked[slv_idx] = m_awaddr_i_unpacked[selecting_mst_r[slv_idx]];
				s_wvalid_o[slv_idx] = m_wvalid_i[selecting_mst_r[slv_idx]];
				s_wdata_o_unpacked[slv_idx] = m_wdata_i_unpacked[selecting_mst_r[slv_idx]];
				s_bready_o[slv_idx] = m_bready_i[selecting_mst_r[slv_idx]];
			end
		end
	end // for (slv_idx = 0; slv_idx < N_SLV ...
endgenerate

endmodule
