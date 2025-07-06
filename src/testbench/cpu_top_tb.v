`timescale  1ns/1ps

module cpu_top_tb ();

parameter CLOCK = 50;
reg clk_i_s, rst_i_s;

`ifdef DDR
wire        ddr3_reset_n;
wire [15:0] ddr3_dq_fpga;
wire [1:0]  ddr3_dqs_p_fpga;
wire [1:0]  ddr3_dqs_n_fpga;
wire [13:0] ddr3_addr_fpga;
wire [2:0]  ddr3_ba_fpga;
wire        ddr3_ras_n_fpga;
wire        ddr3_cas_n_fpga;
wire        ddr3_we_n_fpga;
wire        ddr3_cke_fpga;
wire        ddr3_ck_p_fpga;
wire        ddr3_ck_n_fpga;
wire        ddr3_cs_n_fpga;
wire [1:0]  ddr3_dm_fpga;
wire        ddr3_odt_fpga;
`endif

wire spi_cs_ns, spi_mosi_s, spi_miso_s, wp_ns, hold_ns, spi_sck_s;
wire uart_loop;
localparam BOOT_SOURCE = 2'b1;
cpu_top DUT(
	.clk_i(clk_i_s),
    .rst_i(rst_i_s),
    // Boot source strapping pins
	// 0:SPI, 1:SRAM, 2:DDR
	.boot_source_i(BOOT_SOURCE),
	// UART
    .tx_o(uart_loop),
    .rx_i(uart_loop),
	// SPI
    .spi_sck_o(spi_sck_s),
	.spi_cs_no(spi_cs_ns),
	.spi_mosi_o(spi_mosi_s),
	.spi_miso_i(spi_miso_s),
	.wp_no(wp_ns),
	.hold_no(hold_ns)
`ifdef DDR
    ,
	// DDR
	.ddr3_addr(ddr3_addr_fpga),
    .ddr3_ba(ddr3_ba_fpga),
    .ddr3_cas_n(ddr3_cas_n_fpga),
    .ddr3_ck_n(ddr3_ck_n_fpga),
    .ddr3_ck_p(ddr3_ck_p_fpga),
    .ddr3_cke(ddr3_cke_fpga),
    .ddr3_ras_n(ddr3_ras_n_fpga),
    .ddr3_reset_n(ddr3_reset_n),
    .ddr3_we_n(ddr3_we_n_fpga),
    .ddr3_dq(ddr3_dq_fpga),
    .ddr3_dqs_n(ddr3_dqs_n_fpga),
    .ddr3_dqs_p(ddr3_dqs_p_fpga),     
	.ddr3_cs_n(ddr3_cs_n_fpga),
    .ddr3_dm(ddr3_dm_fpga),
    .ddr3_odt(ddr3_odt_fpga),
	.init_calib_complete_o()
`endif
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


`ifndef FPGA
// SPI EEPROM Model
parameter FILE_NAME = "software_8.txt";
initial #1 $readmemb(FILE_NAME, cpu_top_tb.inst_sst25vf016B.memory);
sst25vf016B inst_sst25vf016B (
    .WPn(wp_ns),
    .SO(spi_miso_s),
    .HOLDn(hold_ns),
    .SCK(spi_sck_s),
    .CEn(spi_cs_ns),
    .SI(spi_mosi_s)
);
`endif

`ifdef DDR
// DDR Model
ddr3_model u_comp_ddr3
            (
             .rst_n   (ddr3_reset_n),
             .ck      (ddr3_ck_p_fpga),
             .ck_n    (ddr3_ck_n_fpga),
             .cke     (ddr3_cke_fpga),
             .cs_n    (ddr3_cs_n_fpga),
             .ras_n   (ddr3_ras_n_fpga),
             .cas_n   (ddr3_cas_n_fpga),
             .we_n    (ddr3_we_n_fpga),
             .dm_tdqs (ddr3_dm_fpga),
             .ba      (ddr3_ba_fpga),
             .addr    (ddr3_addr_fpga),
             .dq      (ddr3_dq_fpga),
             .dqs     (ddr3_dqs_p_fpga),
             .dqs_n   (ddr3_dqs_n_fpga),
             .tdqs_n  (),
             .odt     (ddr3_odt_fpga)
             );
`endif

endmodule
