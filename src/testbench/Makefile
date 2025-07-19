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

# Incremental compilation of all verilog files of the testbench
analyze : \
	$(OBJ_DIR) \
	$(WORK_DIR)/_info \
	$(WORK_DIR)/chip_top_tb/_primary.dat \

$(WORK_DIR)/_info : 
	vlib -type directory $(WORK_DIR)

$(WORK_DIR)/chip_top_tb/_primary.dat : $(SRC_DIR)/testbench/chip_top_tb.v
	vlog -quiet -work $(WORK_DIR) $<


