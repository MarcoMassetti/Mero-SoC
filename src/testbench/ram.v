// OpenRAM SRAM model
// Words: 1024
// Word size: 32

module ram(
// Port 0: RW
    clk0,csb0,web0,addr0,din0,dout0,wmask0
  );

  parameter DATA_WIDTH = 32 ;
  parameter ADDR_WIDTH = 15 ;
  parameter RAM_DEPTH = 1 << ADDR_WIDTH;
  parameter NUM_WMASKS = 4 ;
  // FIXME: This delay is arbitrary.

  input  clk0; // clock
  input   csb0; // active low chip select
  input  web0; // active low write control
  input [ADDR_WIDTH-1:0]  addr0;
  input [DATA_WIDTH-1:0]  din0;
  output [DATA_WIDTH-1:0] dout0;
  input [NUM_WMASKS-1:0]  wmask0; // write mask

  reg  csb0_reg;
  reg  web0_reg;
  reg [ADDR_WIDTH-1:0]  addr0_reg;
  reg [DATA_WIDTH-1:0]  din0_reg;
  reg [DATA_WIDTH-1:0]  dout0;
  reg [NUM_WMASKS-1:0]  wmask0_reg;

  // All inputs are registers
  always @(posedge clk0) begin
    csb0_reg <= csb0;
    web0_reg <= web0;
    addr0_reg <= addr0;
    din0_reg <= din0;
    wmask0_reg = wmask0;
    //dout0 = 32'bx;
  end

reg [DATA_WIDTH-1:0]    mem [0:RAM_DEPTH-1];

  parameter FILE_NAME;
  integer file;
  integer i;
  reg [DATA_WIDTH-1:0] data;
  initial begin
    file = $fopen(FILE_NAME, "rb");
    if (file == 0) begin
      $display("Error opening file");
    end else begin
      i = 0;
      while ($fread(data, file)) begin
          mem[i] = {data[7:0], data[15:8], data[23:16], data[31:24]};
          i = i + 1;
      end
      $fclose(file);
    end
  end

  // Memory Write Block Port 0
  // Write Operation : When web0 = 0, csb0 = 0
  always @(negedge clk0) begin
    if ( !csb0_reg && !web0_reg ) begin
        if (wmask0_reg[0])
                mem[addr0_reg][7:0] = din0_reg[7:0];
        if (wmask0_reg[1])
                mem[addr0_reg][15:8] = din0_reg[15:8];
        if (wmask0_reg[2])
                mem[addr0_reg][23:16] = din0_reg[23:16];
        if (wmask0_reg[3])
                mem[addr0_reg][31:24] = din0_reg[31:24];
    end
  end

  // Memory Read Block Port 0
  // Read Operation : When web0 = 1, csb0 = 0
  always @(negedge clk0) begin
    if (!csb0_reg && web0_reg) begin
       dout0 <= mem[addr0_reg];
    end
  end

endmodule
