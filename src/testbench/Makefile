# Include makefile with base constants definitions
include /media/marco/Data_L/EDA/openlane2/my_designs/cpu/base.mk

# Incremental compilation of all verilog files of the testbench
analyze : \
	$(OBJ_DIR) \
	$(WORK_DIR)/_info \
	$(WORK_DIR)/cpu_top_tb/_primary.dat \


$(WORK_DIR)/_info : 
	vlib -type directory $(WORK_DIR)

$(WORK_DIR)/cpu_top_tb/_primary.dat : $(SRC_DIR)/testbench/cpu_top_tb.v
	vlog -quiet -work $(WORK_DIR) $<


