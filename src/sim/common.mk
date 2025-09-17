# Variables used during simulation
export OUTPUT_DIR
export TEST_DIR
export SRC_DIR

# Simulation directory for testcase
OUTPUT_DIR := $(subst $(SRC_DIR),$(OBJ_DIR),$(CURRENT_DIR))

ifeq ($(SIMULATOR), questasim)
#######################################################
#############  Questasim specific targets  #############
#######################################################

# Start simulation in Questasim batch mode (compile design and generate software image)
.PHONY: batch
batch : analyze $(OUTPUT_DIR)/$(TEST_NAME).txt
	cd $(OUTPUT_DIR) ; \
	vsim $(WORK_DIR).chip_top_tb -l tc.out -quiet -batch -do "run -all" \
	+SRAM_FILE_NAME=$(OUTPUT_DIR)/$(TEST_NAME).txt +VCD_ENABLE=0 +SIM_TIMEOUT_NS=$(SIM_TIMEOUT_NS)


# Start simulation in Questasim gui mode (compile design and generate software image)
.PHONY: gui
gui : analyze $(OUTPUT_DIR)/$(TEST_NAME).txt
	cd $(OUTPUT_DIR) ; \
	vsim $(WORK_DIR).chip_top_tb -l tc.out -quiet -do $(SRC_DIR)/scripts/questasim/run_gui.tcl \
	+SRAM_FILE_NAME=$(OUTPUT_DIR)/$(TEST_NAME).txt +VCD_ENABLE=0 +SIM_TIMEOUT_NS=$(SIM_TIMEOUT_NS)


# Compile design and testbench with Questasim
.PHONY: analyze
analyze :
	make -f $(SRC_DIR)/design/Makefile analyze
	make -f $(SRC_DIR)/testbench/Makefile analyze


else ifeq ($(SIMULATOR), icarus)
#######################################################
##############  Icarus specific targets  ##############
#######################################################

# Start simulation with Icarus (compile design and generate software image)
.PHONY: batch
batch : analyze $(OBJ_DIR)/chip_top_tb.vvp $(OUTPUT_DIR)/$(TEST_NAME).txt
	cd $(OUTPUT_DIR) ; \
	vvp -n -l tc.out $(OBJ_DIR)/chip_top_tb.vvp \
	+SRAM_FILE_NAME=$(OUTPUT_DIR)/$(TEST_NAME).txt +VCD_ENABLE=0 +SIM_TIMEOUT_NS=$(SIM_TIMEOUT_NS)


gui : analyze $(OBJ_DIR)/chip_top_tb.vvp $(OUTPUT_DIR)/$(TEST_NAME).txt
	cd $(OUTPUT_DIR) ; \
	vvp -n -l tc.out $(OBJ_DIR)/chip_top_tb.vvp \
	+SRAM_FILE_NAME=$(OUTPUT_DIR)/$(TEST_NAME).txt +VCD_ENABLE=1  +SIM_TIMEOUT_NS=$(SIM_TIMEOUT_NS) && \
	gtkwave dump.vcd


# Compile design and testbench with Icarus
.PHONY: analyze
analyze : $(OUTPUT_DIR) .check_sources $(OBJ_DIR)/chip_top_tb.vvp	


# Check if any of the source files has been updated
.PHONY: .check_sources
.check_sources :
	make -f $(SRC_DIR)/design/Makefile analyze
	make -f $(SRC_DIR)/testbench/Makefile analyze


# Re-compile only if any of the source files has been updated
$(OBJ_DIR)/chip_top_tb.vvp : $(SRC_DIR)/design/srclist.txt $(SRC_DIR)/testbench/srclist.txt
	iverilog -Wanachronisms -Wimplicit -Wimplicit-dimensions -Wmacro-replacement -Wportbind -Wselect-range \
	-o $(OBJ_DIR)/chip_top_tb.vvp \
	-c $(SRC_DIR)/design/srclist.txt -c $(SRC_DIR)/testbench/srclist.txt

endif

######################################################
##################  Common targets  ##################
######################################################

# Start simulation in batch mode and compare results with reference model
.PHONY: batch_ref
batch_ref : golden batch
	cd $(OUTPUT_DIR) ; \
	diff $(OUTPUT_DIR)/register_file_golden.txt $(OUTPUT_DIR)/register_file_dut.txt && \
    echo "Register-files match" \


# Calculate the expected results with the ripes simulator
.PHONY: golden
golden : $(OUTPUT_DIR)/register_file_golden.txt


# Calculate the expected results with the ripes simulator
$(OUTPUT_DIR)/register_file_golden.txt : $(OUTPUT_DIR)/$(TEST_NAME).bin
	ripes --mode cli --proc "RV32_5S" --timeout 60000 --src $< -t bin --regs --output $@


# Compile C code and produce binary file
$(OUTPUT_DIR)/$(TEST_NAME).bin : $(SOURCE_FILES) $(OUTPUT_DIR)
	$(ARCH)-gcc $(OPTS) $(CRT0) $(SOURCE_FILES) -o $(OUTPUT_DIR)/$(TEST_NAME).elf
	$(ARCH)-objcopy $(OUTPUT_DIR)/$(TEST_NAME).elf $@ -O binary


# Compile C code and produce binary file
$(OUTPUT_DIR)/$(TEST_NAME).txt : $(OUTPUT_DIR)/$(TEST_NAME).bin
	python3 $(SRC_DIR)/scripts/binary_conversion.py $< $@


# Creating simulation directory
$(OUTPUT_DIR) : $(OBJ_DIR)
	mkdir -p $(OUTPUT_DIR)


# Print content of the binary file
.PHONY: dump
dump : $(OUTPUT_DIR)/$(TEST_NAME).elf
	$(ARCH)-objdump -d $(OUTPUT_DIR)/$(TEST_NAME).elf
