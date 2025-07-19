module spi_boot_ctrl(	
	input  clk_i,
	input  rst_ni,

	// Handshake interface from CPU
	input  cpu_hs_read_i,
	input  [31:0] cpu_hs_addr_i,
	output reg cpu_hs_ready_o,
	output [31:0] cpu_hs_data_o,
	
	// Handshake interface to interconnect
	input  bus_hs_ready_i,
	input  [31:0] bus_hs_data_i,
	output reg bus_hs_rd_o,
	output reg bus_hs_wr_o,
	output reg [31:0] bus_hs_addr_o,
	output reg [31:0] bus_hs_data_o
);

// Counter for shift register bytes
reg  [2:0] cnt_r;
reg  cnt_en_s, cnt_clr_s;
wire cnt_tc_s;

// Shift register to send/receive SPI data
reg  load_en_s, shift_en_s;
reg  [7:0] shift_reg_r [7:0];
integer i;
always @(posedge clk_i) begin
	if (rst_ni == 1'd0) begin
		for (i=0; i<8; i=i+1) begin
            shift_reg_r[i] <= 8'd0;
        end
	end else begin
		if (load_en_s == 1'b1) begin
			// Parrallel load values to send to SPI controller
			// Flash read command
			shift_reg_r[7] <= 8'd3;
			// Instruction address
			shift_reg_r[6] <= cpu_hs_addr_i[23:16];
			shift_reg_r[5] <= cpu_hs_addr_i[15:8];
			shift_reg_r[4] <= cpu_hs_addr_i[7:0];
			// Dummy bytes to receive data
			shift_reg_r[3] <= 8'd0;
			shift_reg_r[2] <= 8'd0;
			shift_reg_r[1] <= 8'd0;
			shift_reg_r[0] <= 8'd0;
		end else if (shift_en_s & bus_hs_ready_i) begin
			// Shift data during TX and RX
			shift_reg_r[7] <= shift_reg_r[6];
			shift_reg_r[6] <= shift_reg_r[5];
			shift_reg_r[5] <= shift_reg_r[4];
			shift_reg_r[4] <= shift_reg_r[3];
			shift_reg_r[3] <= shift_reg_r[2];
			shift_reg_r[2] <= shift_reg_r[1];
			shift_reg_r[1] <= shift_reg_r[0];
			// Receive data from SPI controller
    		shift_reg_r[0] <= bus_hs_data_i[7:0];
		end
	end
end

// Counter for shift register bytes
always @(posedge clk_i) begin
	if(rst_ni == 1'd0 || cnt_clr_s == 1'b1) begin
		cnt_r <= 'b0;
	end else begin
		if (cnt_en_s & bus_hs_ready_i) begin
			cnt_r <= cnt_r+1;
		end
	end
end
assign cnt_tc_s = (cnt_r == 3'd7) ? 1'b1 : 1'b0;

// Signals and encoding for FSM status
reg [4:0] current_state_r, next_state_s;
localparam IDLE         = 5'd0;
localparam SET_INHIBIT  = 5'd1;
localparam FILL_TX_FIFO    = 5'd2;
localparam WAIT_BUS_1   = 5'd3;
localparam RESET_INHIBIT     = 5'd4;
localparam WAIT_DATA    = 5'd5;
localparam RECEIVE_DATA = 5'd6;
localparam WAIT_BUS_2   = 5'd7;
localparam SEND_TO_CPU  = 5'd8;

// FSM present state update
always @(posedge clk_i) begin
	if(rst_ni == 1'd0) begin
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
		// Wait for new request from hs interface
  		IDLE : begin
			if (cpu_hs_read_i) begin
				// Send data to SPI controller
				next_state_s = SET_INHIBIT;
			end
		end

		// Set inhibit of spi controller
  		SET_INHIBIT : begin
			if (bus_hs_ready_i) begin
				// Start sending data to SPI controller
				next_state_s = FILL_TX_FIFO;
			end
		end

		// Send 1 byte to SPI controller
		FILL_TX_FIFO : begin
			next_state_s = WAIT_BUS_1;
		end

		// Wait acknowledge from bus
		WAIT_BUS_1 : begin
			if (bus_hs_ready_i) begin
				// Check if all the data has been sent to the controller
				if (cnt_tc_s) begin
					// Start SPI transation
					next_state_s = RESET_INHIBIT;
				end else begin
					// Send next byte
					next_state_s = FILL_TX_FIFO;
				end
			end
		end

		// Start SPI transation realeasing TX inhibit
		RESET_INHIBIT : begin
			if (bus_hs_ready_i) begin
				next_state_s = WAIT_DATA;
			end
		end

		// Wait until RX fifo is filled with 8 bytes
		WAIT_DATA : begin
			if (bus_hs_ready_i && (bus_hs_data_i == 32'd8) ) begin
				// Get data from SPI controller
			    next_state_s = RECEIVE_DATA;
			end
		end
		
		// Get data from SPI controller
		RECEIVE_DATA : begin
			next_state_s = WAIT_BUS_2;
		end

		// Wait acknowledge from bus
		WAIT_BUS_2 : begin
			// Check if all the data has been received to the controller
			if (bus_hs_ready_i) begin
				if (cnt_tc_s) begin
					// Send intruction to the cpu
					next_state_s = SEND_TO_CPU;
				end else begin
					// Get next byte
					next_state_s = RECEIVE_DATA;
				end
			end
		end

		// Send intruction to the cpu
		SEND_TO_CPU : begin
			next_state_s = IDLE;
		end
        
        default : next_state_s = IDLE;
	endcase
end

// FSM output calculation
always @(*) begin
	// Default output values
	cpu_hs_ready_o = 1'b0;
	bus_hs_rd_o    = 1'b0;
	bus_hs_wr_o    = 1'b0;
	bus_hs_addr_o  = 32'b0;
	bus_hs_data_o  = 32'b0;

	load_en_s  = 1'b0;
	shift_en_s = 1'b0;

	cnt_en_s  = 1'b0;
	cnt_clr_s = 1'b0;

	case(current_state_r)
		// Wait for new request from hs interface
  		IDLE : begin
			load_en_s = 1'b1;
		end

		// Set inhibit of spi controller
		SET_INHIBIT : begin
			cnt_clr_s     = 1'b1;
			bus_hs_wr_o   = 1'b1;
			bus_hs_addr_o = 32'h60000;
			bus_hs_data_o = 32'h4;
		end

		// Send 1 byte to SPI controller
		FILL_TX_FIFO : begin
			bus_hs_wr_o   = 1'b1;
			bus_hs_addr_o = 32'h60008;
			bus_hs_data_o = {24'd0, shift_reg_r[7]};
		end

		// Wait acknowledge from bus
		// Keep signals until transaction is done
		WAIT_BUS_1 : begin
			cnt_en_s      = 1'b1;
			shift_en_s    = 1'b1;
			bus_hs_wr_o   = 1'b1;
			bus_hs_addr_o = 32'h60008;
			bus_hs_data_o = {24'd0, shift_reg_r[7]};
		end

		// Start SPI transation realeasing TX inhibit
		RESET_INHIBIT : begin
			cnt_clr_s     = 1'b1;
			bus_hs_wr_o   = 1'b1;
			bus_hs_addr_o = 32'h60060;
			bus_hs_data_o = 32'h0;
		end

		// Wait until RX fifo is filled with 8 bytes
		WAIT_DATA : begin
			bus_hs_rd_o   = 1'b1;
			bus_hs_addr_o = 32'h60014;
		end
		
		// Get data from SPI controller
		RECEIVE_DATA : begin
			bus_hs_rd_o   = 1'b1;
			bus_hs_addr_o = 32'h6000c;
		end

		// Wait acknowledge from bus
		// Keep signals until transaction is done
		WAIT_BUS_2 : begin
			cnt_en_s      = 1'b1;
			shift_en_s    = 1'b1;
			bus_hs_rd_o   = 1'b1;
			bus_hs_addr_o = 32'h6000c;
		end

		// Send intruction to the cpu
		SEND_TO_CPU : begin
			cpu_hs_ready_o = 1'b1;
		end
        
        default : begin
		end
	endcase
end
assign cpu_hs_data_o = {shift_reg_r[0], shift_reg_r[1], shift_reg_r[2], shift_reg_r[3]};

endmodule
