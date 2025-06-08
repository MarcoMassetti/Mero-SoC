module alu_control_unit (
    input [2:0] alu_op_i,
    input [2:0] funct_3_i,
    input [6:0] funct_7_i,

    output reg [4:0] alu_ctrl_o
);

always @(*) begin

    alu_ctrl_o = 5'd0;

    case(alu_op_i)
        // add, sub, xor, or, and, sll, srl, sra, slt, sltu
        3'b000 : begin
            case(funct_3_i)
                // add, sub
                3'b000 : begin
                    case(funct_7_i)
                        // add
                        7'b0000000 : alu_ctrl_o = 5'd0;
                        // sub
                        7'b0100000 : alu_ctrl_o = 5'd3;
                        default : begin
                        end
                    endcase
                end
                // xor
                3'b100 : alu_ctrl_o = 5'd4;
                // or
                3'b110 : alu_ctrl_o = 5'd9;
                // and
                3'b111 : alu_ctrl_o = 5'd10;
                // sll
                3'b001 : alu_ctrl_o = 5'd1;
                // srl, sra
                3'b101 : begin
                    case(funct_7_i)
                        // srl
                        7'b0000000 : alu_ctrl_o = 5'd11;
                        // sra
                        7'b0100000 : alu_ctrl_o = 5'd2;
                        default : begin
                        end
                    endcase
                end
                // slt
                3'b010 : alu_ctrl_o = 5'd12;
                // sltu
                3'b011 : alu_ctrl_o = 5'd13;
                default : begin
                end
            endcase
        end

        // addi, xori, ori, andi, slli, srli, srai, slti, sltiu
        3'b101 : begin 
            case(funct_3_i)
                // addi
                3'b000 : alu_ctrl_o = 5'd0; 
                // xori
                3'b100 : alu_ctrl_o = 5'd4;
                // ori
                3'b110 : alu_ctrl_o = 5'd9;
                // andi
                3'b111 : alu_ctrl_o = 5'd10;
                // slli
                3'b001 : alu_ctrl_o = 5'd1;
                // srli, srai
                3'b101 : begin
                    case(funct_7_i)
                        // srli
                        7'b0000000 : alu_ctrl_o = 5'd11;
                        // srai
                        7'b0100000 : alu_ctrl_o = 5'd2;
                        default : begin
                        end
                    endcase
                end
                // slti
                3'b010 : alu_ctrl_o = 5'd12;
                // sltiu
                3'b011 : alu_ctrl_o = 5'd13;
                default : begin
                end
            endcase
        end

        // lb, lh, lw, lbu, lhu, sb, sh, sw
        3'b110 : alu_ctrl_o = 5'd0;

        // beq, bne, blt, bge, bltu, bgeu
        3'b010 : begin
            case (funct_3_i)
                // beq
                3'b000 : alu_ctrl_o = 5'd14;
                // bne
                3'b001 : alu_ctrl_o = 5'd8;
                // blt
                3'b100 : alu_ctrl_o = 5'd15;
                // bge
                3'b101 : alu_ctrl_o = 5'd7;
                // bltu
                3'b110 : alu_ctrl_o = 5'd16;
                // bgeu
                3'b111 : alu_ctrl_o = 5'd17;
                default : begin
                end
            endcase
        end

        // jal, jalr
        3'b011 : alu_ctrl_o = 5'd5;

        // lui
        3'b001 : alu_ctrl_o = 5'd6;

        // auipc
        3'b100 : alu_ctrl_o = 5'd0;

        default : begin
        end
    endcase
end

endmodule
