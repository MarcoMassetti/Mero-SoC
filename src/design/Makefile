# Include makefile with base constants definitions
include /media/marco/Data_L/EDA/openlane2/my_designs/cpu/base.mk

# Incremental compilation of all verilog files of the design
analyze : \
	$(OBJ_DIR) \
	$(WORK_DIR)/_info \
	$(WORK_DIR)/alu_control_unit/_primary.dat \
	$(WORK_DIR)/alu/_primary.dat \
	$(WORK_DIR)/byte_operation_unit/_primary.dat \
	$(WORK_DIR)/control_unit/_primary.dat \
	$(WORK_DIR)/register_file/_primary.dat \
	$(WORK_DIR)/cpu/_primary.dat \
	$(WORK_DIR)/memory_arbiter/_primary.dat \
	$(WORK_DIR)/ram/_primary.dat \
	$(WORK_DIR)/ram_wrapper/_primary.dat \
	$(WORK_DIR)/axi_master/_primary.dat \
	$(WORK_DIR)/axi_uartlite_0_sim_netlist/_primary.dat \
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
	
$(WORK_DIR)/ram/_primary.dat : $(SRC_DIR)/design/ram.v
	vlog -quiet -work $(WORK_DIR) $<
	
$(WORK_DIR)/ram_wrapper/_primary.dat : $(SRC_DIR)/design/ram_wrapper.v
	vlog -quiet -work $(WORK_DIR) $<
	
$(WORK_DIR)/axi_master/_primary.dat : $(SRC_DIR)/design/axi_master.v
	vlog -quiet -work $(WORK_DIR) $<

$(WORK_DIR)/axi_uartlite_0_sim_netlist/_primary.dat : $(SRC_DIR)/design/axi_uartlite_0_sim_netlist.v
	vlog -quiet -work $(WORK_DIR) $<

$(WORK_DIR)/cpu_top/_primary.dat : $(SRC_DIR)/design/cpu_top.v
	vlog -quiet -work $(WORK_DIR) $<
