module axi_master(	
		input  clk_i,
		input  rst_i,

		// Handshake interface
		input  hs_read_i,
		input  hs_write_i,
		input  [31:0] hs_addr_i,
		input  [31:0] hs_data_i,
		output reg hs_ready_o,
		output reg [31:0] hs_data_o,
		input [3:0] byte_select_i,
		
		//// AXI interface
		// Read Address (AR) channel
		output reg arvalid_o,
		input  aready_i,
		output reg [31:0] araddr_o,

		// Read Data (R) channel
		input  rvalid_i,
		output reg rready_o,
		input  [31:0] rdata_i,
		input  [1:0] rresp_i,

		// Write Address (AW) channel
		output reg awvalid_o,
		input  awready_i,
		output reg [31:0] awaddr_o,

		// Write Data (W) channel
		output reg wvalid_o,
		input  wready_i,
		output reg [31:0] wdata_o,
		output reg [3:0] wstrb_o,

		// Write Response (B) channel
		input  bvalid_i,
		output reg bready_o,
		input  [1:0] bresp_i
);

// Signal to store data form axi interface
reg rdata_reg_en_s;

// Signals and encoding for FSM status
reg [3:0] current_state_r, next_state_s;
localparam IDLE    = 4'd0;
localparam AR_TR   = 4'd1;
localparam R_TR    = 4'd2;
localparam W_TR    = 4'd3;
localparam WAIT_AW = 4'd4;
localparam WAIT_W  = 4'd5;
localparam B_TR    = 4'd6;
localparam HS_ACK  = 4'd7;

// FSM present state update
always @(posedge clk_i) begin
	if(rst_i == 1'd0) begin
		current_state_r <= 'b0;
	end else begin
		current_state_r <= next_state_s;
	end
end

// FSM next state calculation
always @(*) begin
	// Default next state
	next_state_s = current_state_r;

 	case(current_state_r)
		// Idle: wait for new request from hs interface
  		IDLE : begin
			if (hs_read_i) begin
				// Start read transaction
				next_state_s = AR_TR;
			end else if (hs_write_i) begin
				// Start write transaction
				next_state_s = W_TR;
			end
		end

		// Read address transfer
		AR_TR : begin
			if (aready_i) begin
				next_state_s = R_TR;
			end
		end

		// Read data transfer
		R_TR : begin
			if (rvalid_i) begin
				next_state_s = HS_ACK;
			end
		end

		// Write address/data transfer
		W_TR : begin
			// Check if one or both transfers have ended
			if (awready_i && wready_i) begin
			     next_state_s = B_TR;
			end else if (awready_i) begin
				next_state_s = WAIT_W;
			end else if (wready_i) begin
				next_state_s = WAIT_AW;
			end
		end
		
		// Wait end of write address transfer
		WAIT_AW : begin
			if (awready_i) begin
				next_state_s = B_TR;
			end
		end

		// Wait end of write data transfer
		WAIT_W : begin
			if (wready_i) begin
				next_state_s = B_TR;
			end
		end

		// Write response transfer
		B_TR : begin
			if (bvalid_i) begin
				next_state_s = HS_ACK;
			end
		end

		// Send acknowledge to hs interface
		HS_ACK : begin
			next_state_s = IDLE;
		end
        
        default : next_state_s = IDLE;
	endcase
end

// FSM output calculation
always @(*) begin
	// Default output values
	arvalid_o  = 'b0;
	arvalid_o  = 'b0;
	araddr_o   = 'b0;
	rready_o   = 'b0;
	awvalid_o  = 'b0;
	awaddr_o   = 'b0;
	wvalid_o   = 'b0;
	wdata_o    = 'b0;
	wstrb_o    = 'b0;
	bready_o   = 'b0;

	rdata_reg_en_s = 'b0;
	hs_ready_o = 'b0;

	case(current_state_r)
		// Idle: wait for new request from hs interface
  		IDLE : begin
		end

		// Read address transfer
		AR_TR : begin
			arvalid_o = 'b1;
			araddr_o  = hs_addr_i;
		end

		// Read data transfer
		R_TR : begin
			rready_o  = 'b1;
			rdata_reg_en_s = 'b1;
		end

		// Write address/data transfer
		W_TR : begin
			awvalid_o = 'b1;
			awaddr_o  = hs_addr_i;
			
			wvalid_o = 'b1;
			wdata_o  = hs_data_i;
			wstrb_o  = byte_select_i;
		end

		// Wait end of write address transfer
		WAIT_AW : begin
			awvalid_o = 'b1;
			awaddr_o  = hs_addr_i;
		end
		
		// Wait end of write data transfer
		WAIT_W : begin
			wvalid_o = 'b1;
			wdata_o  = hs_data_i;
			wstrb_o  = byte_select_i;
		end

		// Write response transfer
		B_TR : begin
			bready_o = 'b1;
		end
        
		// Send acknowledge to hs interface
		HS_ACK : begin
			hs_ready_o = 'b1;
		end

        default : begin
		end
	endcase
end

// Register to store data from axi interface
always @(posedge clk_i) begin
	if(rst_i == 1'd0) begin
		hs_data_o <= 'b0;
	end else begin
		if (rdata_reg_en_s == 1'b1) begin
			hs_data_o <= rdata_i;
		end
	end
end

endmodule
