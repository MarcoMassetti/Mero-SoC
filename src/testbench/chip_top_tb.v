`timescale  1ns/1ns

module chip_top_tb ();

localparam CLOCK = 10;
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
chip_top DUT(
	.clk_i(clk_i_s),
    .rst_ni(rst_i_s),
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


// Parsing simulation arguments
reg [0:1023] SRAM_FILE_NAME;
reg [31:0] SIM_TIMEOUT_NS;
reg VCD_ENABLE;
initial begin
    // Load software into memory
    if (!$value$plusargs("SRAM_FILE_NAME=%s", SRAM_FILE_NAME)) begin
        $error("SRAM_FILE_NAME argument is not specified");
        $finish;
    end else begin
	    $readmemb(SRAM_FILE_NAME, DUT.inst_ram_wrapper.inst_ram.mem);
    end

    // Save VCD file
    if ($value$plusargs("VCD_ENABLE=%d", VCD_ENABLE) && VCD_ENABLE == 1'b1) begin
        $dumpfile("dump.vcd");
        $dumpvars(0, chip_top_tb);
    end

    // Simulation timeout value (in nanoseconds)
    if (!$value$plusargs("SIM_TIMEOUT_NS=%d", SIM_TIMEOUT_NS) || SIM_TIMEOUT_NS==32'd0) begin
        // Default value (1 ms)
        SIM_TIMEOUT_NS = 1000000;
    end

end


integer file;
integer i;
initial begin
    // Wait until trap is asserted or until timeout
    //while (((DUT.inst_cpu.trap_o !== 1'b1) || ((DUT.inst_cpu.inst_register_file.registers[17] !== 32'ha) && (DUT.inst_cpu.inst_register_file.registers[17] !== 32'h5d))) 
    while (((DUT.inst_cpu.trap_o !== 1'b1) ) 
			&& ($time < SIM_TIMEOUT_NS)
		   ) begin
        #10; 
    end

    // Check cause of simulation stop
    if (DUT.inst_cpu.trap_o === 1'b1) begin
        $display("Trap asserted at time  %d ns", $time);

        // Print register file content
        file = $fopen("register_file_dut.txt", "w");
        if (file) begin
            $fdisplay(file, "===== register values");
            for (i = 0; i < 32; i=i+1) begin
                $fdisplay(file, "x%0d:\t%0d\t(0x%08x)", i, $signed(DUT.inst_cpu.inst_register_file.registers[i]), DUT.inst_cpu.inst_register_file.registers[i]);
            end
            $fdisplay(file, "");
            $fclose(file);
        end
        $finish;
    end else begin
        $warning("Simulation timed out at time %d ns", $time);
        $finish;
    end
end

endmodule
