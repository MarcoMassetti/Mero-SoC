module ram_wrapper(	
		input clk_i,
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

always @(posedge clk_i) begin
	// Sample read signal to detect edge
	read_r <= read_i;


	addr_r <= addr_i;

end

assign mem_ready_o = ((read_i == 1'b1 && read_r == 1'b0) || ((read_i) && addr_r != addr_i)) ? 1'b0 : 1'b1;

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


