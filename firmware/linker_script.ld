OUTPUT_FORMAT("elf32-littleriscv", "elf32-littleriscv",
	      "elf32-littleriscv")
OUTPUT_ARCH(riscv)
ENTRY(_start)

/* Define memories */
MEMORY
{
   /* Code memory */
   CODE (rx)   : ORIGIN = 0x00000000, LENGTH = 64k
   /* Data memory */
   DATA (rwx)  : ORIGIN = 0x00010000, LENGTH = 64k
}

/* Define sections */
SECTIONS
{
  /* Define stack pointer reset value (highest ram address) */
  PROVIDE(__stack_top = 0x0001fff8);
  
  /* Define .text section, containing all the executable code */
  .text : { *(.text .text.*) } > CODE
    
  /* Define .data section, containing all the initialized data */
  .data : { *(.data .data.*) } > DATA
  
  .sdata :
  {
    /* Define global pointer reset value (inside the sdata section) */
    __global_pointer = . + 0x800; 
    *(.srodata .srodata*)
    *(.sdata .sdata*)
  } > DATA

  /* Define .bss section, containing all the uninitialized data */
  __bss_start = .;
  .bss : { *(.bss .bss.*) } > DATA
}

