include /media/marco/Data_L/EDA/openlane2/my_designs/cpu/base.mk

analyze : \
	$(WORK_DIR)/_info \
	$(WORK_DIR)/ram/_primary.dat \
	$(WORK_DIR)/ram_wrapper/_primary.dat \
	$(WORK_DIR)/cpu_top_tb/_primary.dat \


$(WORK_DIR)/_info : 
	vlib -type directory $(WORK_DIR)

$(WORK_DIR)/ram/_primary.dat : $(SRC_DIR)/testbench/ram.v
	vlog -quiet -work $(WORK_DIR) $<

$(WORK_DIR)/ram_wrapper/_primary.dat : $(SRC_DIR)/testbench/ram_wrapper.v
	vlog -quiet -work $(WORK_DIR) $<

$(WORK_DIR)/cpu_top_tb/_primary.dat : $(SRC_DIR)/testbench/cpu_top_tb.v
	vlog -quiet -work $(WORK_DIR) $<

