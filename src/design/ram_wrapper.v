module ram_wrapper(	
		input clk_i,
		input rst_i,
		input read_i,
		input write_i,
		input [14:0] addr_i,
		input [31:0] data_i,
		input [3:0] byte_select_i,
		
		output reg mem_ready_o,
		output [31:0] data_o
);

reg mem_ready_r;

always @(posedge clk_i) begin
	if(rst_i == 1'd0) begin
		mem_ready_r <= 1'd0;
		mem_ready_o <= 1'd0;
	end else begin
		mem_ready_r <= (read_i || write_i);
		mem_ready_o <= mem_ready_r;
	end
end

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


