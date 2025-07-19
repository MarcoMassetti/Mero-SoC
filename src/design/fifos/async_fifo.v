module async_fifo #(
		parameter DEPTH=8,
		parameter DATA_WIDTH=8
		) (
	// Write port
	input wr_clk_i, 
	input wr_rst_i,
	input wr_en_i,
  	input [DATA_WIDTH-1:0] wr_data_i,
	output full_o,
	output empty_wr_o,

	// Read port
  	input rd_clk_i, 
	input rd_rst_i,
  	input rd_en_i,
  	output [DATA_WIDTH-1:0] rd_data_o,
  	output empty_o,
	output not_empty_o
);

localparam PTR_WIDTH = $clog2(DEPTH);

//// Double FF synchonizers for pointers
reg [PTR_WIDTH:0] wr_ptr_sync_r [1:0];
reg [PTR_WIDTH:0] rd_ptr_sync_r [1:0];

//// Write pointer logic
wire [PTR_WIDTH:0] wr_ptr_bin_s, wr_ptr_gray_s;
reg  [PTR_WIDTH:0] wr_ptr_bin_r, wr_ptr_gray_r;

//// Read pointer logic
wire [PTR_WIDTH:0] rd_ptr_bin_s;
reg  [PTR_WIDTH:0] rd_ptr_bin_r;
wire [PTR_WIDTH:0] rd_ptr_gray_s;
reg  [PTR_WIDTH:0] rd_ptr_gray_r;

//// FIFO registers
reg [DATA_WIDTH-1:0] fifo_r [0:DEPTH-1];


//// Write pointer logic
// Next pointer calculation
assign wr_ptr_bin_s  = wr_ptr_bin_r + (wr_en_i & !full_o);
assign wr_ptr_gray_s = (wr_ptr_bin_s >>1) ^ wr_ptr_bin_s;
// Pointer sampling
always @(posedge wr_clk_i) begin
	if (wr_rst_i == 1'd0) begin
		wr_ptr_bin_r  <= 'd0;
		wr_ptr_gray_r <= 'd0;
	end else begin
		wr_ptr_bin_r  <= wr_ptr_bin_s;
		wr_ptr_gray_r <= wr_ptr_gray_s;
	end
end
// Full condition
assign full_o = (wr_ptr_gray_r == {~rd_ptr_sync_r[1][PTR_WIDTH:PTR_WIDTH-1], rd_ptr_sync_r[1][PTR_WIDTH-2:0]});
// Empty condition (for wr_domain)
assign empty_wr_o = (wr_ptr_gray_r == rd_ptr_sync_r[1]);

//// Read pointer logic
// Next pointer calculation
assign rd_ptr_bin_s  = rd_ptr_bin_r + (rd_en_i & !empty_o);
assign rd_ptr_gray_s = (rd_ptr_bin_s >>1) ^ rd_ptr_bin_s;
// Pointer sampling
always @(posedge rd_clk_i) begin
	if (rd_rst_i == 1'd0) begin
		rd_ptr_bin_r  <= 'd0;
		rd_ptr_gray_r <= 'd0;
	end else begin
		rd_ptr_bin_r  <= rd_ptr_bin_s;
		rd_ptr_gray_r <= rd_ptr_gray_s;
	end
end
// Empty condition
assign empty_o = (wr_ptr_sync_r[1] == rd_ptr_gray_r);
assign not_empty_o = ~empty_o;


//// Double FF synchonizers for pointers
// rd_ptr (from rd_domain to wr_domain)
always @(posedge wr_clk_i) begin
    if (wr_rst_i == 1'd0) begin
		rd_ptr_sync_r[0] <= 'd0;
    	rd_ptr_sync_r[1] <= 'd0;
    end else begin
		rd_ptr_sync_r[0] <= rd_ptr_gray_r;
    	rd_ptr_sync_r[1] <= rd_ptr_sync_r[0];
	end
end
// wr_ptr (from wr_domain to rd_domain)
always @(posedge rd_clk_i) begin
    if (rd_rst_i == 1'd0) begin
    	wr_ptr_sync_r[0] <= 'd0;
    	wr_ptr_sync_r[1] <= 'd0;
    end else begin
    	wr_ptr_sync_r[0] <= wr_ptr_gray_r;
    	wr_ptr_sync_r[1] <= wr_ptr_sync_r[0];
	end
end


//// FIFO registers
integer i;
always @(posedge wr_clk_i) begin
	if (wr_rst_i==1'b0 || rd_rst_i==1'b0) begin
		//Reset of all the registers
        for (i=0; i<DEPTH; i=i+1) begin
            fifo_r[i] <= 'd0;
        end
	end else if (wr_en_i & !full_o) begin
		fifo_r[wr_ptr_bin_r[PTR_WIDTH-1:0]] <= wr_data_i;
	end
end
// Asynchronous read
assign rd_data_o = fifo_r[rd_ptr_bin_r[PTR_WIDTH-1:0]];

endmodule
