#include "uart_controller.h"

// Periodically check if any character has been received
//  from UART and print it back

// Function to print a character to UART (waiting until UART fifo is not full)
void print_uart(char chr) {
	// Wait for space in uart fifo
	while(UART_STATUS_TX_FIFO_FULL_G(UART_STATUS_REGISTER));
	UART_TX_FIFO_DATA = chr;
}

int main() {
	volatile unsigned int delay_cnt;

	// Baud rate 115200
	UART_CLOCK_DIVIDER_LSB = 0x64; 
	UART_CLOCK_DIVIDER_MSB = 0x03;
   
	while (1) {
		// Check if something has been received
		if (UART_STATUS_RX_FIFO_NOT_EMPTY_G(UART_STATUS_REGISTER)) {
			// Print what has been received
			print_uart('R');
			print_uart('x');
			print_uart(':');
			print_uart(' ');
			// Continue printing until fifo is empty
			while (UART_STATUS_RX_FIFO_NOT_EMPTY_G(UART_STATUS_REGISTER)) {
				print_uart(UART_RX_FIFO_DATA & 0xff);
			}
		} else {
			// Nothing has been received
			print_uart('N');
		}
		// Go to new line
		print_uart('\r');
		print_uart('\n');

		// Delay
		for(delay_cnt=0; delay_cnt<233000; delay_cnt++);
	}
}
