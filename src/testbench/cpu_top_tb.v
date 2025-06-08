`timescale  1ns/1ps

module cpu_top_tb ();

parameter CLOCK = 10;
reg clk_i_s, rst_i_s;

cpu_top DUT(
	.clk_i(clk_i_s),
    .rst_i(rst_i_s),
    .led_o(),
	// UART
    .tx_o(),
    .rx_i(1'b1),
	// SPI
	.spi_cs_no(),
	.spi_mosi_o(),
	.spi_miso_i(1'b1),
	.wp_no(),
	.hold_no()

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
