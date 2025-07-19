.section .text
.global _start
_start:

    # Initialize stack and global pointer
    .option push
    .option norelax
    la gp, __global_pointer
    la sp, __stack_top
    .option pop
    
#define TEST(n) \
	.global n; \
	addi x1, zero, 1000; \
	jal zero,n; \
	.global n ## _ret; \
	n ## _ret:

#if defined(MY_TEST_addi)
	TEST(addi)
#endif
#if defined(MY_TEST_add)
	TEST(add)
#endif
#if defined(MY_TEST_andi)
	TEST(andi)
#endif
#if defined(MY_TEST_and)
	TEST(and)
#endif
#if defined(MY_TEST_auipc)
	TEST(auipc)
#endif
#if defined(MY_TEST_beq)
	TEST(beq)
#endif
#if defined(MY_TEST_bge)
	TEST(bge)
#endif
#if defined(MY_TEST_bgeu)
	TEST(bgeu)
#endif
#if defined(MY_TEST_blt)
	TEST(blt)
#endif
#if defined(MY_TEST_bltu)
	TEST(bltu)
#endif
#if defined(MY_TEST_bne)
	TEST(bne)
#endif
#if defined(MY_TEST_jalr)
	TEST(jalr)
#endif
#if defined(MY_TEST_jal)
	TEST(jal)
#endif
#if defined(MY_TEST_j)
	TEST(j)
#endif
#if defined(MY_TEST_lb)
	TEST(lb)
#endif
#if defined(MY_TEST_lbu)
	TEST(lbu)
#endif
#if defined(MY_TEST_lh)
	TEST(lh)
#endif
#if defined(MY_TEST_lhu)
	TEST(lhu)
#endif
#if defined(MY_TEST_lui)
	TEST(lui)
#endif
#if defined(MY_TEST_lw)
	TEST(lw)
#endif
#if defined(MY_TEST_ori)
	TEST(ori)
#endif
#if defined(MY_TEST_or)
	TEST(or)
#endif
#if defined(MY_TEST_sb)
	TEST(sb)
#endif
#if defined(MY_TEST_sh)
	TEST(sh)
#endif
#if defined(MY_TEST_simple)
	TEST(simple)
#endif
#if defined(MY_TEST_slli)
	TEST(slli)
#endif
#if defined(MY_TEST_sll)
	TEST(sll)
#endif
#if defined(MY_TEST_slti)
	TEST(slti)
#endif
#if defined(MY_TEST_slt)
	TEST(slt)
#endif
#if defined(MY_TEST_srai)
	TEST(srai)
#endif
#if defined(MY_TEST_sra)
	TEST(sra)
#endif
#if defined(MY_TEST_srli)
	TEST(srli)
#endif
#if defined(MY_TEST_srl)
	TEST(srl)
#endif
#if defined(MY_TEST_sub)
	TEST(sub)
#endif
#if defined(MY_TEST_sw)
	TEST(sw)
#endif
#if defined(MY_TEST_xori)
	TEST(xori)
#endif
#if defined(MY_TEST_xor)
	TEST(xor)
#endif

    # Exit program
    li a7, 93
    ecall
    .end
