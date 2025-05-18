module ram_wrapper(	
		input clk_i,
		input rst_i,
		input read_i,
		input write_i,
		input [14:0] addr_i,
		input [31:0] data_i,
		input [3:0] byte_select_i,
		
		output mem_ready_o,
		output [31:0] data_o
);

reg read_r;
reg [14:0] addr_r;
reg [31:0] data_r;

wire mem_ready_s;
reg mem_ready_r;

always @(posedge clk_i) begin
	// Sample read signal to detect edge
	read_r <= read_i;
	addr_r <= addr_i;
	data_r <= data_i;

	if(rst_i == 1'd0) begin
		mem_ready_r <= 1'b1;
	end else begin
		if(mem_ready_s == 1'b0) begin
			mem_ready_r <= 1'b0;	
		end else begin
			mem_ready_r <= 1'b1;
		end
	end

end

assign mem_ready_s = ((read_i == 1'b1 && read_r == 1'b0) ||
					  ((read_i) && addr_r != addr_i) ||
					  ((write_i) && addr_r != addr_i) ||
					  ((write_i) && data_r != data_i) ) ? 1'b0 : 1'b1;

assign mem_ready_o = mem_ready_s && mem_ready_r;

// SRAM Macro
ram inst_ram (
							.clk0(clk_i), 
							.csb0(~(read_i | write_i)), 
							.web0(~write_i), 
							.addr0(addr_i), 
							.din0(data_i), 
							.dout0(data_o),
							.wmask0(byte_select_i));
							
endmodule


