module register_file (
    input clk_i,
    input rst_ni,
    input stall_i,

    // Write port
    input        reg_write_i,
    input [4:0]  write_addr_i,
    input [31:0] data_i,
    
    // Read port 1
    input [4:0]   rs1_addr_i, 
	output [31:0] rs1_data_o, 
    
    // Read port 2
    input [4:0]   rs2_addr_i,
    output [31:0] rs2_data_o
);

reg [31:0] registers [0:31];
integer i;

//Output for RS1 value (with bypassing for same address write/read)
assign  rs1_data_o = (rs1_addr_i == write_addr_i && reg_write_i==1'b1 && write_addr_i !=5'd0) ? data_i : registers[rs1_addr_i];

//Output for RS2 value (with bypassing for same address write/read)
assign  rs2_data_o = (rs2_addr_i == write_addr_i && reg_write_i==1'b1 && write_addr_i !=5'd0) ? data_i : registers[rs2_addr_i];

always @(posedge clk_i) begin
    if (rst_ni == 0) begin
        //Reset of all the registers
        for (i=0; i<32; i=i+1) begin
            registers[i] <= 32'd0;
        end
    end else if (!stall_i) begin
        //Writing in the registers (register 0 is read only)
        if (reg_write_i == 1 && write_addr_i != 5'd0) begin
            registers[write_addr_i] <= data_i;
        end
    end
end

endmodule 
