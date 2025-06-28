module mmu(	
	input  clk_i,
	input  rst_i,

	// CPU stall signal
	output reg mem_ready_o,

	//// Instruction memory IOs
	// Towards CPU
	input  cpu_instr_mem_rd_i,
	input  [31:0] cpu_instr_mem_addr_i,
	output [31:0] cpu_instr_mem_data_o,
	// Towards BUS
	input  bus_instr_mem_ready_i,
	output reg bus_instr_mem_rd_o,
	output reg bus_instr_mem_wr_o,
	output [31:0] bus_instr_mem_addr_o,
	input  [31:0] bus_instr_mem_data_i,
	output [31:0] bus_instr_mem_data_o,

	// Data memory IOs
	input cpu_data_mem_rd_i,
	input cpu_data_mem_wr_i,
	output reg bus_data_mem_rd_o,
	output reg bus_data_mem_wr_o,
	input  bus_data_mem_ready_i
);

reg instr_reg_en_s, data_reg_en_s;
reg [31:0] instr_r, data_r;

// Signals and encoding for FSM status
reg [2:0] current_state_r, next_state_s;
localparam IDLE       = 3'd0;
localparam WAIT_BOTH  = 3'd1;
localparam WAIT_DATA  = 3'd2;
localparam WAIT_INSTR = 3'd3;
localparam HS_ACK     = 3'd4;


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
		// Wait for data memory access
		IDLE : begin
			if (cpu_data_mem_rd_i || cpu_data_mem_wr_i) begin
				if (bus_instr_mem_ready_i && bus_data_mem_ready_i) begin
					// If memories are immediatly ready stay in idle
					//  and just forward CPU request
					next_state_s = IDLE;
				end else if (!bus_instr_mem_ready_i && !bus_data_mem_ready_i) begin
					// If memories are not ready, must wait for both
					next_state_s = WAIT_BOTH;
				end else if (!bus_instr_mem_ready_i) begin
					// If only instruction memory is not ready, wait for it
					next_state_s = WAIT_INSTR;
				end else if (!bus_data_mem_ready_i) begin
					// If only data memory is not ready, wait for it
					next_state_s = WAIT_DATA;
				end
			end
		end
		
		// Wait for both memory transactions to finish
  		WAIT_BOTH : begin
			if (bus_instr_mem_ready_i && bus_data_mem_ready_i) begin
				// If both memories are ready return to idle
				next_state_s = HS_ACK;
			end else if (bus_instr_mem_ready_i) begin
				// If only instruction memory is ready, wait for data memory
				next_state_s = WAIT_DATA;
			end else if (bus_data_mem_ready_i) begin
				// If only data memory is ready, wait for instruction memory
				next_state_s = WAIT_INSTR;
			end
		end

		// Wait for data memory transaction to finish
		WAIT_DATA : begin
			if (bus_data_mem_ready_i) begin
				next_state_s = HS_ACK;
			end
		end

		// Wait for instruction memory transaction to finish
		WAIT_INSTR : begin
			if (bus_instr_mem_ready_i) begin
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
	bus_instr_mem_rd_o = cpu_instr_mem_rd_i;
	bus_data_mem_rd_o = cpu_data_mem_rd_i;
	bus_data_mem_wr_o = cpu_data_mem_wr_i;
	instr_reg_en_s = 1'b0;
	data_reg_en_s = 1'b0;

	case(current_state_r)
		// Wait for data memory access
  		IDLE : begin
		end

		// Wait for both memory transactions to finish
  		WAIT_BOTH : begin
			instr_reg_en_s = 1'b1;
			data_reg_en_s = 1'b1;
		end

		// Wait for data memory transaction to finish
		WAIT_DATA : begin
			bus_instr_mem_rd_o = 1'b0;
			data_reg_en_s = 1'b1;
		end

		// Wait for instruction memory transaction to finish
		WAIT_INSTR : begin
			bus_data_mem_rd_o = 1'b0;
			bus_data_mem_wr_o = 1'b0;
			instr_reg_en_s = 1'b1;
		end

		// Send acknowledge to hs interface
		HS_ACK : begin
			bus_data_mem_rd_o = 1'b0;
			bus_data_mem_wr_o = 1'b0;
			bus_instr_mem_rd_o = 1'b0;
		end
        
        default : begin
		end
	endcase
end

always @(*) begin
	if (next_state_s==IDLE && current_state_r==IDLE) begin
		mem_ready_o = bus_instr_mem_ready_i;
	end else if (current_state_r==HS_ACK) begin
		mem_ready_o = 1'b1;
	end else begin
		mem_ready_o = 1'b0;
	end
end

always @(posedge clk_i) begin
	if (rst_i==1'b0) begin
		instr_r <= 32'd0;
		data_r <= 32'd0;
	end else begin
		if (instr_reg_en_s) begin
			instr_r <= bus_instr_mem_data_i;
		end
	end
end

assign bus_instr_mem_wr_o = 1'b0;
assign bus_instr_mem_data_o = 32'd0;
assign bus_instr_mem_addr_o = cpu_instr_mem_addr_i;
assign cpu_instr_mem_data_o = (current_state_r!=HS_ACK) ? bus_instr_mem_data_i : instr_r;


/*
wire bus_instr_mem_ready_s, bus_instr_mem_rd_s;

assign mem_ready_o = (next_state_s!=IDLE) ? 1'b0 : bus_instr_mem_ready_s;
assign bus_instr_mem_rd_s = (current_state_r!=WAIT_DATA && next_state_s!=WAIT_DATA) ? cpu_instr_mem_rd_i : 1'b0;
assign bus_data_mem_rd_o  = (current_state_r!=WAIT_INSTR && next_state_s!=WAIT_INSTR) ? cpu_data_mem_rd_i : 1'b0;
assign bus_data_mem_wr_o  = (current_state_r!=WAIT_INSTR && next_state_s!=WAIT_INSTR) ? cpu_data_mem_wr_i : 1'b0;

//// SECTION FOR SPI MEMORY BOOT
spi_boot_ctrl inst_spi_boot_ctrl (
	.clk_i(clk_i),
	.rst_i(rst_i),

	// Handshake interface from CPU
	.cpu_hs_read_i(bus_instr_mem_rd_s),
	.cpu_hs_addr_i(cpu_instr_mem_addr_i),
	.cpu_hs_ready_o(bus_instr_mem_ready_s),
	.cpu_hs_data_o(cpu_instr_mem_data_o),
	
	// Handshake interface to interconnect
	.bus_hs_ready_i(bus_instr_mem_ready_i),
	.bus_hs_data_i(bus_instr_mem_data_i),
	.bus_hs_rd_o(bus_instr_mem_rd_o),
	.bus_hs_wr_o(bus_instr_mem_wr_o),
	.bus_hs_addr_o(bus_instr_mem_addr_o),
	.bus_hs_data_o(bus_instr_mem_data_o)
);
*/

endmodule
