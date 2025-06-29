module uart #(
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

	//// UART interface
	input  rx_i,
	output tx_o
);

/* ---------------------------------------------------
* Register Access Section
* --------------------------------------------------*/
wire [7:0] rx_fifo_data_o_s;
// Status register signals
reg overrun_error_r, rx_frame_error_r;
wire tx_fifo_full_s, tx_fifo_empty_s, rx_fifo_full_s, rx_fifo_not_empty_s;
// Controll register signals
wire rst_tx_fifo_s, rst_rx_fifo_s;
// Clock divider
wire [15:0] clk_div_s;

//// Register access
// Reg_0 (0x00): RX fifo data (RO)
// Reg_1 (0x04): TX fifo data (WO)
// Reg_2 (0x08): Status reg   (RO)
// Reg_3 (0x0C): Ctrl reg     (RW)
// Reg_4 (0x10): Clk_div low  (RW)
// Reg_5 (0x14): Clk_div high (RW)
reg [7:0] registers_r [0:5];

always @(posedge clk_i) begin
    if (rst_i == 0) begin
        // Reset of the registers
        registers_r[3] <= 8'd0;
		// Minimum value for 8x oversampling
		registers_r[4] <= 8'h08;
		registers_r[5] <= 8'h00;
    end else begin
        // Writing in the registers
        if (hs_write_i == 1) begin
            registers_r[hs_addr_i[4:2]] <= hs_data_i;
        end

		// Self clearing bits
		registers_r[3][0] <= (registers_r[3][0]) ? 1'b0 : registers_r[3][0];
		registers_r[3][1] <= (registers_r[3][1]) ? 1'b0 : registers_r[3][1];
    end
	// Register 0 is read-only (RX fifo data)
	registers_r[0] <= rx_fifo_data_o_s;
	// Register 1 is write only (TX fifo data), always read 0 back
	registers_r[1] <= 8'd0;
	// Register 2 is read-only (Status reg)
	registers_r[2] <= {1'b0, rx_frame_error_r, overrun_error_r, 1'b0, tx_fifo_full_s, tx_fifo_empty_s, rx_fifo_full_s, rx_fifo_not_empty_s};
end
// Signals from ctrl register
assign rst_tx_fifo_s = (rst_i && ~registers_r[3][0]);
assign rst_rx_fifo_s = (rst_i && ~registers_r[3][1]);
// Values from clock divider registers
assign clk_div_s = {registers_r[5], registers_r[4]};
//Output for register access
assign hs_data_o = registers_r[hs_addr_i[4:2]];
// Latency of register access is 0
assign hs_ready_o = 1'b1;


/* ---------------------------------------------------
* TX Section
* --------------------------------------------------*/
//// TX fifo
reg tx_fifo_rd_s;
wire tx_fifo_wr_s, tx_fifo_not_empty_s;
assign tx_fifo_wr_s = (hs_write_i && hs_addr_i[4:2]==3'd1) ? 1'b1 : 1'b0;
wire [7:0] tx_fifo_data_o_s;
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
  	.rd_data_o(tx_fifo_data_o_s),
  	.empty_o(tx_fifo_empty_s),
	.not_empty_o(tx_fifo_not_empty_s)
);


//// UART TX FSM
// Signals and encoding for TX FSM
reg [2:0] tx_current_state_r, tx_next_state_s;
localparam TX_IDLE      = 3'd0;
localparam TX_START_BIT = 3'd1;
localparam TX_DATA      = 3'd2;
localparam TX_STOP      = 3'd3;
localparam TX_POP_FIFO  = 3'd4;

// TX clock divider signals
reg tx_clk_div_en_s;
reg [15:0] tx_clk_div_r;
wire tx_clk_div_tc_s;
// TX bit counter signals
reg tx_bit_cnt_clr_s;
reg [2:0] tx_bit_cnt_r;
wire tx_bit_cnt_tc_s;
// Signal fo send start/stop bit
reg tx_force_zero_s, tx_force_one_s;

// FSM present state update
always @(posedge clk_i) begin
	if(rst_i == 1'd0) begin
		tx_current_state_r <= 'b0;
	end else begin
		tx_current_state_r <= tx_next_state_s;
	end
end

// FSM next state calculation
always @(*) begin
	// Default next state
	tx_next_state_s = tx_current_state_r;

 	case(tx_current_state_r)
		// Idle: wait for data in tx fifo
  		TX_IDLE : begin
			if (tx_fifo_not_empty_s) begin
				// Start transmission
				tx_next_state_s = TX_START_BIT;
			end
		end

		// Send start bit
		TX_START_BIT : begin
			// Continue for 1 bit time
			if (tx_clk_div_tc_s) begin
				tx_next_state_s = TX_DATA;
			end
		end

		// Send 8 data bits
		TX_DATA : begin
			// Continue for 8 bit times
			if (tx_clk_div_tc_s && tx_bit_cnt_tc_s) begin
				tx_next_state_s = TX_STOP;
			end
		end

		// Send stop bit
		TX_STOP : begin
			// Continue for 1 bit time
			if (tx_clk_div_tc_s) begin
				tx_next_state_s = TX_POP_FIFO;
			end
		end

		// Remove item from tx fifo
		TX_POP_FIFO : begin
				tx_next_state_s = TX_IDLE;
		end
        
        default : tx_next_state_s = TX_IDLE;
	endcase
end

// FSM output calculation
always @(*) begin
	// Default output values
	tx_clk_div_en_s  = 1'b0;
	tx_bit_cnt_clr_s = 1'b0;

	tx_fifo_rd_s = 1'b0;
	tx_force_one_s = 1'b1;
	tx_force_zero_s = 1'b0;

	case(tx_current_state_r)
		// Idle: wait for data in tx fifo
  		TX_IDLE : begin
			tx_bit_cnt_clr_s = 1'b1;
		end

		// Send start bit
		TX_START_BIT : begin
			tx_clk_div_en_s = 1'b1;
			tx_bit_cnt_clr_s = 1'b1;
			tx_force_zero_s = 1'b1;
			tx_force_one_s = 1'b0;
		end

		// Send 8 data bits
		TX_DATA : begin
			tx_clk_div_en_s = 1'b1;
			tx_force_zero_s = 1'b0;
			tx_force_one_s = 1'b0;
		end

		// Send stop bit
		TX_STOP : begin
			tx_clk_div_en_s = 1'b1;
		end

		// Remove item from tx fifo
		TX_POP_FIFO : begin
			tx_fifo_rd_s = 1'b1;
		end

        default : begin
		end
	endcase
end

// TX clock divider counter
always @(posedge clk_i) begin
	if(rst_i == 1'd0) begin
		tx_clk_div_r <= 'b0;
	end else begin
		if (tx_clk_div_en_s == 1'b1 && ~tx_clk_div_tc_s) begin
			// Count up when enabled
			tx_clk_div_r <= tx_clk_div_r+1;
		end else begin
			// Clear when not enabled
			tx_clk_div_r <= 'b0;
		end
	end
end
assign tx_clk_div_tc_s = (tx_clk_div_r==(clk_div_s-1)) ? 1'b1: 1'b0;

// TX bit counter
always @(posedge clk_i) begin
	if(rst_i == 1'd0) begin
		tx_bit_cnt_r <= 'b0;
	end else begin
		if (tx_bit_cnt_clr_s == 1'b1) begin
			// Clear
			tx_bit_cnt_r <= 'b0;
		end else if (tx_clk_div_tc_s) begin
			// Count up when bit time have ended
			tx_bit_cnt_r <= tx_bit_cnt_r+1;
		end
	end
end
assign tx_bit_cnt_tc_s = (tx_bit_cnt_r==3'd7) ? 1'b1: 1'b0;
assign tx_o = (tx_force_one_s | tx_fifo_data_o_s[tx_bit_cnt_r]) & ~tx_force_zero_s;


/* ---------------------------------------------------
* RX Section
* --------------------------------------------------*/
// RX clock divider signals
reg [12:0] rx_clk_div_r;
wire rx_clk_div_tc_s;
// RX sample counter
reg rx_smpl_cnt_clr_s;
reg [2:0] rx_smpl_cnt_r, rx_smpl_cnt_tc_val_s;
wire rx_smpl_cnt_tc_s;
// RX bit counter signals
reg rx_bit_cnt_clr_s;
reg [2:0] rx_bit_cnt_r;
wire rx_bit_cnt_tc_s;

// RX FIFO
wire rx_fifo_rd_s;
assign rx_fifo_rd_s = (hs_read_i && hs_addr_i[4:2]==3'd0) ? 1'b1 : 1'b0;
reg rx_fifo_wr_s;
reg rx_fifo_data_sh_en_s;
reg [7:0] rx_fifo_data_r;
sync_fifo  #(
	.DEPTH(FIFO_DEPTH),
	.DATA_WIDTH(8)
	)
	inst_rx_fifo (	
	// Write port
	.clk_i(clk_i), 
	.rst_i(rst_rx_fifo_s),
	.wr_en_i(rx_fifo_wr_s),
  	.wr_data_i(rx_fifo_data_r),
	.full_o(rx_fifo_full_s),
	// Read port
  	.rd_en_i(rx_fifo_rd_s),
  	.rd_data_o(rx_fifo_data_o_s),
  	.empty_o(),
	.not_empty_o(rx_fifo_not_empty_s)
);

// RX fifo overrun error flag
wire overrun_error_clr_s;
assign overrun_error_clr_s = (hs_read_i && hs_addr_i[4:2]==3'd2) ? 1'b1 : 1'b0;
always @(posedge clk_i) begin
    if (rst_i == 1'd0) begin
    	overrun_error_r <= 1'b0;
    end else begin
		if (rx_fifo_full_s & rx_fifo_wr_s) begin
			// Set flag if write to fifo is tried when fifo is full
			//  (the fifo will not save the data)
			overrun_error_r <= 1'b1;
		end else if (overrun_error_clr_s) begin
			overrun_error_r <= 1'b0;
		end
	end
end

// RX frame error flag
reg rx_frame_err_set_s;
wire rx_frame_error_clr_s;
assign rx_frame_error_clr_s = (hs_read_i && hs_addr_i[4:2]==3'd2) ? 1'b1 : 1'b0;
always @(posedge clk_i) begin
    if (rst_i == 1'd0) begin
    	rx_frame_error_r <= 1'b0;
    end else begin
		if (rx_frame_err_set_s) begin
			// Set flag if received stop bit is not 1
			//  (the fifo will not save the data)
			rx_frame_error_r <= 1'b1;
		end else if (rx_frame_error_clr_s) begin
			rx_frame_error_r <= 1'b0;
		end
	end
end


// RX line sampling (Double FF sinchronizer)
reg [1:0] rx_r;
always @(posedge clk_i) begin
    if (rst_i == 1'd0) begin
    	rx_r <= 2'd3;
    end else begin
    	rx_r[0] <= rx_i;
    	rx_r[1] <= rx_r[0];
	end
end

// Shift register for RX line samples
//  (8X oversampling of baud rate)
reg [7:0] rx_shift_r;
always @(posedge clk_i) begin
    if (rst_i == 1'd0) begin
    	rx_shift_r <= 8'd255;
    end else begin
		if (rx_clk_div_tc_s) begin
    		rx_shift_r <= {rx_shift_r[6:0], rx_r[1]};
		end
	end
end

// 3 bit majority voting from 3 central RX samples (bit 2,3,4)
wire rx_bit_s;
assign rx_bit_s = (rx_shift_r[2] && rx_shift_r[3]) || 
                  (rx_shift_r[2] && rx_shift_r[4]) || 
				  (rx_shift_r[3] && rx_shift_r[4]);

// Shift register for RX data
always @(posedge clk_i) begin
    if (rst_i == 1'd0) begin
    	rx_fifo_data_r <= 8'd0;
    end else begin
		if (rx_fifo_data_sh_en_s && rx_clk_div_tc_s && rx_smpl_cnt_tc_s) begin
    		rx_fifo_data_r <= {rx_bit_s, rx_fifo_data_r[7:1]};
		end
	end
end

//// UART RX FSM
// Signals and encoding for RX FSM
reg [2:0] rx_current_state_r, rx_next_state_s;
localparam RX_IDLE       = 3'd0;
localparam RX_START_BIT  = 3'd1;
localparam RX_DATA       = 3'd2;
localparam RX_STOP       = 3'd3;
localparam RX_PUSH_FIFO  = 3'd4;
localparam RX_FRAME_ERR  = 3'd5;


// FSM present state update
always @(posedge clk_i) begin
	if(rst_i == 1'd0) begin
		rx_current_state_r <= 'b0;
	end else begin
		rx_current_state_r <= rx_next_state_s;
	end
end

// FSM next state calculation
always @(*) begin
	// Default next state
	rx_next_state_s = rx_current_state_r;

 	case(rx_current_state_r)
		// Idle: wait for start bit
  		RX_IDLE : begin
			if (rx_bit_s==1'b0) begin
				// Start transmission
				rx_next_state_s = RX_START_BIT;
			end
		end

		// Receive remaining of start bit
		RX_START_BIT : begin
			// Continue for 1/2 bit time
			if (rx_clk_div_tc_s && rx_smpl_cnt_tc_s) begin
				rx_next_state_s = RX_DATA;
			end
		end

		// Receive 8 data bits
		RX_DATA : begin
			// Continue for 8 bit times
			if (rx_clk_div_tc_s && rx_smpl_cnt_tc_s && rx_bit_cnt_tc_s) begin
				rx_next_state_s = RX_STOP;
			end
		end

		// Receive stop bit
		RX_STOP : begin
			// Continue for 1 bit time
			if (rx_clk_div_tc_s && rx_smpl_cnt_tc_s) begin
				if (rx_bit_s==1'b1) begin
					rx_next_state_s = RX_PUSH_FIFO;
				end else begin
					rx_next_state_s = RX_FRAME_ERR;
				end
			end
		end

		// Push item into rx fifo
		RX_PUSH_FIFO : begin
				rx_next_state_s = RX_IDLE;
		end

		// Set frame error flag
		RX_FRAME_ERR : begin
				rx_next_state_s = RX_IDLE;
		end
        
        default : rx_next_state_s = RX_IDLE;
	endcase
end

// FSM output calculation
always @(*) begin
	// Default output values
	rx_bit_cnt_clr_s  = 1'b0;
	rx_smpl_cnt_clr_s = 1'b0;

	rx_fifo_wr_s = 1'b0;
	rx_fifo_data_sh_en_s = 1'b0;
	rx_smpl_cnt_tc_val_s = 3'd7;
	rx_frame_err_set_s = 1'b0;

	case(rx_current_state_r)
		// Idle: wait for start bit
  		RX_IDLE : begin
			rx_bit_cnt_clr_s  = 1'b1;
			rx_smpl_cnt_clr_s = 1'b1;
		end

		// Receive remaining of start bit
		RX_START_BIT : begin
			rx_bit_cnt_clr_s  = 1'b1;
			rx_smpl_cnt_tc_val_s = 3'd3;
		end

		// Receive 8 data bits
		RX_DATA : begin
			rx_fifo_data_sh_en_s = 1'b1;
		end

		// Receive stop bit
		RX_STOP : begin
			rx_bit_cnt_clr_s  = 1'b1;
		end

		// Push item into rx fifo
		RX_PUSH_FIFO : begin
			rx_fifo_wr_s = 1'b1;
		end

		// Set frame error flag
		RX_FRAME_ERR : begin
			rx_frame_err_set_s = 1'b1;
		end

        default : begin
		end
	endcase
end

// RX Clock divider counter
always @(posedge clk_i) begin
	if(rst_i == 1'd0) begin
		rx_clk_div_r <= 'b0;
	end else begin
		if (~rx_clk_div_tc_s) begin
			// Count up when enabled
			rx_clk_div_r <= rx_clk_div_r+1;
		end else begin
			// Clear when not enabled
			rx_clk_div_r <= 'b0;
		end
	end
end
// 8X oversampling
assign rx_clk_div_tc_s = (rx_clk_div_r==(clk_div_s[15:3]-1)) ? 1'b1: 1'b0;

// RX sample counter
always @(posedge clk_i) begin
	if(rst_i == 1'd0) begin
		rx_smpl_cnt_r <= 'b0;
	end else begin
		if (rx_smpl_cnt_clr_s | (rx_next_state_s!=rx_current_state_r)) begin
			// Clear
			rx_smpl_cnt_r <= 'b0;
		end else if (rx_clk_div_tc_s == 1'b1) begin
			// Count up when enabled
			rx_smpl_cnt_r <= rx_smpl_cnt_r+1;
		end
	end
end
assign rx_smpl_cnt_tc_s = (rx_smpl_cnt_r==rx_smpl_cnt_tc_val_s) ? 1'b1: 1'b0;

// RX bit counter
always @(posedge clk_i) begin
	if(rst_i == 1'd0) begin
		rx_bit_cnt_r <= 'b0;
	end else begin
		if (rx_bit_cnt_clr_s) begin
			// Clear
			rx_bit_cnt_r <= 'b0;
		end else if (rx_smpl_cnt_tc_s & rx_clk_div_tc_s) begin
			// Count up when enabled
			rx_bit_cnt_r <= rx_bit_cnt_r+1;
		end
	end
end
assign rx_bit_cnt_tc_s = (rx_bit_cnt_r==3'd7) ? 1'b1: 1'b0;

endmodule
