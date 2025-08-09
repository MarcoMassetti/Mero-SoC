#include "cpu_interface_controller.h"
#include "uart_controller.h"

// Copy executable code from external flash to internal
//   ram while printing uart messages

// Function to print a character to UART (waiting until UART fifo is not full)
void print_uart(char chr) {
	// Wait for space in uart fifo
	while(UART_STATUS_TX_FIFO_FULL_G(UART_STATUS_REGISTER));
	UART_TX_FIFO_DATA = chr;
}

int main() {
	volatile unsigned int delay_cnt;
    unsigned char i;
	
	// Baud rate 115200
	UART_CLOCK_DIVIDER_LSB = 0x64;
	UART_CLOCK_DIVIDER_MSB = 0x03;

    // Print messages before copying code to ram
    for(i=0; i<10; i++) {
        print_uart('F');
		print_uart('L');
		print_uart('A');
		print_uart('S');
		print_uart('H');
		print_uart('\r');
		print_uart('\n');
        for(delay_cnt=0; delay_cnt<23300; delay_cnt++);
    }

    // Flash address from where to start copying
    CPU_INTERFACE_START_ADDRESS = 0x0;
    // Flash address where to end copying
    CPU_INTERFACE_STOP_ADDRESS =  0x200;
    // Start copy operation (from flash to sram)
    //CPU_INTERFACE_CONTROL_REGISTER = CPU_INTERFACE_CONTROL_START_COPY_M;
	// Start copy operation (from flash to dram)
    CPU_INTERFACE_CONTROL_REGISTER = CPU_INTERFACE_CONTROL_START_COPY_M | CPU_INTERFACE_CONTROL_DEST_S(1);

    // Processor is stopped until copy is ended

    // Print messages after copying code to ram
	while (1) {
		print_uart('R');
		print_uart('A');
		print_uart('M');
		print_uart('\r');
		print_uart('\n');
	    for(delay_cnt=0; delay_cnt<23300; delay_cnt++);
	}
}
