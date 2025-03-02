include /media/marco/Data_L/EDA/openlane2/my_designs/cpu/base.mk

analyze : \
	$(WORK_DIR)/_info \
	$(WORK_DIR)/alu_control_unit/_primary.dat \
	$(WORK_DIR)/alu/_primary.dat \
	$(WORK_DIR)/byte_operation_unit/_primary.dat \
	$(WORK_DIR)/control_unit/_primary.dat \
	$(WORK_DIR)/register_file/_primary.dat \
	$(WORK_DIR)/cpu/_primary.dat \
	$(WORK_DIR)/memory_arbiter/_primary.dat \
	$(WORK_DIR)/cpu_top/_primary.dat \


$(WORK_DIR)/_info : 
	vlib -type directory $(WORK_DIR)

$(WORK_DIR)/alu_control_unit/_primary.dat : $(SRC_DIR)/design/alu_control_unit.v
	vlog -quiet -work $(WORK_DIR) $<

$(WORK_DIR)/alu/_primary.dat : $(SRC_DIR)/design/alu.v
	vlog -quiet -work $(WORK_DIR) $<

$(WORK_DIR)/byte_operation_unit/_primary.dat : $(SRC_DIR)/design/byte_operation_unit.v
	vlog -quiet -work $(WORK_DIR) $<

$(WORK_DIR)/control_unit/_primary.dat : $(SRC_DIR)/design/control_unit.v
	vlog -quiet -work $(WORK_DIR) $<

$(WORK_DIR)/register_file/_primary.dat : $(SRC_DIR)/design/register_file.v
	vlog -quiet -work $(WORK_DIR) $<

$(WORK_DIR)/cpu/_primary.dat : $(SRC_DIR)/design/cpu.v
	vlog -quiet -work $(WORK_DIR) $<

$(WORK_DIR)/memory_arbiter/_primary.dat : $(SRC_DIR)/design/memory_arbiter.v
	vlog -quiet -work $(WORK_DIR) $<

$(WORK_DIR)/cpu_top/_primary.dat : $(SRC_DIR)/design/cpu_top.v
	vlog -quiet -work $(WORK_DIR) $<
