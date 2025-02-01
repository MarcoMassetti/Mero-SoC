module alu_control_unit (
    input [3:0] alu_op_i,
    input [2:0] funct_3_i,
    input [6:0] funct_7_i,

    output reg [3:0] alu_ctrl_o
);

always @(*) begin

    alu_ctrl_o = 4'd0;

    case(alu_op_i)
        // add, sub, xor
        4'b0000 : begin
            case(funct_3_i)
                // add, sub
                3'b000 : begin
                    case(funct_7_i)
                        // add
                        7'b0000000 : alu_ctrl_o = 4'b0000;
                        // sub
                        7'b0100000 : alu_ctrl_o = 4'b0011;
                    endcase
                end
                // xor
                3'b100 : alu_ctrl_o = 4'b0100; 
            endcase
        end

        // lui
        4'b0001 : alu_ctrl_o = 4'b0110;

        // ble, bne
        4'b0010 : begin
            case (funct_3_i)
                // ble
                3'b101 : alu_ctrl_o = 4'b0111;
                // bne
                3'b001 : alu_ctrl_o = 4'b1000;
            endcase
        end

        // jal, j, ret
        4'b0011 : alu_ctrl_o = 4'b0101;

        // auipc
        4'b0100 : alu_ctrl_o = 4'b0000;

        // addi, li, mv, slli, srai
        4'b0101 : begin 
            case(funct_3_i)
                // addi, li, mv
                3'b000 : alu_ctrl_o = 4'b0000; 
                // slli
                3'b001 : alu_ctrl_o = 4'b0001; 
                // srai
                3'b101 : alu_ctrl_o = 4'b0010; 
            endcase
        end

        // lw, sw
        4'b0110 : alu_ctrl_o = 4'b0000;
    endcase
end

endmodule
