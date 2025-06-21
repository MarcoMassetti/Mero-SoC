module mmu(	
	input  clk_i,
	input  rst_i,

	// CPU stall signal
	output mem_ready_o,

	// Instruction memory IOs
	input  cpu_instr_mem_rd_i,
	output bus_instr_mem_rd_o,
	input  bus_instr_mem_ready_i,

	// Data memory IOs
	input cpu_data_mem_rd_i,
	input cpu_data_mem_wr_i,
	output bus_data_mem_rd_o,
	output bus_data_mem_wr_o,
	input  bus_data_mem_ready_i
);

// Signals and encoding for FSM status
reg [1:0] current_state_r, next_state_s;
localparam IDLE       = 2'd0;
localparam WAIT_BOTH  = 2'd1;
localparam WAIT_DATA  = 2'd2;
localparam WAIT_INSTR = 2'd3;


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
				next_state_s = IDLE;
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
				next_state_s = IDLE;
			end
		end

		// Wait for instruction memory transaction to finish
		WAIT_INSTR : begin
			if (bus_instr_mem_ready_i) begin
				next_state_s = IDLE;
			end
		end
        
        default : next_state_s = IDLE;
	endcase
end

// FSM output calculation
always @(*) begin
	// Default output values
	case(current_state_r)
		// Wait for data memory access
  		IDLE : begin
		end

		// Wait for both memory transactions to finish
  		WAIT_BOTH : begin
		end

		// Wait for data memory transaction to finish
		WAIT_DATA : begin
		end

		// Wait for instruction memory transaction to finish
		WAIT_INSTR : begin
		end
        
        default : begin
		end
	endcase
end

assign mem_ready_o = (next_state_s!=IDLE) ? 1'b0 : bus_instr_mem_ready_i;
assign bus_instr_mem_rd_o = (current_state_r!=WAIT_DATA && next_state_s!=WAIT_DATA) ? cpu_instr_mem_rd_i : 1'b0;
assign bus_data_mem_rd_o  = (current_state_r!=WAIT_INSTR && next_state_s!=WAIT_INSTR) ? cpu_data_mem_rd_i : 1'b0;
assign bus_data_mem_wr_o  = (current_state_r!=WAIT_INSTR && next_state_s!=WAIT_INSTR) ? cpu_data_mem_wr_i : 1'b0;

endmodule
