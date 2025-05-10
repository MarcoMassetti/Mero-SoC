# Variables used during simulation
export OUTPUT_DIR
export TEST_DIR

# Simulation directory for testcase
OUTPUT_DIR := $(subst $(SRC_DIR),$(OBJ_DIR),$(CURRENT_DIR))

# Start simulation in batch mode
batch : analyze-design analyze-testbench golden
	cd $(OUTPUT_DIR) ; vsim $(WORK_DIR).cpu_top_tb -l tc.out -quiet -batch -do $(TEST_DIR)/common_sim.tcl -g/cpu_top_tb/inst_ram_wrapper/inst_ram/FILE_NAME=$(OUTPUT_DIR)/$(SOURCE_FILE_NAME).bin
	
# Start simulation in gui mode
gui : analyze-design analyze-testbench  golden
	cd $(OUTPUT_DIR) ; vsim $(WORK_DIR).cpu_top_tb -l tc.out -quiet -do $(TEST_DIR)/common_sim.tcl -g/cpu_top_tb/inst_ram_wrapper/inst_ram/FILE_NAME=$(OUTPUT_DIR)/$(SOURCE_FILE_NAME).bin
	
# Compile the design
analyze-design :
	make -f $(SRC_DIR)/design/Makefile analyze

# Compile the testbench
analyze-testbench :
	make -f $(SRC_DIR)/testbench/Makefile analyze
	
# Expected results dependency
golden : $(OUTPUT_DIR)/$(SOURCE_FILE_NAME)_rf_golden.txt

# Calculate the expected results with the ripes simulator
$(OUTPUT_DIR)/$(SOURCE_FILE_NAME)_rf_golden.txt : $(OUTPUT_DIR)/$(SOURCE_FILE_NAME).bin
	ripes --mode cli --proc "RV32_5S" --timeout 60000 --src $< -t bin --regs --output $@
	
# Compile C code and produce binary file
$(OUTPUT_DIR)/$(SOURCE_FILE_NAME).bin : $(SOURCE_FILE_NAME).c $(OUTPUT_DIR)
	$(ARCH)-gcc $(OPTS) $(CRT0) $< -o $(OUTPUT_DIR)/$(SOURCE_FILE_NAME).elf
	$(ARCH)-objcopy $(OUTPUT_DIR)/$(SOURCE_FILE_NAME).elf $@ -O binary

# Creating simulation directory
$(OUTPUT_DIR) : 
	mkdir -p $(OUTPUT_DIR)

# Print content of the binary file
dump : $(OUTPUT_DIR)/$(SOURCE_FILE_NAME).elf
	$(ARCH)-objdump -d $(OUTPUT_DIR)/$(SOURCE_FILE_NAME).elf





