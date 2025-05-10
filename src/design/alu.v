module alu (
	input signed [31:0] op1_i,
    input signed [31:0] op2_i, 
	input [4:0] alu_ctrl_i, 
	
	output reg [31:0] data_o,
	output reg Zero_o
);

always @(*) begin
    data_o = 32'd0;
    Zero_o = 1'b0;

	case(alu_ctrl_i)
        // addi, li, mv, add, lw, sw
		5'd0 : data_o = op1_i + op2_i;
					  
        // sll, slli
		5'd1 : data_o = op1_i << op2_i[4:0];

        // sra, srai	
        5'd2 : data_o = op1_i >>> op2_i[4:0];

        // sub 
		5'd3 : data_o = op1_i - op2_i;

        // xor 
		5'd4 : data_o = op1_i ^ op2_i;

        // jal, jalr
        5'd5 : begin 
            data_o = op1_i + 32'd4;
            Zero_o = 1'b1;
		end

        // lui
		5'd6 : data_o = op2_i;
	
		// bge
		5'd7 : Zero_o = (op1_i >= op2_i) ? 1'b1 : 1'b0;
		
        // bne
		5'd8 : Zero_o = (op1_i != op2_i) ? 1'b1 : 1'b0;

		// or
		5'd9 : data_o = op1_i | op2_i;

		// and
		5'd10 : data_o = op1_i & op2_i;

		// srl	
        5'd11 : data_o = op1_i >> op2_i[4:0];

		// slt	
        5'd12 : data_o = (op1_i<op2_i) ? 32'd1 : 32'd0;

		// sltu
        5'd13 : data_o = ($unsigned(op1_i)<$unsigned(op2_i)) ? 32'd1 : 32'd0;

		// beq
		5'd14 : Zero_o = (op1_i == op2_i) ? 1'b1 : 1'b0;

		// blt
		5'd15 : Zero_o = (op1_i < op2_i) ? 1'b1 : 1'b0;

		// bltu
		5'd16 : Zero_o = ($unsigned(op1_i) < $unsigned(op2_i)) ? 1'b1 : 1'b0;

		// bgeu
		5'd17 : Zero_o = ($unsigned(op1_i) >= $unsigned(op2_i)) ? 1'b1 : 1'b0;

		default : begin
        end
	endcase
end

endmodule


