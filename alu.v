module alu (
	input signed [31:0] op1_i,
    input signed [31:0] op2_i, 
	input [3:0] alu_ctrl_i, 
	
	output reg [31:0] data_o,
	output reg Zero_o
);

always @(*) begin
    data_o = 32'd0;
    Zero_o = 1'b0;

	case(alu_ctrl_i)
        // addi, li, mv, add, lw, sw
		4'b0000 : data_o = op1_i + op2_i;
					  
        // slli
		4'b0001 : data_o = op1_i << op2_i[4:0];

        // srai	
        4'b0010 : data_o = op1_i >>> op2_i[4:0];

        // sub 
		4'b0011 : data_o = op1_i - op2_i;

        // xor 
		4'b0100 : data_o = op1_i ^ op2_i;

        // jal, j, ret
        4'b0101 : begin 
            data_o = op1_i + 32'd4;
            Zero_o = 1'b1;
		end

        // lui
		4'b0110 : data_o = op2_i;

        // ble
		4'b0111 : begin	
			if (op2_i <= op1_i) begin
				Zero_o = 1'b1;
			end
		end
		
        // bne
		4'b1000 : begin
			if (op1_i != op2_i) begin
				Zero_o = 1'b1;
			end
		end
	endcase
end

endmodule


