# Find top directory of the project
export TOP_DIR := $(shell \
  d=$$(pwd); \
  while [ "$$d" != "/" ] && [ ! -e "$$d/base.mk" ]; do \
    d=$$(dirname "$$d"); \
  done; \
  if [ -n "$$d" ] && [ -e "$$d/base.mk" ]; then echo "$$d"; else echo "."; fi \
)

# Include makefile with base constants definitions
include $(TOP_DIR)/base.mk

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
	$(WORK_DIR)/cpu_interface_ctrl/_primary.dat \
	$(WORK_DIR)/axi_cpu_interface_ctrl/_primary.dat \
	$(WORK_DIR)/sky130_sram_2kbyte_1rw_32x512_8/_primary.dat \
	$(WORK_DIR)/async_fifo/_primary.dat \
	$(WORK_DIR)/sync_fifo/_primary.dat \
	$(WORK_DIR)/axi_ram_wrapper/_primary.dat \
	$(WORK_DIR)/axi_cdc/_primary.dat \
	$(WORK_DIR)/hs_2_axi/_primary.dat \
	$(WORK_DIR)/axi_2_hs/_primary.dat \
	$(WORK_DIR)/axi_interconnect/_primary.dat \
	$(WORK_DIR)/uart_ctrl/_primary.dat \
	$(WORK_DIR)/axi_uart_ctrl/_primary.dat \
	$(WORK_DIR)/spi_mst/_primary.dat \
	$(WORK_DIR)/axi_spi_mst/_primary.dat \
	$(WORK_DIR)/spi_boot_ctrl/_primary.dat \
	$(WORK_DIR)/chip_top/_primary.dat \

$(WORK_DIR)/_info : 
	vlib -type directory $(WORK_DIR)

$(WORK_DIR)/alu_control_unit/_primary.dat : $(SRC_DIR)/design/cpu/alu_control_unit.v
	vlog -quiet -work $(WORK_DIR) $<

$(WORK_DIR)/alu/_primary.dat : $(SRC_DIR)/design/cpu/alu.v
	vlog -quiet -work $(WORK_DIR) $<

$(WORK_DIR)/byte_operation_unit/_primary.dat : $(SRC_DIR)/design/cpu/byte_operation_unit.v
	vlog -quiet -work $(WORK_DIR) $<

$(WORK_DIR)/control_unit/_primary.dat : $(SRC_DIR)/design/cpu/control_unit.v
	vlog -quiet -work $(WORK_DIR) $<

$(WORK_DIR)/register_file/_primary.dat : $(SRC_DIR)/design/cpu/register_file.v
	vlog -quiet -work $(WORK_DIR) $<

$(WORK_DIR)/cpu/_primary.dat : $(SRC_DIR)/design/cpu/cpu.v
	vlog -quiet -work $(WORK_DIR) $<
	
$(WORK_DIR)/cpu_interface_ctrl/_primary.dat : $(SRC_DIR)/design/cpu/cpu_interface_ctrl.v
	vlog -quiet -work $(WORK_DIR) $<
	
$(WORK_DIR)/axi_cpu_interface_ctrl/_primary.dat : $(SRC_DIR)/design/cpu/axi_cpu_interface_ctrl.v
	vlog -quiet -work $(WORK_DIR) $<
	
$(WORK_DIR)/sky130_sram_2kbyte_1rw_32x512_8/_primary.dat : $(SRC_DIR)/design/ram_macro/sky130_sram_2kbyte_1rw_32x512_8.v
	vlog -quiet -work $(WORK_DIR) $< +define+FPGA
	
$(WORK_DIR)/async_fifo/_primary.dat : $(SRC_DIR)/design/fifos/async_fifo.v
	vlog -quiet -work $(WORK_DIR) $<
	
$(WORK_DIR)/sync_fifo/_primary.dat : $(SRC_DIR)/design/fifos/sync_fifo.v
	vlog -quiet -work $(WORK_DIR) $<
	
$(WORK_DIR)/axi_ram_wrapper/_primary.dat : $(SRC_DIR)/design/axi_blocks/axi_ram_wrapper.v
	vlog -quiet -work $(WORK_DIR) $<
	
$(WORK_DIR)/axi_cdc/_primary.dat : $(SRC_DIR)/design/axi_blocks/axi_cdc.v
	vlog -quiet -work $(WORK_DIR) $<
	
$(WORK_DIR)/hs_2_axi/_primary.dat : $(SRC_DIR)/design/axi_blocks/hs_2_axi.v
	vlog -quiet -work $(WORK_DIR) $<
	
$(WORK_DIR)/axi_2_hs/_primary.dat : $(SRC_DIR)/design/axi_blocks/axi_2_hs.v
	vlog -quiet -work $(WORK_DIR) $<
	
$(WORK_DIR)/axi_interconnect/_primary.dat : $(SRC_DIR)/design/axi_blocks/axi_interconnect.v
	vlog -quiet -work $(WORK_DIR) $<
	
$(WORK_DIR)/uart_ctrl/_primary.dat : $(SRC_DIR)/design/uart_ctrl/uart_ctrl.v
	vlog -quiet -work $(WORK_DIR) $<
	
$(WORK_DIR)/axi_uart_ctrl/_primary.dat : $(SRC_DIR)/design/uart_ctrl/axi_uart_ctrl.v
	vlog -quiet -work $(WORK_DIR) $<
	
$(WORK_DIR)/spi_mst/_primary.dat : $(SRC_DIR)/design/spi_ctrl/spi_mst.v
	vlog -quiet -work $(WORK_DIR) $<

$(WORK_DIR)/axi_spi_mst/_primary.dat : $(SRC_DIR)/design/spi_ctrl/axi_spi_mst.v
	vlog -quiet -work $(WORK_DIR) $<
	
$(WORK_DIR)/spi_boot_ctrl/_primary.dat : $(SRC_DIR)/design/spi_ctrl/spi_boot_ctrl.v
	vlog -quiet -work $(WORK_DIR) $<
	
$(WORK_DIR)/chip_top/_primary.dat : $(SRC_DIR)/design/chip_top.v
	vlog -quiet -work $(WORK_DIR) $<
