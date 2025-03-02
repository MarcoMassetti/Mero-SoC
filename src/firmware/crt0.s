.section .text
.global _start
_start:

    # Initialize stack and global pointer
    .option push
    .option norelax
    la gp, __global_pointer
    la sp, __stack_top
    .option pop
    
    # Go to main
    jal ra, main
    
    # Exit program
    li a7, 10
    ecall
    .end
