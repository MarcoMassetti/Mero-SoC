module cpu_interface_ctrl(	
	input  clk_i,
	input  rst_ni,

	// Boot source strapping pins
	// 0:SPI, 1:SRAM, 2:DDR
	input [1:0] boot_source_i,

	//// AXI interface
	// Read Address (AR) channel
	input  arvalid_i,
	output aready_o,
	input  [31:0] araddr_i,
	// Read Data (R) channel
	output rvalid_o,
	input  rready_i,
	output [31:0] rdata_o,
	output [1:0] rresp_o,
	// Write Address (AW) channel
	input  awvalid_i,
	output awready_o,
	input  [31:0] awaddr_i,
	// Write Data (W) channel
	input  wvalid_i,
	output wready_o,
	input  [31:0] wdata_i,
	input  [3:0] wstrb_i,
	// Write Response (B) channel
	output bvalid_o,
	input  bready_i,
	output [1:0] bresp_o,

	// CPU stall signal
	output reg mem_ready_o,

	//// Instruction memory IOs
	// Towards CPU
	input  cpu_instr_mem_rd_i,
	input  [31:0] cpu_instr_mem_addr_i,
	output [31:0] cpu_instr_mem_data_o,
	// Towards BUS
	input  bus_instr_mem_ready_i,
	output bus_instr_mem_rd_o,
	output bus_instr_mem_wr_o,
	output reg [31:0] bus_instr_mem_addr_o,
	input  [31:0] bus_instr_mem_data_i,
	output [31:0] bus_instr_mem_data_o,

	// Data memory IOs
	// Towards CPU
	input  cpu_data_mem_rd_i,
	input  cpu_data_mem_wr_i,
	input  [31:0] cpu_data_mem_addr_i,
	input  [31:0] cpu_data_mem_data_i,
	output [31:0] cpu_data_mem_data_o,
	input  [3:0] cpu_byte_select_i,
	// Towards BUS
	input  bus_data_mem_ready_i,
	output bus_data_mem_rd_o,
	output bus_data_mem_wr_o,
	output [31:0] bus_data_mem_addr_o,
	input  [31:0] bus_data_mem_data_i,
	output [31:0] bus_data_mem_data_o,
	output [3:0] bus_byte_select_o
);

// AXI to HS transation signals
wire hs_ready_s;
wire hs_read_s, hs_write_s;
wire [31:0] hs_addr_s, hs_data_i_s, hs_data_o_s;

axi_2_hs inst_axi_slave (
	.clk_i(clk_i),
	.rst_ni(rst_ni),
	//// AXI interface
	// Read Address (AR) channel
	.arvalid_i(arvalid_i),
	.aready_o(aready_o),
	.araddr_i(araddr_i),
	// Read Data (R) channel
	.rvalid_o(rvalid_o),
	.rready_i(rready_i),
	.rdata_o(rdata_o),
	.rresp_o(rresp_o),
	// Write Address (AW) channel
	.awvalid_i(awvalid_i),
	.awready_o(awready_o),
	.awaddr_i(awaddr_i),
	// Write Data (W) channel
	.wvalid_i(wvalid_i),
	.wready_o(wready_o),
	.wdata_i(wdata_i),
	.wstrb_i(wstrb_i),
	// Write Response (B) channel
	.bvalid_o(bvalid_o),
	.bready_i(bready_i),
	.bresp_o(bresp_o),
	// Handshake interface
	.hs_read_o(hs_read_s),
	.hs_write_o(hs_write_s),
	.hs_addr_o(hs_addr_s),
	.hs_data_o(hs_data_i_s),
	.hs_ready_i(hs_ready_s),
	.hs_data_i(hs_data_o_s),
	.byte_select_o()
);

/* ---------------------------------------------------
* Register Access Section
* --------------------------------------------------*/
// Status register signals
reg executing_from_copy_s, executing_from_copy_r;
// Control registers signals
wire [31:0] start_addr_s, stop_addr_s;
wire start_copy_s;
// 0:SRAM, 1:DDR
wire copy_destination_s;
// Signal to clear the start_copy bit from hardware
reg start_copy_clr_s;

//// Register access
// Reg_0 (0x00): Ctrl reg      (RW)
// Reg_1 (0x04): Status reg    (RO)
// Reg_2 (0x08): Start address (RW)
// Reg_3 (0x0C): Stop address  (RW)
reg [31:0] registers_r [0:3];
always @(posedge clk_i) begin
    if (rst_ni == 0) begin
        // Reset of the registers
        registers_r[0] <= 32'd0;
		registers_r[2] <= 32'd0;
		registers_r[3] <= 32'd0;
    end else begin
        // Writing in the registers
        if (hs_write_s == 1) begin
            registers_r[hs_addr_s[3:2]] <= hs_data_i_s;
        end
		// Clear of start_copy bit from hardware
		if (start_copy_clr_s) begin
			registers_r[0][0] <= 1'b0;
		end
    end
	// Register 1 is read-only (Status reg)
	registers_r[1] <= {29'd0, boot_source_i, executing_from_copy_r};
end
// Signals from ctrl register
assign start_copy_s       = registers_r[0][0];
assign copy_destination_s = registers_r[0][1];
assign start_addr_s       = registers_r[2];
assign stop_addr_s        = registers_r[3];
//Output for register access
assign hs_data_o_s = registers_r[hs_addr_s[3:2]];
// Latency of register access is 0
assign hs_ready_s = 1'b1;

/* ---------------------------------------------------
* Single word memory access FSM
* Manages simultaneus instruction and data memory accesses
* --------------------------------------------------*/
// Signals between stall_fsm, spi boot controller and bus
reg  stall_instr_mem_rd_s, stall_data_mem_rd_s, stall_data_mem_wr_s;
wire bus_instr_mem_ready_s;
wire [31:0] bus_instr_mem_data_s;
// Sample incoming data from bus
reg [1:0] instr_reg_en_s;
reg data_reg_en_s;
reg [31:0] instr_r, data_r;
always @(posedge clk_i) begin
	if (rst_ni==1'b0) begin
		instr_r <= 32'd0;
		data_r  <= 32'd0;
	end else begin
		// Sample instruction interface input
		if (instr_reg_en_s[0] || instr_reg_en_s[1]) begin
			instr_r <= bus_instr_mem_data_s;
		end
		// Sample data interface input
		if (data_reg_en_s) begin
			data_r <= bus_data_mem_data_i;
		end
	end
end

// Signals and encoding for FSM status
reg [2:0] stall_current_state_r, stall_next_state_s;
localparam IDLE       = 3'd0;
localparam WAIT_BOTH  = 3'd1;
localparam WAIT_DATA  = 3'd2;
localparam WAIT_INSTR = 3'd3;
localparam HS_ACK     = 3'd4;
// Signal indicating if the copy_fsm is not in idle
wire copy_started_s;

// FSM present state update
always @(posedge clk_i) begin
	if(rst_ni == 1'd0) begin
		stall_current_state_r <= 'b0;
	end else begin
		stall_current_state_r <= stall_next_state_s;
	end
end

// FSM next state calculation
always @(*) begin
	// Default next state
	stall_next_state_s = stall_current_state_r;

 	case(stall_current_state_r)
		// Wait for data memory access
		IDLE : begin
			// Regulate access only when both an operation towards intruction and data interfaces are started
			//   If a code copy is running don't do anything
			if ((cpu_data_mem_rd_i || cpu_data_mem_wr_i) && !copy_started_s) begin
				if (bus_instr_mem_ready_s && bus_data_mem_ready_i) begin
					// If memories are immediatly ready stay in idle
					//  and just forward CPU request
					stall_next_state_s = IDLE;
				end else if (!bus_instr_mem_ready_s && !bus_data_mem_ready_i) begin
					// If memories are not ready, must wait for both
					stall_next_state_s = WAIT_BOTH;
				end else if (!bus_instr_mem_ready_s) begin
					// If only instruction memory is not ready, wait for it
					stall_next_state_s = WAIT_INSTR;
				end else if (!bus_data_mem_ready_i) begin
					// If only data memory is not ready, wait for it
					stall_next_state_s = WAIT_DATA;
				end
			end
		end
		
		// Wait for both memory transactions to finish
  		WAIT_BOTH : begin
			if (bus_instr_mem_ready_s && bus_data_mem_ready_i) begin
				// If both memories are ready return to idle
				stall_next_state_s = HS_ACK;
			end else if (bus_instr_mem_ready_s) begin
				// If only instruction memory is ready, wait for data memory
				stall_next_state_s = WAIT_DATA;
			end else if (bus_data_mem_ready_i) begin
				// If only data memory is ready, wait for instruction memory
				stall_next_state_s = WAIT_INSTR;
			end
		end

		// Wait for data memory transaction to finish
		WAIT_DATA : begin
			if (bus_data_mem_ready_i) begin
				stall_next_state_s = HS_ACK;
			end
		end

		// Wait for instruction memory transaction to finish
		WAIT_INSTR : begin
			if (bus_instr_mem_ready_s) begin
				stall_next_state_s = HS_ACK;
			end
		end

		// Send acknowledge to hs interface
		HS_ACK : begin
			stall_next_state_s = IDLE;
		end
        
        default : stall_next_state_s = IDLE;
	endcase
end

// FSM output calculation
always @(*) begin
	// Default output values
	// By default forward directly the requestr from the CPU
	stall_instr_mem_rd_s = cpu_instr_mem_rd_i;
	stall_data_mem_rd_s  = cpu_data_mem_rd_i;
	stall_data_mem_wr_s  = cpu_data_mem_wr_i;
	// Sampling of data from bus
	instr_reg_en_s[0] = 1'b0;
	data_reg_en_s     = 1'b0;

	case(stall_current_state_r)
		// Wait for data memory access
  		IDLE : begin
		end

		// Wait for both memory transactions to finish
  		WAIT_BOTH : begin
			instr_reg_en_s[0] = 1'b1;
			data_reg_en_s = 1'b1;
		end

		// Wait for data memory transaction to finish
		WAIT_DATA : begin
			stall_instr_mem_rd_s = 1'b0;
			data_reg_en_s = 1'b1;
		end

		// Wait for instruction memory transaction to finish
		WAIT_INSTR : begin
			stall_data_mem_rd_s = 1'b0;
			stall_data_mem_wr_s = 1'b0;
			instr_reg_en_s[0] = 1'b1;
		end

		// Send acknowledge to hs interface
		HS_ACK : begin
			stall_data_mem_rd_s = 1'b0;
			stall_data_mem_wr_s = 1'b0;
			stall_instr_mem_rd_s = 1'b0;
		end
        
        default : begin
		end
	endcase
end

/* ---------------------------------------------------
* Copy from SPI memory FSM
* --------------------------------------------------*/
// Signals and encoding for FSM status
reg [2:0] copy_current_state_r, copy_next_state_s;
localparam COPY_IDLE = 3'd0;
localparam READ_ROM  = 3'd1;
localparam WRITE_RAM = 3'd2;
localparam INCR_ADDR = 3'd3;
localparam END_COPY  = 3'd4;
// Bus control signals from copy_fsm
reg copy_instr_mem_rd_s, copy_data_mem_wr_s;
// Signal indicating if the copy_fsm is not in idle
assign copy_started_s = (copy_current_state_r!=COPY_IDLE) ? 1'b1 : 1'b0;

// Register for word address that is being copied
//  and register indicating if code is being executed from the code copy in ram
reg [31:0] copy_word_addr_s, copy_word_addr_r;
always @(posedge clk_i) begin
	if(rst_ni == 1'd0) begin
		copy_word_addr_r <= 'b0;
		executing_from_copy_r <= 1'b0;
	end else begin
		copy_word_addr_r <= copy_word_addr_s;
		executing_from_copy_r <= executing_from_copy_s;
	end
end

// FSM present state update
always @(posedge clk_i) begin
	if(rst_ni == 1'd0) begin
		copy_current_state_r <= 'b0;
	end else begin
		copy_current_state_r <= copy_next_state_s;
	end
end

// FSM next state calculation
always @(*) begin
	// Default next state
	copy_next_state_s = copy_current_state_r;

 	case(copy_current_state_r)
		// Wait until a copy is started and the last cpu operation is finished
		COPY_IDLE : begin
			if (start_copy_s & mem_ready_o) begin
				copy_next_state_s = READ_ROM;
			end
		end

		// Get data from code memory
		READ_ROM : begin
			if (bus_instr_mem_ready_s) begin
				copy_next_state_s = WRITE_RAM;
			end
		end

		// Write data to ram (internal or ddr)
		WRITE_RAM : begin
			if (bus_data_mem_ready_i) begin
				copy_next_state_s = INCR_ADDR;
			end
		end

		// Increment word address
		INCR_ADDR : begin
			// Check if next word needs to be copied
			if (copy_word_addr_s == stop_addr_s) begin
				copy_next_state_s = END_COPY;
			end else begin
				copy_next_state_s = READ_ROM;
			end
		end

		// Set register to continue executing from the code copy in ram
		END_COPY : begin
			copy_next_state_s = COPY_IDLE;
		end
        
        default : copy_next_state_s = COPY_IDLE;
	endcase
end

// FSM output calculation
always @(*) begin
	// Default output values
	copy_word_addr_s    = start_addr_s;
	copy_instr_mem_rd_s = 1'b0;
	copy_data_mem_wr_s  = 1'b0;
	instr_reg_en_s[1]   = 1'b0;
	executing_from_copy_s = executing_from_copy_r;
	start_copy_clr_s    = 1'b0;

	case(copy_current_state_r)
  		// Wait until a copy is started
		COPY_IDLE : begin
		end

		// Get data from code memory
		READ_ROM : begin
			copy_instr_mem_rd_s = 1'b1;
			instr_reg_en_s[1]   = 1'b1;
			copy_word_addr_s    = copy_word_addr_r;
		end

		// Write data to ram (internal or ddr)
		WRITE_RAM : begin
			copy_data_mem_wr_s = 1'b1;
			copy_word_addr_s   = copy_word_addr_r;
		end

		// Increment word address
		INCR_ADDR : begin
			copy_word_addr_s = copy_word_addr_r+4;
		end

		// Set register to continue executing from ram
		// Clear start copy bit
		END_COPY : begin
			start_copy_clr_s      = 1'b1;
			executing_from_copy_s = 1'b1;
		end

        default : begin
		end
	endcase
end

// Controller to boot from external spi memory
// Use spi boot controller only when copying (receive transactions from copy_fsm) 
//    or booting from SPI before having copied to RAM (receive transaction from stall_fsm)
wire use_boot_ctrl_s;
assign use_boot_ctrl_s = (copy_started_s || (!executing_from_copy_r && boot_source_i==2'd0));
reg boot_ctrl_rd_s;
reg [31:0] boot_ctrl_addr_s;
always @(*) begin
	if (copy_started_s) begin
		// Receive transactions from copy_fsm
		boot_ctrl_rd_s   = copy_instr_mem_rd_s;
`ifdef FPGA
		boot_ctrl_addr_s = copy_word_addr_r + 32'h00130000;
`else
        boot_ctrl_addr_s = copy_word_addr_r;
`endif
	end else begin
		if (use_boot_ctrl_s) begin
			// Receive transaction from stall_fsm
			boot_ctrl_rd_s = stall_instr_mem_rd_s;
		end else begin
			// Block any transaction
			boot_ctrl_rd_s = 1'b0;
		end
		// Always receive the address from stall_fsm
`ifdef FPGA
		boot_ctrl_addr_s = cpu_instr_mem_addr_i + 32'h00130000;
`else
       boot_ctrl_addr_s = cpu_instr_mem_addr_i;
`endif
	end
end

// Signals between spi boot controller and bus
wire spi_instr_mem_rd_s, spi_instr_mem_ready_s;
wire [31:0] spi_instr_mem_addr_s, spi_instr_mem_data_s;
spi_boot_ctrl inst_spi_boot_ctrl (
	.clk_i(clk_i),
	.rst_ni(rst_ni),
	// Handshake interface from CPU
	.cpu_hs_read_i(boot_ctrl_rd_s),
	.cpu_hs_addr_i(boot_ctrl_addr_s),
	.cpu_hs_ready_o(spi_instr_mem_ready_s),
	.cpu_hs_data_o(spi_instr_mem_data_s),
	// Handshake interface to interconnect
	.bus_hs_ready_i(bus_instr_mem_ready_i),
	.bus_hs_data_i(bus_instr_mem_data_i),
	.bus_hs_rd_o(spi_instr_mem_rd_s),
	.bus_hs_wr_o(bus_instr_mem_wr_o),
	.bus_hs_addr_o(spi_instr_mem_addr_s),
	.bus_hs_data_o(bus_instr_mem_data_o)
);

/* ---------------------------------------------------
* CPU stall control
* CPU needs to be halted while waiting for the bus and while coying code
* --------------------------------------------------*/
always @(*) begin
	if (copy_started_s) begin
		// Stop CPU while copying code
		mem_ready_o = 1'b0;
	end else begin
		if (stall_next_state_s==IDLE && stall_current_state_r==IDLE) begin
			// If no simultaneus instruction/data interfaces operations
			//   connect directly CPU stall signal to ready signal from bus or spi boot ctrl
			if (use_boot_ctrl_s) begin
				// CPU stalled by spi boot controller
				mem_ready_o = spi_instr_mem_ready_s;
			end else begin
				// CPU stalled by bus boot controller
				mem_ready_o = bus_instr_mem_ready_i;
			end
		end else if (stall_current_state_r==HS_ACK) begin
			// stall_fsm has concluded the transactions, start CPU
			mem_ready_o = 1'b1;
		end else begin
			// CPU stalled by stall_fsm
			mem_ready_o = 1'b0;
		end
	end
end

/* ---------------------------------------------------
* Multiplexing of bus interfaces (select stall_fsm/spi_boot_ctrl)
* --------------------------------------------------*/
// Instruction memory interface signals
assign bus_instr_mem_ready_s = (use_boot_ctrl_s) ? spi_instr_mem_ready_s : bus_instr_mem_ready_i;
assign bus_instr_mem_data_s  = (use_boot_ctrl_s) ? spi_instr_mem_data_s  : bus_instr_mem_data_i;
assign bus_instr_mem_rd_o    = (use_boot_ctrl_s) ? spi_instr_mem_rd_s    : stall_instr_mem_rd_s;
// Provide to cpu instruction got from bus (it needs to be taken from the instruciton interface sampling register if concurrent intruction/data accesses)
assign cpu_instr_mem_data_o  = (stall_current_state_r!=HS_ACK) ? bus_instr_mem_data_s : instr_r;
// Select address for bus instruction interface
//  Code can be in external SPI memory, internal SRAM or external DDR
//    depending on boot mode, and if code has been copyed to ram 
always @(*) begin
	if (use_boot_ctrl_s) begin
		// Use address form SPI boot controller
		bus_instr_mem_addr_o = spi_instr_mem_addr_s;
	end else if ((!executing_from_copy_r && boot_source_i==2'd1) || (executing_from_copy_r && copy_destination_s==1'd0)) begin
		// Use address of internal SRAM
		bus_instr_mem_addr_o = {15'd0, cpu_instr_mem_addr_i[16:0]};
	end else begin
		// Use address of external DDR
		bus_instr_mem_addr_o = {4'hf, cpu_instr_mem_addr_i[27:0]};
	end 
end

// Data memory interface signals
// Data memory towards bus (from copy_fsm or from stall_fsm)
// Add offset to memory where to copy code
wire [31:0] copy_data_addr_s;
assign copy_data_addr_s    = (copy_destination_s==1'd0) ? {15'd0, copy_word_addr_r[16:0]} : {4'hf, copy_word_addr_r[27:0]};
assign bus_data_mem_addr_o = (copy_started_s) ? copy_data_addr_s   : cpu_data_mem_addr_i;
assign bus_data_mem_data_o = (copy_started_s) ? instr_r            : cpu_data_mem_data_i;
assign bus_data_mem_wr_o   = (copy_started_s) ? copy_data_mem_wr_s : stall_data_mem_wr_s;
assign bus_data_mem_rd_o   = (copy_started_s) ? 1'b0               : stall_data_mem_rd_s;
assign bus_byte_select_o   = (copy_started_s) ? 4'hf               : cpu_byte_select_i;
// Provide to cpu data got from bus (it always needs to be taken from data interface sampling register)
assign cpu_data_mem_data_o = data_r;

endmodule
