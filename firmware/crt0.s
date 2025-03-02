.section .text
.global _start
_start:
    .option push
    .option norelax
    la gp, __global_pointer
    la sp, __stack_top
    .option pop
    jal ra, main
    
el:
    j el
    .end
