TOP_DIR=/media/marco/Data_L/EDA/openlane2/my_designs/cpu
SRC_DIR=$(TOP_DIR)/src
OBJ_DIR=$(TOP_DIR)/obj
TEST_DIR=$(SRC_DIR)/test
MODELSIM_DIR=$(OBJ_DIR)/modelsim
WORK_DIR=$(OBJ_DIR)/modelsim/work


ARCH=riscv32-unknown-elf
LINKER_SCRIPT=$(SRC_DIR)/firmware/linker_script.ld
CRT0=$(SRC_DIR)/firmware/crt0.s
OPTS=-march=rv32i -mabi=ilp32 -ffreestanding -O3 -Wl,--gc-sections -nostartfiles -T $(LINKER_SCRIPT)

clean :
	rm -rf $(OBJ_DIR)/*

# Check for all necessary programs and create the obj directory
$(OBJ_DIR) :
# Check for risc-v toolchain
	@if ! which $(ARCH)-gcc > /dev/null 2>&1; then \
		echo "RISC-V toolchain: MISSING"; \
		exit 1; \
	else \
		echo "RISC-V toolchain: OK"; \
	fi
# Check for ripes
	@if ! which ripes > /dev/null 2>&1; then \
		echo "Ripes: MISSING"; \
		exit 1; \
	else \
		echo "Ripes: OK"; \
	fi
# Check for modelsim
	@if ! which vsim > /dev/null 2>&1; then \
		echo "Modelsim: MISSING"; \
		exit 1; \
	else \
		echo "Modelsim: OK"; \
	fi
# Create obj directory
	@if ! mkdir -p $(OBJ_DIR) > /dev/null 2>&1; then \
		echo "Failed to create folder $(OBJ_DIR)"; \
		exit 1; \
	else \
		echo "Folder $(OBJ_DIR) created successfully"; \
		echo "All prerequisites met"; \
	fi
