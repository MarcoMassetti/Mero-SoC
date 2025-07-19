OUTPUT_FORMAT("elf32-littleriscv", "elf32-littleriscv",
	      "elf32-littleriscv")
OUTPUT_ARCH(riscv)
ENTRY(_start)

/* Define memories */
MEMORY
{
   /* Code memory (0x10000000 - 0x00ffffff) */
   CODE (rx)   : ORIGIN = 0x00000000, LENGTH = 16M
   /* Data memory (0x00000000 - 0x000007ff) */
   DATA (rwx)  : ORIGIN = 0x00000800, LENGTH = 2K
}

/* Define sections */
SECTIONS
{
  /* Define stack pointer reset value (highest ram address) */
  PROVIDE(__stack_top = 0x000007f8);
  
  /* Define .text section, containing all the executable code */
  .text : { *(.text .text.*) } > CODE
    
  /* Define .data section, containing all the initialized data */
  .data : { *(.data .data.*) } > DATA
  
  .sdata :
  {
    /* Define global pointer reset value (inside the sdata section) */
    __global_pointer = . + 0x400; 
    *(.srodata .srodata*)
    *(.sdata .sdata*)
  } > DATA

  /* Define .bss section, containing all the uninitialized data */
  __bss_start = .;
  .bss : { *(.bss .bss.*) } > DATA
}

