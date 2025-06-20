# Include makefile with base constants definitions
include /media/marco/Shared/fpga/cpu/base.mk

# Incremental compilation of all verilog files of the testbench
analyze : \
	$(OBJ_DIR) \
	$(WORK_DIR)/_info \
	$(WORK_DIR)/ddr3_model/_primary.dat \
	$(WORK_DIR)/cpu_top_tb/_primary.dat \


$(WORK_DIR)/_info : 
	vlib -type directory $(WORK_DIR)
	
$(WORK_DIR)/ddr3_model/_primary.dat : $(SRC_DIR)/testbench/ddr3_model.sv
	vlog -sv -suppress 2083 -quiet -work $(WORK_DIR) $(SRC_DIR)/testbench/ddr3_model_parameters.vh
	vlog -suppress 2083 -quiet -work $(WORK_DIR) $<

$(WORK_DIR)/cpu_top_tb/_primary.dat : $(SRC_DIR)/testbench/cpu_top_tb.v
	vlog -quiet -work $(WORK_DIR) $<


