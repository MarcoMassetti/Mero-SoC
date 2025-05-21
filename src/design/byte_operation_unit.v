module byte_operation_unit (
    input [2:0] funct_3_i,
	input [1:0] addr_i,
	input mem_read_i,
	input mem_write_i,
	input [31:0] data_to_mem_i,
	input [31:0] data_from_mem_i,
    
    output reg [31:0] data_to_mem_o,
	output reg [31:0] data_from_mem_o,
	output reg [3:0] byte_select_o
);

reg [7:0] tmp_byte;
reg [15:0] tmp_hw;

// Store operations (sb, sh, sw)
always @(*) begin

    byte_select_o = 4'b1111;
	data_to_mem_o = data_to_mem_i;

	if (mem_write_i == 1'b1) begin
		case(funct_3_i)
			// sb
			3'b000 : begin
				case(addr_i)
					2'b00 : byte_select_o = 4'b0001;
					2'b01 : byte_select_o = 4'b0010;
					2'b10 : byte_select_o = 4'b0100;
					2'b11 : byte_select_o = 4'b1000;
					default : begin
					end
				endcase

				data_to_mem_o = {4{data_to_mem_i[7:0]}};
			end

			// sh
			3'b001 : begin
				case(addr_i)
					2'b00 : byte_select_o = 4'b0011;
					2'b10 : byte_select_o = 4'b1100;
					default : begin
					end
				endcase

				data_to_mem_o = {2{data_to_mem_i[15:0]}};
			end

			// sw
			3'b010 : begin
				byte_select_o = 4'b1111;
				if (addr_i != 2'b00) begin
            		//$error("Misaligned write");
				end
			end

			default : begin
			end
		endcase
	end 
end

// Load operations (lb, lh, lw, lbu, lhu)
always @(*) begin

	data_from_mem_o = 32'd0;
	tmp_byte = 8'd0;
	tmp_hw = 16'd0;

	if (mem_read_i == 1'b1) begin
		// lb, lh, lw, lbu, lhu
		case(funct_3_i)
			// lb
			3'b000 : begin
				case(addr_i)
					2'b00 : tmp_byte = data_from_mem_i[7:0];
					2'b01 : tmp_byte = data_from_mem_i[15:8];
					2'b10 : tmp_byte = data_from_mem_i[23:16];
					2'b11 : tmp_byte = data_from_mem_i[31:24];
					default : begin
					end
				endcase
				data_from_mem_o = {{24{tmp_byte[7]}}, tmp_byte};
			end

			// lh
			3'b001 : begin
				case(addr_i)
					2'b00 : tmp_hw = data_from_mem_i[15:0];
					2'b10 : tmp_hw = data_from_mem_i[31:16];
					default : begin
					end
				endcase
				data_from_mem_o = {{16{tmp_hw[15]}}, tmp_hw};
			end

			// lw
			3'b010 : begin
				data_from_mem_o = data_from_mem_i;
				if (addr_i != 2'b00) begin
            		//$error("Misaligned load");
				end
			end

			// lbu
			3'b100 : begin
				case(addr_i)
					2'b00 : tmp_byte = data_from_mem_i[7:0];
					2'b01 : tmp_byte = data_from_mem_i[15:8];
					2'b10 : tmp_byte = data_from_mem_i[23:16];
					2'b11 : tmp_byte = data_from_mem_i[31:24];
					default : begin
					end
				endcase
				data_from_mem_o = {24'd0, tmp_byte};
			end

			// lhu
			3'b101 : begin
				case(addr_i)
					2'b00 : tmp_hw = data_from_mem_i[15:0];
					2'b10 : tmp_hw = data_from_mem_i[31:16];
					default : begin
					end
				endcase
				data_from_mem_o = {16'd0, tmp_hw};
			end

			default : begin
			end
		endcase
	end 
end

endmodule
