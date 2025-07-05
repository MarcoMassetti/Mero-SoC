# Include makefile with base constants definitions
include /media/marco/Shared/fpga/cpu/base.mk

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
	$(WORK_DIR)/ram/_primary.dat \
	$(WORK_DIR)/ram_wrapper/_primary.dat \
	$(WORK_DIR)/spi_boot_ctrl/_primary.dat \
	$(WORK_DIR)/mmu/_primary.dat \
	$(WORK_DIR)/async_fifo/_primary.dat \
	$(WORK_DIR)/sync_fifo/_primary.dat \
	$(WORK_DIR)/axi_cdc/_primary.dat \
	$(WORK_DIR)/axi_master/_primary.dat \
	$(WORK_DIR)/axi_slave/_primary.dat \
	$(WORK_DIR)/axi_interconnect/_primary.dat \
	$(WORK_DIR)/uart/_primary.dat \
	$(WORK_DIR)/axi_uart/_primary.dat \
	$(WORK_DIR)/spi_mst/_primary.dat \
	$(WORK_DIR)/axi_spi_mst/_primary.dat \
	$(WORK_DIR)/cpu_top/_primary.dat \
#$(WORK_DIR)/clk_wiz_0/_primary.dat \
#$(WORK_DIR)/mig_7series_0/_primary.dat \

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
	
$(WORK_DIR)/spi_boot_ctrl/_primary.dat : $(SRC_DIR)/design/spi_boot_ctrl.v
	vlog -quiet -work $(WORK_DIR) $<
	
$(WORK_DIR)/mmu/_primary.dat : $(SRC_DIR)/design/mmu.v
	vlog -quiet -work $(WORK_DIR) $<
	
$(WORK_DIR)/ram/_primary.dat : $(SRC_DIR)/design/ram.v
	vlog -quiet -work $(WORK_DIR) $<
	
$(WORK_DIR)/ram_wrapper/_primary.dat : $(SRC_DIR)/design/ram_wrapper.v
	vlog -quiet -work $(WORK_DIR) $<
	
$(WORK_DIR)/async_fifo/_primary.dat : $(SRC_DIR)/design/async_fifo.v
	vlog -quiet -work $(WORK_DIR) $<
	
$(WORK_DIR)/sync_fifo/_primary.dat : $(SRC_DIR)/design/sync_fifo.v
	vlog -quiet -work $(WORK_DIR) $<
	
$(WORK_DIR)/axi_cdc/_primary.dat : $(SRC_DIR)/design/axi_cdc.v
	vlog -quiet -work $(WORK_DIR) $<
	
$(WORK_DIR)/axi_master/_primary.dat : $(SRC_DIR)/design/axi_master.v
	vlog -quiet -work $(WORK_DIR) $<
	
$(WORK_DIR)/axi_slave/_primary.dat : $(SRC_DIR)/design/axi_slave.v
	vlog -quiet -work $(WORK_DIR) $<
	
$(WORK_DIR)/axi_interconnect/_primary.dat : $(SRC_DIR)/design/axi_interconnect.v
	vlog -quiet -work $(WORK_DIR) $<
	
$(WORK_DIR)/uart/_primary.dat : $(SRC_DIR)/design/uart.v
	vlog -quiet -work $(WORK_DIR) $<
	
$(WORK_DIR)/axi_uart/_primary.dat : $(SRC_DIR)/design/axi_uart.v
	vlog -quiet -work $(WORK_DIR) $<
	
$(WORK_DIR)/spi_mst/_primary.dat : $(SRC_DIR)/design/spi_mst.v
	vlog -quiet -work $(WORK_DIR) $<

$(WORK_DIR)/axi_spi_mst/_primary.dat : $(SRC_DIR)/design/axi_spi_mst.v
	vlog -quiet -work $(WORK_DIR) $<
	
#$(WORK_DIR)/clk_wiz_0/_primary.dat : $(SRC_DIR)/design/clk_wiz_0_sim_netlist.v
#	vlog -quiet -work $(WORK_DIR) $<

#$(WORK_DIR)/mig_7series_0/_primary.dat : $(SRC_DIR)/design/mig_7series_0_sim_netlist.v
#	vlog -quiet -work $(WORK_DIR) $<
	
$(WORK_DIR)/cpu_top/_primary.dat : $(SRC_DIR)/design/cpu_top.v
	vlog -quiet -work $(WORK_DIR) $<
