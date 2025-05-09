void test() {
    volatile int result = 0;
    volatile unsigned int uresult = 0;
    volatile int a = 10;
    volatile int b = 2;
    volatile unsigned int ua = 10;
    volatile unsigned int ub = 2;
    volatile int i;

    for (i = 0; i < 1000; i++) {
        result += a + b;
        uresult += ua + ub;

        result -= a - b;
        uresult -= ua - ub;

        result *= a * b;
        uresult *= ua * ub;

        if (b != 0) {
            result /= a / b;
            uresult /= ua / ub;
        }

        result %= a % b;
        uresult %= ua % ub;

        result = a << b;
        uresult = ua << ub;

        result = a >> b;
        uresult = ua >> ub;

        result = a & b;
        uresult = ua & ub;

        result = a | b;
        uresult = ua | ub;

        result = a ^ b;
        uresult = ua ^ ub;

        result = (a == b) ? 1 : 0;
        uresult = (ua == ub) ? 1 : 0;

        result = (a != b) ? 1 : 0;
        uresult = (ua != ub) ? 1 : 0;

        result = (a < b) ? 1 : 0;
        uresult = (ua < ub) ? 1 : 0;

        result = (a > b) ? 1 : 0;
        uresult = (ua > ub) ? 1 : 0;

        result = (a <= b) ? 1 : 0;
        uresult = (ua <= ub) ? 1 : 0;

        result = (a >= b) ? 1 : 0;
        uresult = (ua >= ub) ? 1 : 0;
    }
}

int main() {
    test();
    return 0;
}
