module spi_mst #(
	parameter FIFO_DEPTH=16
	)(	
	input  clk_i,
	input  rst_i,

	// Handshake interface
	input  hs_read_i,
	input  hs_write_i,
	input  [4:0] hs_addr_i,
	input  [7:0] hs_data_i,
	output hs_ready_o,
	output [7:0] hs_data_o,

	// SPI interface
	output sck_o,
	output reg cs_no,
	output mosi_o,
	input  miso_i 
);

/* ---------------------------------------------------
* Register Access
* --------------------------------------------------*/
wire [7:0] rx_fifo_data_o_s;
reg  [7:0] rx_fifo_level_r, tx_fifo_level_r;
// Status register signals
wire tx_fifo_full_s, tx_fifo_empty_s, rx_fifo_full_s, rx_fifo_empty_s;
// Control register signals
wire rst_tx_fifo_s, rst_rx_fifo_s, tx_inhibit_s, clk_pol_s, clk_phase_s, lsb_first;
// Clock divider
wire [15:0] clk_div_s;

//// Register access
// Reg_0 (0x00): Ctrl reg      (RW)
// Reg_1 (0x04): Status reg    (RO)
// Reg_2 (0x08): TX fifo data  (WO)
// Reg_3 (0x0C): RX fifo data  (RO)
// Reg_4 (0x10): TX fifo level (RO)
// Reg_5 (0x14): RX fifo level (RO)
// Reg_6 (0x18): Clk_div low   (RW)
// Reg_7 (0x1C): Clk_div high  (RW)
reg [7:0] registers_r [0:7];
always @(posedge clk_i) begin
    if (rst_i == 0) begin
        // Reset of the registers
		registers_r[0] <= 8'd0;
		registers_r[2] <= 8'd0;
		registers_r[6] <= 8'd1;
		registers_r[7] <= 8'd0;
    end else begin
        // Writing in the registers
        if (hs_write_i == 1'b1) begin
            registers_r[hs_addr_i[4:2]] <= hs_data_i;
        end
		// Self clearing bits
		registers_r[0][0] <= (registers_r[3][0]) ? 1'b0 : registers_r[0][0];
		registers_r[0][1] <= (registers_r[3][1]) ? 1'b0 : registers_r[0][1];
    end
	// Register 1 is read-only (Status reg)
	registers_r[1] <= {4'd0, tx_fifo_full_s, tx_fifo_empty_s, rx_fifo_full_s, rx_fifo_empty_s};
	// Register 3 is read-only (RX fifo data)
	registers_r[3] <= rx_fifo_data_o_s;
	// Register 4 is read-only (TX fifo level)
	registers_r[4] <= tx_fifo_level_r;
	// Register 5 is read-only (RX fifo level)
	registers_r[5] <= rx_fifo_level_r;
	// Register 2 is write only (TX fifo data), always read 0 back
	registers_r[2] <= 8'd0;
end
// Signals from ctrl register
assign rst_tx_fifo_s = (rst_i & ~registers_r[0][0]);
assign rst_rx_fifo_s = (rst_i & ~registers_r[0][1]);
assign tx_inhibit_s  = registers_r[0][2];
assign clk_pol_s     = registers_r[0][3];
assign clk_phase_s   = registers_r[0][4];
assign lsb_first     = registers_r[0][5];
// Values from clock divider registers
assign clk_div_s = {registers_r[7], registers_r[6]};
// Output for register access
assign hs_data_o = registers_r[hs_addr_i[4:2]];
// Latency of register access is 0
assign hs_ready_o = 1'b1;


/* ---------------------------------------------------
* FSM
* --------------------------------------------------*/
// Clock divider signals
reg  clk_div_en_s;
reg  [15:0] clk_div_r;
wire clk_div_tc_s;
// Bit counter signals
reg  bit_cnt_clr_s;
reg  [2:0] bit_cnt_r;
wire bit_cnt_tc_s;
// Divided output clock and, clock output enable signal
reg [3:0] edge_cnt_r;
reg sck_en_s;
// TX fifo control/status signals
reg  tx_fifo_rd_s;
wire tx_fifo_wr_s, tx_fifo_not_empty_s;
// RX fifo control signal
reg rx_fifo_wr_s;

// Signals and encoding for FSM
reg [2:0] current_state_r, next_state_s;
localparam IDLE           = 3'd0;
localparam SET_CS         = 3'd1;
localparam DATA           = 3'd2;
localparam POP_PUSH_FIFOS = 3'd3;
localparam RESET_CS       = 3'd4;

// FSM present state update
always @(posedge clk_i) begin
	if(rst_i == 1'd0) begin
		current_state_r <= 'b0;
	end else begin
		current_state_r <= next_state_s;
	end
end

// FSM next state calculation
always @(*) begin
	// Default next state
	next_state_s = current_state_r;

 	case(current_state_r)
		// Wait for data in tx fifo
  		IDLE : begin
			if (tx_fifo_not_empty_s & ~tx_inhibit_s) begin
				// Start transmission
				next_state_s = SET_CS;
			end
		end

		// Set chip select
		// Wait 1 bit time before starting clock
  		SET_CS : begin
			if (clk_div_tc_s) begin
				// Start transmission
				next_state_s = DATA;
			end
		end

		// Transmit/receive 1 byte
  		DATA : begin
			if (clk_div_tc_s & bit_cnt_tc_s & edge_cnt_r[0]) begin
				next_state_s = POP_PUSH_FIFOS;
			end
		end
		// Remove transmitted byte from tx fifo
		// Add received byte into rx fifo
  		POP_PUSH_FIFOS : begin
			if ((tx_fifo_level_r!=1) & ~tx_inhibit_s) begin
				// Continue transmission of next byte
				next_state_s = DATA;
			end else begin
				// Return to idle
				next_state_s = RESET_CS;
			end
		end

		// Release chip select
		// Wait at least one bit time before starting new transaction
  		RESET_CS : begin
			if (clk_div_tc_s) begin
				// Return to idle
				next_state_s = IDLE;
			end
		end
        
        default : next_state_s = IDLE;
	endcase
end

// FSM output calculation
always @(*) begin
	// Default output values
	cs_no         = 1'b1;
	sck_en_s      = 1'b0;
	clk_div_en_s  = 1'b0;
	bit_cnt_clr_s = 1'b0;
	tx_fifo_rd_s  = 1'b0;
	rx_fifo_wr_s  = 1'b0;

	case(current_state_r)
		// Wait for data in tx fifo
  		IDLE : begin
			bit_cnt_clr_s = 1'b1;
		end

		// Set chip select
		// Wait 1 bit time before starting clock
  		SET_CS : begin
			cs_no         = 1'b0;
			clk_div_en_s  = 1'b1;
			bit_cnt_clr_s = 1'b1;
		end

		// Transmit/receive 1 byte
  		DATA : begin
			cs_no         = 1'b0;
			sck_en_s      = 1'b1;
			clk_div_en_s  = 1'b1;
		end

		// Remove transmitted byte from tx fifo
		// Add received byte into rx fifo
  		POP_PUSH_FIFOS : begin
			cs_no        = 1'b0;
			clk_div_en_s = 1'b1;
			tx_fifo_rd_s = 1'b1;
			rx_fifo_wr_s = 1'b1;
		end

		// Release chip select
		// Wait at least one bit time before starting new transaction
  		RESET_CS : begin
			cs_no         = 1'b0;
			clk_div_en_s  = 1'b1;
			bit_cnt_clr_s = 1'b1;
		end

        default : begin
		end
	endcase
end


/* ---------------------------------------------------
* Clock/Bit counters
* --------------------------------------------------*/
// Clock divider counter
always @(posedge clk_i) begin
	if(rst_i == 1'd0) begin
		clk_div_r <= 'b0;
	end else begin
		if (clk_div_en_s == 1'b1 && ~clk_div_tc_s) begin
			// Count up when enabled
			clk_div_r <= clk_div_r+1;
		end else begin
			// Clear when not enabled
			clk_div_r <= 'b0;
		end
	end
end
assign clk_div_tc_s = (clk_div_r==(clk_div_s-1)) ? 1'b1: 1'b0;

// Bit counter
always @(posedge clk_i) begin
	if(rst_i == 1'd0) begin
		bit_cnt_r <= 'b0;
	end else begin
		if (bit_cnt_clr_s == 1'b1) begin
			// Clear
			bit_cnt_r <= 'b0;
		end else if (clk_div_tc_s & edge_cnt_r[0]) begin
			// Count up when bit time have ended
			bit_cnt_r <= bit_cnt_r+1;
		end
	end
end
assign bit_cnt_tc_s = (bit_cnt_r==3'd7) ? 1'b1: 1'b0;

// Output clock generation
always @(posedge clk_i) begin
	if(rst_i == 1'd0) begin
		edge_cnt_r <= 4'd0;
	end else begin
		if (sck_en_s & clk_div_tc_s) begin
			// Count up every time there is a terminal count from clock divider
			edge_cnt_r <= edge_cnt_r+1;
		end
	end
end
// Output clock taken from lsb of edge counter
assign sck_o = edge_cnt_r[0] ^ clk_pol_s;


/* ---------------------------------------------------
* TX Section
* --------------------------------------------------*/
// TX fifo
assign tx_fifo_wr_s = (hs_write_i && hs_addr_i[4:2]==3'd2) ? 1'b1 : 1'b0;
wire [7:0] tx_data_s;
sync_fifo  #(
	.DEPTH(FIFO_DEPTH),
	.DATA_WIDTH(8)
	)
	inst_tx_fifo (	
	// Write port
	.clk_i(clk_i), 
	.rst_i(rst_tx_fifo_s),
	.wr_en_i(tx_fifo_wr_s),
  	.wr_data_i(hs_data_i),
	.full_o(tx_fifo_full_s),
	// Read port
  	.rd_en_i(tx_fifo_rd_s),
  	.rd_data_o(tx_data_s),
  	.empty_o(tx_fifo_empty_s),
	.not_empty_o(tx_fifo_not_empty_s)
);

// TX fifo fill level counter
always @(posedge clk_i) begin
	if(rst_i == 1'd0) begin
		tx_fifo_level_r <= 'd0;
	end else begin
		if (rst_tx_fifo_s==1'b0) begin
			// Reset counter when fifo is reset
			tx_fifo_level_r <='d0;
		end else if (tx_fifo_wr_s==1'b1 && tx_fifo_rd_s==1'b0) begin
			// Increase counter if fifo when filled
			tx_fifo_level_r <= tx_fifo_level_r+1;
		end else if (tx_fifo_wr_s==1'b0 && tx_fifo_rd_s==1'b1) begin
			// Increase counter if fifo when emptied
			tx_fifo_level_r <= tx_fifo_level_r-1;
		end
	end
end

// Select bit order depending on register field
wire correct_bit_order_data_s;
assign correct_bit_order_data_s = (lsb_first) ? tx_data_s[bit_cnt_r] : tx_data_s[7-bit_cnt_r];

// Delay for clock phase 1 configurations
reg mosi_r;
always @(posedge clk_i) begin
	if(rst_i == 1'd0) begin
		mosi_r <= 1'd0;
	end else begin
		if (sck_en_s & clk_div_tc_s) begin
			// Sample every time there is a terminal count from clock divider
			mosi_r <= correct_bit_order_data_s;
		end
	end
end
// Output data (select between direct and delayed data depending on clock phase)
assign mosi_o = (clk_phase_s) ? mosi_r : correct_bit_order_data_s;


/* ---------------------------------------------------
* RX Section
* --------------------------------------------------*/
// Byte being received
reg [7:0] rx_data_r;
always @(posedge clk_i) begin
	if(rst_i == 1'd0) begin
		rx_data_r <= 'b0;
	end else begin
		if (clk_div_en_s==1'b1 && clk_div_tc_s && (edge_cnt_r[0]==(clk_pol_s | clk_phase_s))) begin
			rx_data_r <= (lsb_first) ? {miso_i, rx_data_r[7:1]} : {rx_data_r[6:0], miso_i};
		end
	end
end

// RX fifo
wire rx_fifo_rd_s;
assign rx_fifo_rd_s = (hs_read_i && hs_addr_i[4:2]==3'd3) ? 1'b1 : 1'b0;
sync_fifo  #(
	.DEPTH(FIFO_DEPTH),
	.DATA_WIDTH(8)
	)
	inst_rx_fifo (	
	// Write port
	.clk_i(clk_i), 
	.rst_i(rst_rx_fifo_s),
	.wr_en_i(rx_fifo_wr_s),
  	.wr_data_i(rx_data_r),
	.full_o(rx_fifo_full_s),
	// Read port
  	.rd_en_i(rx_fifo_rd_s),
  	.rd_data_o(rx_fifo_data_o_s),
  	.empty_o(rx_fifo_empty_s),
	.not_empty_o()
);

// RX fifo fill level counter
always @(posedge clk_i) begin
	if(rst_i == 1'd0) begin
		rx_fifo_level_r <= 'd0;
	end else begin
		if (rst_rx_fifo_s==1'b0) begin
			// Reset counter when fifo is reset
			rx_fifo_level_r <='d0;
		end else if (rx_fifo_wr_s==1'b1 && rx_fifo_rd_s==1'b0) begin
			// Increase counter if fifo when filled
			rx_fifo_level_r <= rx_fifo_level_r+1;
		end else if (rx_fifo_wr_s==1'b0 && rx_fifo_rd_s==1'b1) begin
			// Increase counter if fifo when emptied
			rx_fifo_level_r <= rx_fifo_level_r-1;
		end
	end
end

endmodule
