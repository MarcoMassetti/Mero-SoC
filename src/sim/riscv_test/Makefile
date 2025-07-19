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

export CURRENT_DIR=$(shell pwd)


S_FILES := $(wildcard ./S/*.S)
export SOURCE_FILE_NAME ?= add

export OUTPUT_DIR
export TEST_DIR

# Output folder for testcase
OUTPUT_DIR := $(subst $(SRC_DIR),$(OBJ_DIR),$(CURRENT_DIR))

batch : analyze-design analyze-testbench golden $(OUTPUT_DIR)/$(SOURCE_FILE_NAME).txt
	cd $(OUTPUT_DIR) ; \
	vsim $(WORK_DIR).chip_top_tb -l tc.out -quiet -batch -do $(TEST_DIR)/common_sim.tcl -g/chip_top_tb/SRAM_FILE_NAME=$(OUTPUT_DIR)/$(SOURCE_FILE_NAME).txt
	
	
gui : analyze-design analyze-testbench  golden $(OUTPUT_DIR)/$(SOURCE_FILE_NAME).txt
	cd $(OUTPUT_DIR) ; vsim $(WORK_DIR).chip_top_tb -l tc.out -quiet        -do $(TEST_DIR)/common_sim.tcl --g/chip_top_tb/SRAM_FILE_NAME=$(OUTPUT_DIR)/$(SOURCE_FILE_NAME).txt
	
	
analyze-design :
	make -f $(SRC_DIR)/design/Makefile analyze
	
analyze-testbench :
	make -f $(SRC_DIR)/testbench/Makefile analyze
	
	
golden : $(OUTPUT_DIR)/$(SOURCE_FILE_NAME)_rf_golden.txt

$(OUTPUT_DIR)/$(SOURCE_FILE_NAME)_rf_golden.txt : $(OUTPUT_DIR)/$(SOURCE_FILE_NAME).bin
	ripes --mode cli --proc "RV32_5S" --timeout 60000 --src $< -t bin --regs --output $@
	
$(OUTPUT_DIR)/$(SOURCE_FILE_NAME).bin : ./S/$(SOURCE_FILE_NAME).S ./start.S ./S/riscv_test.h ./S/test_macros.h ./Makefile $(OUTPUT_DIR)
	$(ARCH)-gcc $(OPTS) ./start.S $< -o $(OUTPUT_DIR)/$(SOURCE_FILE_NAME).elf -DTEST_FUNC_NAME=$(SOURCE_FILE_NAME) -DTEST_FUNC_TXT='"$(SOURCE_FILE_NAME)"' -DTEST_FUNC_RET=$(SOURCE_FILE_NAME)_ret -DMY_TEST_$(SOURCE_FILE_NAME)
	$(ARCH)-objcopy $(OUTPUT_DIR)/$(SOURCE_FILE_NAME).elf $@ -O binary
	
# Compile C code and produce binary file
$(OUTPUT_DIR)/$(SOURCE_FILE_NAME).txt : $(OUTPUT_DIR)/$(SOURCE_FILE_NAME).bin
	python3 $(SRC_DIR)/scripts/binary_conversion.py $< $@
	
$(OUTPUT_DIR) : 
	mkdir -p $(OUTPUT_DIR)

dump : $(OUTPUT_DIR)/$(SOURCE_FILE_NAME).elf
	$(ARCH)-objdump -d $(OUTPUT_DIR)/$(SOURCE_FILE_NAME).elf
	
