module cpu (
	input  clk_i,
	input  rst_i,

	// Instruction memory IOs
	input  instr_mem_ready_i,
	input  [31:0] instr_mem_data_i,
	output [31:0] instr_mem_addr_o,
	output instr_mem_rd_o,

	// Data memory IOs
	input  data_mem_ready_i,
	input  [31:0] data_mem_data_i,
	output [31:0] data_mem_addr_o,
	output [31:0] data_mem_data_o,
	output data_mem_rd_o,
	output data_mem_wr_o,
	output [3:0] byte_select_o
);


/******************************************************************************
* SIGNAL DECLARATIONS
******************************************************************************/
wire mem_ready_s;

/* ---------------------------------------------------
* Related to Instruction Fetch (IF) Pipeline Section
* --------------------------------------------------*/
// Next instruction address
wire        instr_addr_src_s;
wire [31:0] next_instr_addr_s;
reg  [31:0] jmp_addr_mem_r;
// Current instruction address
reg  [31:0] instr_addr_s;
reg  [31:0] instr_addr_r;
// Instruction memory output
wire [31:0] instruction_s;
// Stall control
wire        rst_bubble_s;
reg         rst_bubble_r;
// Pipeline register
reg  [31:0] instr_addr_id_r, instr_id_r;

/* ---------------------------------------------------
* Related to Instruction Decode (ID) Pipeline Section
* --------------------------------------------------*/
// Signals for immediate calculation
wire [24:0] tmp_immediate_s;
reg  [31:0] immediate_s;
// Register file
reg         reg_write_wb_r;
reg  [4:0]  rd_addr_wb_r;
reg  [31:0] reg_data_i_s;
wire [31:0] rs1_data_s, rs2_data_s;
// Control signals
wire [2:0]  imm_select_s;
wire [3:0]  alu_op_s;
wire jmp_addr_op1_sel_s, reg_write_s, alu_pc_s, alu_src_s, mem_read_s, mem_write_s, mem_to_reg_s, branch_s;
reg hazard_nop_s;
// Pipeline register
reg  [31:0] immediate_ex_r, instr_addr_ex_r, rs1_data_ex_r, rs2_data_ex_r;
reg  [3:0]  alu_op_ex_r;
reg  [31:7] inst_ex_r;
reg alu_pc_ex_r, alu_src_ex_r, reg_write_ex_r, mem_to_reg_ex_r, mem_read_ex_r, mem_write_ex_r, jmp_addr_op1_sel_ex_r, branch_ex_r;

/* ---------------------------------------------------
* Related to Execute (EX) Pipeline Section
* --------------------------------------------------*/
// ALU
reg  [31:0] op1_alu_s, op2_alu_s;
wire [31:0] alu_result_s;
wire [4:0]  alu_ctrl_s;
wire zero_s;
// Jump
reg  [31:0] op1_jump_addr_s;
wire [31:0] jmp_addr_s;
// Forwarding
reg  [1:0] forward_op1_sel_s, forward_op2_sel_s;
// Pipeline register
reg  [31:0] alu_result_mem_r, rs2_data_mem_r;
reg  [4:0] rd_addr_mem_r;
reg zero_mem_r, reg_write_mem_r, mem_to_reg_mem_r, branch_mem_r, mem_read_mem_r, mem_write_mem_r;
reg  [2:0] funct_3_mem_r;

/* ---------------------------------------------------
* Related to Memory (MEM) Pipeline Section
* --------------------------------------------------*/
// Data memory output
wire [31:0] data_mem_o;
// Pipeline register
reg  [31:0] data_mem_o_wb_r, alu_result_wb_r;
reg mem_to_reg_wb_r;


/******************************************************************************
* BEGINNING OF IMPLEMENTATION
******************************************************************************/
assign mem_ready_s = instr_mem_ready_i & data_mem_ready_i;

/******************************************************************************
* Instruction Fetch (IF) Pipeline Section
******************************************************************************/

// Signal to reset in case of external reset or jumps
assign rst_bubble_s = (mem_ready_s) ? ((~instr_addr_src_s) & rst_i) : 1'b1;

// Flip-Flop to save the previous state of the reset signal
always @(posedge clk_i) begin
	if (mem_ready_s) begin
		rst_bubble_r <= rst_bubble_s;
	end
end

// Calculate address of next instruction
assign next_instr_addr_s = instr_addr_r + 32'd4;

// Multiplexer for selection of input for the program counter
assign instr_addr_s = (instr_addr_src_s == 1'd0) ? next_instr_addr_s : jmp_addr_mem_r;

// Program counter
always @(posedge clk_i) begin
	if(rst_i == 1'd0) begin
		instr_addr_r <= 32'd0;	
	end else if (mem_ready_s && hazard_nop_s==1'b0) begin
		instr_addr_r <= instr_addr_s;
	end
end

// Instruction memory IOs
assign instr_mem_addr_o = instr_addr_r;
assign instr_mem_rd_o   = rst_i & data_mem_ready_i;
assign instruction_s    = instr_mem_data_i;

// IF-ID pipeline register
always @(posedge clk_i) begin
	if (rst_i == 1'd0) begin
    	instr_addr_id_r <= 32'd0;
		instr_id_r      <= 32'd0;
	end else if (mem_ready_s && hazard_nop_s==1'b0) begin
		instr_addr_id_r <= instr_addr_r;
		instr_id_r      <= instruction_s;
	end
end


/******************************************************************************
* Instruction Decode (ID) Pipeline Section
******************************************************************************/

// Register file
register_file inst_register_file(
	.clk_i(clk_i),
	.rst_i(rst_i),
	.stall_i(mem_ready_s),
	
	.reg_write_i(reg_write_wb_r),
    .write_addr_i(rd_addr_wb_r),
	.data_i(reg_data_i_s),

    .rs1_addr_i(instr_id_r[19:15]),
	.rs1_data_o(rs1_data_s),
	
    .rs2_addr_i(instr_id_r[24:20]),
	.rs2_data_o(rs2_data_s)
);

// Control unit
control_unit inst_control_unit(
    .op_i(instr_id_r[6:0]),
    
    .alu_op_o(alu_op_s),
    .imm_select_o(imm_select_s),
    .alu_pc_o(alu_pc_s),
    .alu_src_o(alu_src_s),
    .reg_write_o(reg_write_s),
    .mem_rd_o(mem_read_s),
    .mem_wr_o(mem_write_s),
    .mem_to_reg_o(mem_to_reg_s),
    .branch_o(branch_s),
    .add_sum_reg_o(jmp_addr_op1_sel_s)
);

// Selector for the bits that form the immediate value
assign tmp_immediate_s = instr_id_r[31:7];
always @(*) begin
  	case(imm_select_s)
        // I immediate
  		3'b000 : immediate_s = {{20{tmp_immediate_s[24]}},tmp_immediate_s[24:13]};	
        // S immediate
	  	3'b001 : immediate_s = {{20{tmp_immediate_s[24]}},tmp_immediate_s[24:18],tmp_immediate_s[4:0]};
        // SB immediate
	  	3'b010 : immediate_s = {{20{tmp_immediate_s[24]}},tmp_immediate_s[24],tmp_immediate_s[0],tmp_immediate_s[23:18],tmp_immediate_s[4:1]};
        // U immediate
        3'b011 : immediate_s = {{tmp_immediate_s[24:5]},12'd0};
        // UJ immediate
	  	3'b100 : immediate_s = {{12{tmp_immediate_s[24]}},tmp_immediate_s[24],tmp_immediate_s[12:5],tmp_immediate_s[13],tmp_immediate_s[23:14]};
        default : immediate_s = 32'd0;
	endcase
end

// Hazard detection
always @(*) begin
	hazard_nop_s = 1'b0;
	// If read from data memory
	if (mem_read_ex_r == 1'b1) begin
		// If destination register is one that must be read now
		if (inst_ex_r[11:7] == instr_id_r[19:15] ||
			inst_ex_r[11:7] == instr_id_r[24:20]) begin
			// Insert NOP
			hazard_nop_s = 1'b1;
		end
	end
end


// ID-EX pipeline register
always @(posedge clk_i) begin
	if ((rst_bubble_s & rst_bubble_r & rst_i) == 1'd0 ||
		(hazard_nop_s == 1'b1 && mem_ready_s == 1'b1)) begin
		inst_ex_r       <= 25'd0;
		instr_addr_ex_r <= 32'd0;
		rs1_data_ex_r   <= 32'd0;
		rs2_data_ex_r   <= 32'd0;
		immediate_ex_r  <= 32'd0;
		reg_write_ex_r  <= 1'd0;
		mem_to_reg_ex_r <= 1'd0;
		mem_read_ex_r   <= 1'd0;
		mem_write_ex_r  <= 1'd0;
		alu_op_ex_r     <= 4'd0;
		alu_src_ex_r    <= 1'd0;
		jmp_addr_op1_sel_ex_r <= 1'd0;
		alu_pc_ex_r     <= 1'd0;
		branch_ex_r     <= 1'd0;
	end else if (mem_ready_s) begin
		inst_ex_r       <= instr_id_r[31:7];
		instr_addr_ex_r <= instr_addr_id_r;
		rs1_data_ex_r   <= rs1_data_s;
		rs2_data_ex_r   <= rs2_data_s;
		immediate_ex_r  <= immediate_s;
		reg_write_ex_r  <= reg_write_s;
		mem_to_reg_ex_r <= mem_to_reg_s;
		mem_read_ex_r   <= mem_read_s;
		mem_write_ex_r  <= mem_write_s;
		alu_op_ex_r     <= alu_op_s;
		alu_src_ex_r    <= alu_src_s;
		jmp_addr_op1_sel_ex_r <= jmp_addr_op1_sel_s;
		alu_pc_ex_r     <= alu_pc_s;
		branch_ex_r     <= branch_s;
	end
end


/******************************************************************************
* Execute (EX) Pipeline Section
******************************************************************************/

// Multiplexer to select the input of the adder for the target address of a jump
assign op1_jump_addr_s = (jmp_addr_op1_sel_ex_r == 1'd0) ? instr_addr_ex_r : rs1_data_ex_r;

// Adder to calculate the target address of a jump
assign jmp_addr_s = op1_jump_addr_s + {immediate_ex_r[30:0], 1'd0};

// Multiplexer to select the operant 1 of the ALU
always @(*) begin
	if (alu_pc_ex_r == 1'd0) begin
        // Operand from register file
        case (forward_op1_sel_s)
            // No forwarding
            2'b00 : op1_alu_s = rs1_data_ex_r;
            // Forwarding from EX-MEM register
            2'b01 : op1_alu_s = alu_result_mem_r;
            // Forwarding from MEM-WB register
            2'b10 : op1_alu_s = reg_data_i_s;
            default : op1_alu_s = rs1_data_ex_r;
        endcase
	end else begin
		// Operand is the instruction address
		op1_alu_s = instr_addr_ex_r;
	end
end

// Multiplexer to select the operant 2 of the ALU
always @(*) begin
	if (alu_src_ex_r == 1'd0) begin
        // Operand from register file
        case (forward_op2_sel_s)
            // No forwarding
            2'b00 : op2_alu_s = rs2_data_ex_r;
            // Forwarding from EX-MEM register
            2'b01 : op2_alu_s = alu_result_mem_r;
            // Forwarding from MEM-WB register
            2'b10 : op2_alu_s = reg_data_i_s;
            default : op2_alu_s = rs2_data_ex_r;
        endcase
	end else begin
		// Operand is an immediate value
		op2_alu_s = immediate_ex_r;
	end
end

// Arithmetic logic unit
alu inst_alu(
	.op1_i(op1_alu_s), 
	.op2_i(op2_alu_s), 
	.alu_ctrl_i(alu_ctrl_s), 
	
	.data_o(alu_result_s),
	.Zero_o(zero_s)
);

// Control unit for the ALU
alu_control_unit inst_alu_control_unit(
	.alu_op_i(alu_op_ex_r),
	.funct_3_i(inst_ex_r[14:12]),
	.funct_7_i(inst_ex_r[31:25]),
	
	.alu_ctrl_o(alu_ctrl_s)
);

// EX-MEM pipeline register
always @(posedge clk_i) begin
	if((rst_bubble_s & rst_i) == 1'd0) begin
		alu_result_mem_r <= 32'd0;
		rs2_data_mem_r   <= 32'd0;
		mem_read_mem_r   <= 1'd0;
		mem_write_mem_r  <= 1'd0;
		zero_mem_r       <= 1'd0;
		rd_addr_mem_r    <= 5'd0;
		reg_write_mem_r  <= 1'd0;
		mem_to_reg_mem_r <= 1'd0;
		jmp_addr_mem_r   <= 32'd0;
		branch_mem_r     <= 1'd0;
		funct_3_mem_r    <= 3'd0;
  	end else if (mem_ready_s) begin
		alu_result_mem_r <= alu_result_s;
		rs2_data_mem_r   <= rs2_data_ex_r;
		mem_read_mem_r   <= mem_read_ex_r;
		mem_write_mem_r  <= mem_write_ex_r;
		zero_mem_r       <= zero_s;
		rd_addr_mem_r    <= inst_ex_r[11:7];
		reg_write_mem_r  <= reg_write_ex_r;
		mem_to_reg_mem_r <= mem_to_reg_ex_r;
		jmp_addr_mem_r   <= jmp_addr_s;
		branch_mem_r     <= branch_ex_r;
		funct_3_mem_r    <= inst_ex_r[14:12];
  	end
end

// Forwarding unit
always @(*) begin
    if (reg_write_mem_r && (rd_addr_mem_r != 5'd0) && (rd_addr_mem_r == inst_ex_r[19:15])) begin
        // Forwarding of op1 from EX-MEM register
        forward_op1_sel_s = 2'b01;	
    end else if (reg_write_wb_r && (rd_addr_wb_r != 5'd0) && rd_addr_wb_r == inst_ex_r[19:15])  begin
        // Forwarding of op1 from MEM-WB register
        forward_op1_sel_s = 2'b10;		
    end else begin
        // Default output, no forwarding of op1
        forward_op1_sel_s = 2'b00;
    end
	
    if (reg_write_mem_r && (rd_addr_mem_r != 5'd0) && (rd_addr_mem_r == inst_ex_r[24:20])) begin
        // Forwarding of op2 from EX-MEM register
        forward_op2_sel_s = 2'b01;	
    end else if (reg_write_wb_r && (rd_addr_wb_r != 5'd0) && rd_addr_wb_r == inst_ex_r[24:20]) begin
        // Forwarding of op2 from MEM-WB register
        forward_op2_sel_s = 2'b10;		
    end else begin
        // Default output, no forwarding of op2
        forward_op2_sel_s = 2'b00;
    end
end
 
 
/******************************************************************************
* Memory (MEM) Pipeline Section
******************************************************************************/

byte_operation_unit byte_operation_unit(
    .funct_3_i(funct_3_mem_r),
	.addr_i(alu_result_mem_r[1:0]),
	.mem_read_i(mem_read_mem_r),
	.mem_write_i(mem_write_mem_r),
	.data_to_mem_i(rs2_data_mem_r),
	.data_from_mem_i(data_mem_data_i),
    
    .data_to_mem_o(data_mem_data_o),
	.data_from_mem_o(data_mem_o),
	.byte_select_o(byte_select_o)
);

// Data memory IOs
assign data_mem_addr_o = alu_result_mem_r;
//assign data_mem_data_o = rs2_data_mem_r;
assign data_mem_rd_o   = mem_read_mem_r;
assign data_mem_wr_o   = mem_write_mem_r;
//assign data_mem_o      = data_mem_data_i;

// Signal to select the imput of the program counter
assign instr_addr_src_s = branch_mem_r & zero_mem_r;

// MEM-WB pipeline register
always @(posedge clk_i) begin
	if(rst_i == 1'd0) begin
		data_mem_o_wb_r <= 32'd0;
		alu_result_wb_r <= 32'd0;
		rd_addr_wb_r    <= 5'd0;
		reg_write_wb_r  <= 1'd0;
		mem_to_reg_wb_r <= 1'd0;
  	end else if (mem_ready_s) begin
		data_mem_o_wb_r <= data_mem_o;
		alu_result_wb_r <= alu_result_mem_r;
		rd_addr_wb_r    <= rd_addr_mem_r;
		reg_write_wb_r  <= reg_write_mem_r;
		mem_to_reg_wb_r <= mem_to_reg_mem_r;	
  	end
end


/******************************************************************************
* Write-Back (WB) Pipeline Section
******************************************************************************/

//Multiplexer to select the input of the register file write port
assign reg_data_i_s = (mem_to_reg_wb_r == 1'd0) ? alu_result_wb_r : data_mem_o_wb_r;

endmodule
