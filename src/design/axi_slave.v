module axi_slave(	
		input  clk_i,
		input  rst_i,
	
		//// AXI interface
		// Read Address (AR) channel
		input  arvalid_i,
		output reg aready_o,
		input  [31:0] araddr_i,

		// Read Data (R) channel
		output reg rvalid_o,
		input  rready_i,
		output [31:0] rdata_o,
		output [1:0] rresp_o,

		// Write Address (AW) channel
		input  awvalid_i,
		output reg awready_o,
		input  [31:0] awaddr_i,

		// Write Data (W) channel
		input  wvalid_i,
		output reg wready_o,
		input  [31:0] wdata_i,
		input  [3:0] wstrb_i,

		// Write Response (B) channel
		output reg bvalid_o,
		input  bready_i,
		output [1:0] bresp_o,

		// Handshake interface
		output reg hs_read_o,
		output reg hs_write_o,
		output [31:0] hs_addr_o,
		output [31:0] hs_data_o,
		input  hs_ready_i,
		input  [31:0] hs_data_i,
		output [3:0] byte_select_o
);

// Registers to store address/data from axi interface
reg [31:0] wdata_r, araddr_r, awaddr_r;
reg [3:0] wstrb_r;
reg wdata_reg_en_s, araddr_reg_en_s, awaddr_reg_en_s;

// Register to store data from HS interface
reg [31:0] rdata_r;
reg rdata_reg_en_s;

// Signals and encoding for FSM status
reg [3:0] current_state_r, next_state_s;
localparam IDLE       = 4'd0;
localparam WAIT_SLV_R = 4'd1;
localparam R_TR       = 4'd2;
localparam WAIT_SLV_W = 4'd3;
localparam WAIT_AW    = 4'd4;
localparam WAIT_W     = 4'd5; 
localparam B_TR       = 4'd6;


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
		// Idle: wait for new request from axi interface
  		IDLE : begin
			if (arvalid_i) begin
				// Start read transaction
				next_state_s = WAIT_SLV_R;
			end else if (awvalid_i && wvalid_i) begin
				// Start write transaction
				next_state_s = WAIT_SLV_W;
			end else if (awvalid_i) begin
				// Wait end of write data transfer
				next_state_s = WAIT_W;
			end else if (wvalid_i) begin
				// Wait end of write address transfer
				next_state_s = WAIT_AW;
			end
		end

		// Wait until slave provvides data
		WAIT_SLV_R : begin
			if (hs_ready_i) begin
				// Slave has read data
				next_state_s = R_TR;
			end
		end

		// Read data transfer
		R_TR : begin
			if (rready_i) begin
				// Master has sampled the data
				next_state_s = IDLE;
			end
		end

		// Wait until slave writes data
		WAIT_SLV_W : begin
			if (hs_ready_i) begin
				next_state_s = B_TR;
			end
		end

		// Wait end of write address transfer
		WAIT_AW : begin
			if (awvalid_i) begin
				next_state_s = WAIT_SLV_W;
			end
		end

		// Wait end of write data transfer
		WAIT_W : begin
			if (wvalid_i) begin
				next_state_s = WAIT_SLV_W;
			end
		end

		// Write response transfer
		B_TR : begin
			if (bready_i) begin
				next_state_s = IDLE;
			end
		end
        
        default : next_state_s = IDLE;
	endcase
end

// FSM output calculation
always @(*) begin
	//// Default output values
	// AXI interface
	aready_o   = 1'b1;
	rvalid_o   = 1'b0;
	awready_o  = 1'b1;
	wready_o   = 1'b1;
	bvalid_o   = 1'b0;

	// HS interface
	hs_read_o  = 1'b0;
	hs_write_o = 1'b0;

	// Registers enable
	wdata_reg_en_s  = 1'b1;
	araddr_reg_en_s = 1'b1;
	awaddr_reg_en_s = 1'b1;
	rdata_reg_en_s  = 1'b0;

	case(current_state_r)
		// Idle: wait for new request from hs interface
  		IDLE : begin
		end

		// Wait until slave provvides data
		WAIT_SLV_R : begin
			aready_o  = 1'b0;
			awready_o = 1'b0;
			wready_o  = 1'b0;

			hs_read_o = 1'b1;

			wdata_reg_en_s  = 1'b0;
			araddr_reg_en_s = 1'b0;
			awaddr_reg_en_s = 1'b0;
			rdata_reg_en_s  = 1'b1;
		end

		// Read data transfer
		R_TR : begin
			aready_o  = 1'b0;
			awready_o = 1'b0;
			wready_o  = 1'b0;
			rvalid_o  = 1'b1;
		end

		// Wait until slave writes data
		WAIT_SLV_W : begin
			aready_o  = 1'b0;
			awready_o = 1'b0;
			wready_o  = 1'b0;

			hs_write_o = 1'b1;

			wdata_reg_en_s  = 1'b0;
			araddr_reg_en_s = 1'b0;
			awaddr_reg_en_s = 1'b0;
		end

		// Wait end of write address transfer
		WAIT_AW : begin
			aready_o  = 1'b0;
			wready_o  = 1'b0;

			wdata_reg_en_s  = 1'b0;
		end
		
		// Wait end of write data transfer
		WAIT_W : begin
			aready_o   = 1'b0;
			awready_o  = 1'b0;

			awaddr_reg_en_s  = 1'b0;
		end

		// Write response transfer
		B_TR : begin
			aready_o  = 1'b0;
			awready_o = 1'b0;
			wready_o  = 1'b0;
			bvalid_o  = 1'b1;
		end
        
        default : begin
		end
	endcase
end

// Registers to store data from axi interface
always @(posedge clk_i) begin
	if(rst_i == 1'd0) begin
		wdata_r  <= 32'd0;
		wstrb_r  <= 4'd0;
		araddr_r <= 32'd0;
		awaddr_r <= 32'd0;
	end else begin
		if (wdata_reg_en_s == 1'b1) begin
			wdata_r <= wdata_i;
			wstrb_r <= wstrb_i;
		end

		if (araddr_reg_en_s == 1'b1) begin
			araddr_r <= araddr_i;
		end 
		
		if (awaddr_reg_en_s == 1'b1) begin
			awaddr_r <= awaddr_i;
		end
	end
end

// Register to store data from HS interface
always @(posedge clk_i) begin
	if(rst_i == 1'd0) begin
		rdata_r <= 'd0;
	end else begin
		if (rdata_reg_en_s == 1'b1) begin
			rdata_r <= hs_data_i;
		end
	end
end

//// Assign output values
assign rdata_o = rdata_r;
assign rresp_o = 2'd0;
assign bresp_o = 2'b0;
assign hs_data_o = wdata_r;
assign hs_addr_o = (hs_read_o) ? araddr_r : awaddr_r;
assign byte_select_o = wstrb_r;

endmodule
