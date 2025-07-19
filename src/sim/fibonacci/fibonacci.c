// Calculate Fibonacci sequence up to the Nth number
#define N 25

// Function to calculate the nth Fibonacci number
int fibonacci(int n) {
    if (n <= 1) {
        return n;
    }
    int a = 0;
    int b = 1;
    int result = 0;
    for (int i = 2; i <= n; i++) {
        result = a + b;
        a = b;
        b = result;
    }
    return result;
}

// Function to calculate the Fibonacci sequence up to the nth number
void calculate_fibonacci_sequence(int n, int* sequence) {
    for (int i = 0; i <= n; i++) {
        sequence[i] = fibonacci(i);
    }
}



int main() {
    int sequence[N + 1];
    calculate_fibonacci_sequence(N, sequence);

    return 0;
}
