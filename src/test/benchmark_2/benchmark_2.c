volatile unsigned int add(volatile unsigned int a, volatile unsigned int b) {
    return a + b;
}

void branch_test(volatile unsigned int *result) {
    volatile unsigned int i;
    for (i = 0; i < 10000; i++) {
        if (i & 1) {
            *result += i;
        } else {
            *result -= i;
        }
    }
}

void function_call_test(volatile unsigned int *result) {
    volatile unsigned int i;
    for (i = 0; i < 10000; i++) {
        *result += add(i, i);
    }
}

void memory_access_test(volatile unsigned int *result, volatile unsigned int *mem) {
    volatile unsigned int i;
    for (i = 0; i < 10000; i++) {
        mem[i % 1024] = i;
        *result += mem[i % 1024];
    }
}

void cache_test(volatile unsigned int *result, volatile unsigned int *mem) {
    volatile unsigned int i;
    for (i = 0; i < 10000; i++) {
        mem[i % 16] = i; // Access small cache line
        *result += mem[i % 16];
    }
}

void main() {
    volatile unsigned int result = 0;
    volatile unsigned int mem[1024];

    branch_test(&result);
    function_call_test(&result);
    memory_access_test(&result, mem);
    cache_test(&result, mem);
}
