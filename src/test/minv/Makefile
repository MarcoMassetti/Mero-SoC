include /media/marco/Data_L/EDA/openlane2/my_designs/cpu/base.mk

export CURRENT_DIR=$(shell pwd)
export OBJ_DIR

SOURCE_FILE_NAME=minv


batch : analyze-design analyze-testbench golden
	cd $(MODELSIM_DIR) ; vsim $(WORK_DIR).cpu_top_tb -l tc.out -quiet -batch -do $(CURRENT_DIR)/sim0.tcl
	
	
gui : analyze-design analyze-testbench  golden
	cd $(MODELSIM_DIR) ; vsim $(WORK_DIR).cpu_top_tb -l tc.out -quiet -do $(CURRENT_DIR)/sim0.tcl
	
	
analyze-design :
	make -f $(SRC_DIR)/design/Makefile analyze
	
analyze-testbench :
	make -f $(SRC_DIR)/testbench/Makefile analyze
	
	
golden : $(OBJ_DIR)/rf_golden.txt

$(OBJ_DIR)/rf_golden.txt : $(OBJ_DIR)/$(SOURCE_FILE_NAME).bin
	ripes --mode cli --proc "RV32_5S" --timeout 60000 --src $< -t bin --regs --output $@
	
$(OBJ_DIR)/$(SOURCE_FILE_NAME).bin : $(SOURCE_FILE_NAME).c
	$(ARCH)-gcc $(OPTS) $(CRT0) $< -o $(OBJ_DIR)/$(SOURCE_FILE_NAME).elf
	$(ARCH)-objcopy $(OBJ_DIR)/$(SOURCE_FILE_NAME).elf $@ -O binary
	







