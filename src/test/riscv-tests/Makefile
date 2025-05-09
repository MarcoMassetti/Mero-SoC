include /media/marco/Data_L/EDA/openlane2/my_designs/cpu/base.mk

export CURRENT_DIR=$(shell pwd)


S_FILES := $(wildcard ./S/*.S)
export SOURCE_FILE_NAME ?= add

export OBJ_DIR
export TEST_DIR


batch : analyze-design analyze-testbench golden
	cd $(MODELSIM_DIR) ; vsim $(WORK_DIR).cpu_top_tb -l tc.out -quiet -batch -do $(CURRENT_DIR)/sim0.tcl -g/cpu_top_tb/inst_ram_wrapper/inst_ram/FILE_NAME=$(OBJ_DIR)/$(SOURCE_FILE_NAME).bin
	
	
gui : analyze-design analyze-testbench  golden
	cd $(MODELSIM_DIR) ; vsim $(WORK_DIR).cpu_top_tb -l tc.out -quiet -do $(CURRENT_DIR)/sim0.tcl -g/cpu_top_tb/inst_ram_wrapper/inst_ram/FILE_NAME=$(OBJ_DIR)/$(SOURCE_FILE_NAME).bin
	
	
analyze-design :
	make -f $(SRC_DIR)/design/Makefile analyze
	
analyze-testbench :
	make -f $(SRC_DIR)/testbench/Makefile analyze
	
	
golden : $(OBJ_DIR)/$(SOURCE_FILE_NAME)_rf_golden.txt

$(OBJ_DIR)/$(SOURCE_FILE_NAME)_rf_golden.txt : $(OBJ_DIR)/$(SOURCE_FILE_NAME).bin
	ripes --mode cli --proc "RV32_5S" --timeout 60000 --src $< -t bin --regs --output $@
	
$(OBJ_DIR)/$(SOURCE_FILE_NAME).bin : ./S/$(SOURCE_FILE_NAME).S ./start.S ./S/riscv_test.h ./S/test_macros.h ./Makefile
	$(ARCH)-gcc $(OPTS) ./start.S $< -o $(OBJ_DIR)/$(SOURCE_FILE_NAME).elf -DTEST_FUNC_NAME=$(SOURCE_FILE_NAME) -DTEST_FUNC_TXT='"$(SOURCE_FILE_NAME)"' -DTEST_FUNC_RET=$(SOURCE_FILE_NAME)_ret -DMY_TEST_$(SOURCE_FILE_NAME)
	$(ARCH)-objcopy $(OBJ_DIR)/$(SOURCE_FILE_NAME).elf $@ -O binary
	
golden-gui : $(OBJ_DIR)/$(SOURCE_FILE_NAME).bin
	ripes --proc "RV32_5S" --src $< -t bin

dump : $(OBJ_DIR)/$(SOURCE_FILE_NAME).elf
	$(ARCH)-objdump -d $(OBJ_DIR)/$(SOURCE_FILE_NAME).elf
	
