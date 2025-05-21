module axi_master #(
		parameter N_SLV=1
		) (	
		input  clk_i,
		input  rst_i,
		
		//// AXI master interface
		// Read Address (AR) channel
		input  m_arvalid_i,
		output m_aready_o,
		input  [31:0] m_araddr_i,

		// Read Data (R) channel
		output m_rvalid_o,
		input  m_rready_i,
		output m_rlast_o,
		output [31:0] m_rdata_o,
		output [1:0] m_rresp_o,

		// Write Address (AW) channel
		input  m_awvalid_i,
		output m_awready_o,
		input  [31:0] m_awaddr_i,

		// Write Data (W) channel
		input  m_wvalid_i,
		output m_wready_o,
		input  m_wlast_i,
		input  [31:0] m_wdata_i,

		// Write Response (B) channel
		output m_bvalid_o,
		input  m_bready_i,
		output [1:0] m_bresp_o
		
		
		
		//// AXI slaves interfaces
		// Read Address (AR) channel
		output reg s_arvalid_o [0:N_SLV-1],
		input  s_aready_i [0:N_SLV-1],
		output reg [31:0] s_araddr_o[0:N_SLV-1],

		// Read Data (R) channel
		input  s_rvalid_i [0:N_SLV-1],
		output reg s_rready_o[0:N_SLV-1],
		input  s_rlast_i [0:N_SLV-1],
		input  [31:0] s_rdata_i [0:N_SLV-1],
		input  [1:0] s_rresp_i [0:N_SLV-1],

		// Write Address (AW) channel
		output reg s_awvalid_o [0:N_SLV-1],
		input  s_awready_i [0:N_SLV-1],
		output reg [31:0] s_awaddr_o [0:N_SLV-1],

		// Write Data (W) channel
		output reg s_wvalid_o [0:N_SLV-1],
		input  s_wready_i [0:N_SLV-1],
		output reg s_wlast_o [0:N_SLV-1],
		output reg [31:0] s_wdata_o [0:N_SLV-1],

		// Write Response (B) channel
		input  s_bvalid_i [0:N_SLV-1],
		output reg s_bready_o [0:N_SLV-1],
		input  [1:0] s_bresp_i [0:N_SLV-1]
);

// Appena ricevuto indirizzo, decodificare e salvare slave corretto,
// propagare tutti i segnali fino alla fine della transazione, poi tornare in idle

endmodule
