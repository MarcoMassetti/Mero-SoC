# Variables used during simulation
export OUTPUT_DIR
export TEST_DIR
export SRC_DIR

# Simulation directory for testcase
OUTPUT_DIR := $(subst $(SRC_DIR),$(OBJ_DIR),$(CURRENT_DIR))

ifeq ($(SIMULATOR), modelsim)
# Simulation startup for modelsim
# Start simulation in batch mode
batch : analyze-design analyze-testbench $(OUTPUT_DIR)/$(SOURCE_FILE_NAME).txt
	cd $(OUTPUT_DIR) ; \
	vsim $(WORK_DIR).chip_top_tb -l tc.out -quiet -batch -do $(TEST_DIR)/common_sim.tcl -g/chip_top_tb/SRAM_FILE_NAME=$(OUTPUT_DIR)/$(SOURCE_FILE_NAME).txt
	
# Start simulation in gui mode
gui : analyze-design analyze-testbench $(OUTPUT_DIR)/$(SOURCE_FILE_NAME).txt
	cd $(OUTPUT_DIR) ; \
	vsim $(WORK_DIR).chip_top_tb -l tc.out -quiet -do $(TEST_DIR)/common_sim.tcl -g/chip_top_tb/SRAM_FILE_NAME=$(OUTPUT_DIR)/$(SOURCE_FILE_NAME).txt
	
# Start simulation in batch mode and compare results with reference model
batch_ref : golden batch
	
# Start simulation in gui mode and compare results with reference model
gui_ref : golden gui

	
else ifeq ($(SIMULATOR), icarus)
# Simulation startup for icarus
batch :
	iverilog -Wall -o $(OBJ_DIR)/chip_top_tb.vvp -c $(TEST_DIR)/srclist.txt -DFILE_NAME="ram.v"
	#cd $(OUTPUT_DIR) ; vvp -n -l tc.out $(OBJ_DIR)/chip_top_tb.vvp
endif

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
	
# Compile C code and produce binary file
$(OUTPUT_DIR)/$(SOURCE_FILE_NAME).txt : $(OUTPUT_DIR)/$(SOURCE_FILE_NAME).bin
	python3 $(SRC_DIR)/scripts/binary_conversion.py $< $@

# Creating simulation directory
$(OUTPUT_DIR) : 
	mkdir -p $(OUTPUT_DIR)

# Print content of the binary file
dump : $(OUTPUT_DIR)/$(SOURCE_FILE_NAME).elf
	$(ARCH)-objdump -d $(OUTPUT_DIR)/$(SOURCE_FILE_NAME).elf





