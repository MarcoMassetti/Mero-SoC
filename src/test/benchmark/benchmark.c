void benchmark() {
    volatile unsigned long long result = 0;
    volatile unsigned long long i, j;

    // Loop 1: Integer arithmetic
    for (i = 0; i < 100; i++) {
        result += i * 2;
    }

    // Loop 2: Bitwise operations
    volatile unsigned int bitmask = 0xAAAAAAAA;
    for (i = 0; i < 100; i++) {
        result += (i & bitmask) ^ (i | bitmask);
    }

    // Loop 3: Integer multiplication and division
    for (j = 0; j < 100; j++) {
        result += (j * 10) / 2;
    }

    // Loop 4: Memory access
    volatile unsigned int mem[1024];
    for (i = 0; i < 100; i++) {
        mem[i % 1024] = i & 0xFF;
        result += mem[i % 1024];
    }
}

int main() {
    benchmark();
    return 0;
}
