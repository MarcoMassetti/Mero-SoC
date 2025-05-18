module memory_arbiter (
	input  clk_i,
	input  rst_i,

	// Instruction memory IOs
	input  instr_mem_rd_i,
	input  [31:0] instr_mem_addr_i,
	output reg instr_mem_ready_o,
	output [31:0] instr_mem_data_o,

	// Data memory IOs
	input data_mem_rd_i,
	input data_mem_wr_i,
	input [31:0] data_mem_addr_i,
	input [31:0] data_mem_data_i,
	output reg data_mem_ready_o,
	output [31:0] data_mem_data_o,

	// Common memory IOs
	input  merged_mem_ready_i,
	input  [31:0] merged_mem_data_i,
	output reg merged_mem_rd_o,
	output reg merged_mem_wr_o,
	output reg [31:0] merged_mem_addr_o,
	output reg [31:0] merged_mem_data_o
);

// Registers to store incoming data from memory
reg instr_reg_en_s, data_reg_en_s;
reg [31:0] sampled_instr_r, sampled_data_r;

// Registers to manage ready signals
reg instr_mem_rd_r, data_mem_rd_r, data_mem_wr_r;
reg [31:0] instr_mem_addr_r, data_mem_addr_r;
reg instr_mem_ready_r, instr_mem_ready_clr_r, data_mem_ready_r, data_mem_ready_clr_r;

assign instr_mem_data_o  = sampled_instr_r;
assign data_mem_data_o   = sampled_data_r;



// Merge requests from the processor into a single memory request
always @(*) begin

	// Devault output values
	merged_mem_rd_o   = 1'b0;
	merged_mem_wr_o   = 1'b0;
	merged_mem_addr_o = 32'd0;
	merged_mem_data_o = 32'd0;
	instr_reg_en_s    = 1'b0;
	data_reg_en_s     = 1'b0;

	// Serve first request to data memory
	if ((data_mem_rd_i == 1'b1 || data_mem_wr_i == 1'b1) && data_mem_ready_o == 1'b0) begin
		// Request data from memory
		merged_mem_rd_o   = data_mem_rd_i;
		merged_mem_wr_o   = data_mem_wr_i;
		merged_mem_addr_o = data_mem_addr_i;
		merged_mem_data_o = data_mem_data_i;
		// Sample incoming data from memory into data register (when data is ready)
		data_reg_en_s = merged_mem_ready_i;
	end else if (instr_mem_rd_i == 1'b1 && instr_mem_ready_o == 1'b0) begin
		// Request data from memory
		merged_mem_rd_o   = instr_mem_rd_i;
		merged_mem_addr_o = instr_mem_addr_i;
		// Sample incoming data from memory into instruction register (when data is ready)
		instr_reg_en_s = merged_mem_ready_i;
	end
end

// Registers to store incoming data from memory
always @(posedge clk_i) begin
	if(rst_i == 1'd0) begin
		sampled_instr_r <= 32'd0;
		sampled_data_r  <= 32'd0;
	end else begin
		if (instr_reg_en_s == 1'b1) begin
			sampled_instr_r <= merged_mem_data_i;
		end
		
		if (data_reg_en_s == 1'b1) begin
			sampled_data_r <= merged_mem_data_i;
		end
	end
end

// Registers to manage ready signals
always @(posedge clk_i) begin
	if (rst_i == 1'd0) begin
		instr_mem_rd_r   <= 1'b0;
		data_mem_rd_r    <= 1'b0;
		data_mem_wr_r    <= 1'b0;
		instr_mem_addr_r <= 32'd0;
		data_mem_addr_r  <= 32'd0;

		instr_mem_ready_r <= 1'b1;
		data_mem_ready_r  <= 1'b1;
	end else begin

		// Sample read signal to detect edge
		instr_mem_rd_r <= instr_mem_rd_i;
		data_mem_rd_r  <= data_mem_rd_i;
		data_mem_wr_r  <= data_mem_wr_i;

		// Rample addresses to differentiate between consecutive accesses
		instr_mem_addr_r <= instr_mem_addr_i;
		data_mem_addr_r  <= data_mem_addr_i;

		if (instr_mem_ready_clr_r == 1'b1) begin
			instr_mem_ready_r <= 1'b0;
		end else if (instr_reg_en_s == 1'b1) begin
			instr_mem_ready_r <= 1'b1;
		end

		if (data_mem_ready_clr_r == 1'b1) begin
			data_mem_ready_r <= 1'b0;
		end else if (data_reg_en_s == 1'b1) begin
			data_mem_ready_r <= 1'b1;
		end
	end
end

always @(*) begin

	instr_mem_ready_clr_r = 1'b0;
	data_mem_ready_clr_r  = 1'b0;

	// If rising edge of access request or request to a different address compared to the last one
	if ((instr_mem_rd_i == 1'b1 && instr_mem_rd_r == 1'b0) || 
		((instr_mem_rd_i) && instr_mem_addr_r != instr_mem_addr_i)) begin
		// Do not send ready to cpu and clear ready register
		instr_mem_ready_o = 1'b0;
		instr_mem_ready_clr_r = 1'b1;
	end else begin
		instr_mem_ready_o = instr_mem_ready_r;
	end

	// If rising edge of access request or request to a different address compared to the last one
	if ((data_mem_rd_i == 1'b1 && data_mem_rd_r == 1'b0) || 
		(data_mem_wr_i == 1'b1 && data_mem_wr_r == 1'b0) ||
		((data_mem_rd_i || data_mem_wr_i) && data_mem_addr_r != data_mem_addr_i)) begin
		data_mem_ready_o = 1'b0;
		data_mem_ready_clr_r = 1'b1;
	end else begin
		data_mem_ready_o = data_mem_ready_r;
	end
end

endmodule