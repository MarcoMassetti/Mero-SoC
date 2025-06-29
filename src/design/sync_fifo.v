module sync_fifo #(
		parameter DEPTH=8,
		parameter DATA_WIDTH=8
		) (
	// Write port
	input clk_i, 
	input rst_i,
	input wr_en_i,
  	input [DATA_WIDTH-1:0] wr_data_i,
	output full_o,
	// Read port
  	input rd_en_i,
  	output [DATA_WIDTH-1:0] rd_data_o,
  	output empty_o,
	output not_empty_o
);

localparam PTR_WIDTH = $clog2(DEPTH);

// Pointers
reg [PTR_WIDTH:0] wr_ptr_r, rd_ptr_r;

// FIFO registers
reg [DATA_WIDTH-1:0] fifo_r [0:DEPTH-1];

// Pointers update
always @(posedge clk_i) begin
	if (rst_i==1'b0) begin
		wr_ptr_r <= 'd0; 
		rd_ptr_r <= 'd0;
	end else begin
		if (wr_en_i && !full_o) begin
      		wr_ptr_r <= wr_ptr_r + 1;
    	end
		if (rd_en_i && not_empty_o) begin
    		rd_ptr_r <= rd_ptr_r + 1;
    	end
	end
end

// Full/empty conditions
assign full_o = ( ({~wr_ptr_r[PTR_WIDTH], wr_ptr_r[PTR_WIDTH-1:0]}) == rd_ptr_r);
assign empty_o = (wr_ptr_r == rd_ptr_r);
assign not_empty_o = ~empty_o;

// FIFO registers update
integer i;
always @(posedge clk_i) begin
	if (rst_i==1'b0) begin
		//Reset of all the registers
        for (i=0; i<DEPTH; i=i+1) begin
            fifo_r[i] <= 'd0;
        end
	end else if (wr_en_i & !full_o) begin
		fifo_r[wr_ptr_r[PTR_WIDTH-1:0]] <= wr_data_i;
	end
end
// Asynchronous read
assign rd_data_o = fifo_r[rd_ptr_r[PTR_WIDTH-1:0]];

endmodule
