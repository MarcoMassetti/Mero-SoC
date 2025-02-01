module control_unit (
    input [6:0] op_i,
    
    output reg [3:0] alu_op_o,
    output reg [2:0] imm_select_o,
    output reg alu_src_o, alu_pc_o, add_sum_reg_o, reg_write_o,
    output reg mem_rd_o, mem_wr_o, mem_to_reg_o, branch_o
);

always @(*) begin

    alu_op_o      = 4'b0000;
    alu_src_o     = 1'b0;
    alu_pc_o      = 1'b0;
    add_sum_reg_o = 1'b0;
    reg_write_o   = 1'b0;
    mem_rd_o      = 1'b0;
    mem_wr_o      = 1'b0;
    mem_to_reg_o  = 1'b0;
    branch_o      = 1'b0;
    imm_select_o  = 3'b000;

    case (op_i)
        // nop
        7'b0000000 : begin
        end

        // addi, li, mv, slli, srai
        7'b0010011 : begin
            alu_op_o    = 4'b0101;
            alu_src_o   = 1'b1;
            reg_write_o = 1'b1;
        end

        // add, xor, sub
        7'b0110011 : begin
            reg_write_o = 1'b1;
        end

        // lui
        7'b0110111 : begin
            alu_op_o     = 4'b0001;
            alu_src_o    = 1'b1;
            reg_write_o  = 1'b1;
            imm_select_o = 3'b011; 	// "U" immediate format
        end

        // sw
        7'b0100011 : begin
            alu_op_o     = 4'b0110;
            alu_src_o    = 1'b1;
            mem_wr_o     = 1'b1;
            imm_select_o = 3'b001; 	// "S" immediate format
        end

        // lw
        7'b0000011 : begin
            alu_op_o     = 4'b0110;
            alu_src_o    = 1'b1;
            reg_write_o  = 1'b1;
            mem_rd_o     = 1'b1;
            mem_to_reg_o = 1'b1;
        end

        // ble, bne
        7'b1100011 : begin
            alu_op_o     = 4'b0010;
            branch_o     = 1'b1;
            imm_select_o = 3'b010; 	// "SB" immediate format 
        end

        // auipc
        7'b0010111 : begin
            alu_op_o     = 4'b0100;
            alu_src_o    = 1'b1;
            alu_pc_o     = 1'b1;
            reg_write_o  = 1'b1;
            imm_select_o = 3'b011; 	// "U" immediate format
        end

        // jal, j
        7'b1101111 : begin
            alu_op_o     = 4'b0011;
            alu_pc_o     = 1'b1;
            reg_write_o  = 1'b1;
            branch_o     = 1'b1;
            imm_select_o = 3'b100; 	// "UJ" immediate format
        end

        // jalr, ret
        7'b1100111 : begin
            alu_op_o      = 4'b0011;
            alu_pc_o      = 1'b1;
            add_sum_reg_o = 1'b1;
            branch_o      = 1'b1;
        end
    endcase
end

endmodule
