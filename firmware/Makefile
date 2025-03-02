RISCV_PATH=
ARCH=riscv32-unknown-elf
CC=$(RISCV_PATH)$(ARCH)-gcc

OPTS=-march=rv32i -mabi=ilp32 -ffreestanding -O3 -Wl,--gc-sections -nostartfiles -nodefaultlibs

LINKER_SCRIPT=linker_script.ld
LINKER_SCRIPT_OPT=-T linker_script.ld
CRT0=crt0.s

all : main.elf

clean :
	rm -f main.elf
	
main.elf : main.c $(LINKER_SCRIPT) $(CRT0)
	$(CC) $(OPTS) $(LINKER_SCRIPT_OPT) $(CRT0) main.c -o $@
