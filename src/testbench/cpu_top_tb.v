`timescale  1ns/1ps

module cpu_top_tb ();

parameter CLOCK = 10;
reg clk_i_s, rst_i_s;

cpu_top DUT(
	.clk_i(clk_i_s),
    .rst_i(rst_i_s)
);

//Generation of the clock signal
always begin
	#(CLOCK/2)
	// Toggling clock
	clk_i_s = ~clk_i_s;
end

initial begin
	// Setting reset and initial clock value
	rst_i_s <= 1'b0;
	clk_i_s <= 1'b0;

	#(CLOCK*5)
	// Releasing reset
	rst_i_s <= 1'b1;
end

endmodule
