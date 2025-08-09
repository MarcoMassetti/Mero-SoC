#include "uart_controller.h"
#include "spi_master.h"

// Read 4-bytes at a time from SPI flash and print
//  them on the UART terminal

// Function to convert a number (0-15) to its corresponding ascii character
char hex_to_ascii(unsigned int hex) {
    if (hex < 10) {
        return '0' + hex;
    } else {
        return 'a' + (hex - 10);
    }
}

// Function to print a character to UART (waiting until UART fifo is not full)
void print_uart(char chr) {
	// Wait for space in uart fifo
	while(UART_STATUS_TX_FIFO_FULL_G(UART_STATUS_REGISTER));
	UART_TX_FIFO_DATA = chr;
}

int main() {
	volatile unsigned int addr;
	volatile unsigned int read_value;
	
	volatile unsigned int delay_cnt;
	char i;
	
	// Baud rate 115200
	UART_CLOCK_DIVIDER_LSB = 0x64;
	UART_CLOCK_DIVIDER_MSB = 0x03;

	// New line
	print_uart('\r');
	print_uart('\n');
	print_uart('\r');
	print_uart('\n');
   
    //addr = 0x130000;
	addr = 0;
	while (1) {

		// Print flash address
		print_uart('0');
		print_uart('x');
		print_uart(hex_to_ascii((addr>>28) & 0xf));
		print_uart(hex_to_ascii((addr>>24) & 0xf));
		print_uart(hex_to_ascii((addr>>20) & 0xf));
		print_uart(hex_to_ascii((addr>>16) & 0xf));
		print_uart(hex_to_ascii((addr>>12) & 0xf));
		print_uart(hex_to_ascii((addr>>8)  & 0xf));
		print_uart(hex_to_ascii((addr>>4)  & 0xf));
		print_uart(hex_to_ascii(addr       & 0xf));
		print_uart(':');
		print_uart(' ');


		// TX inhibit
		SPI_MASTER_CONTROL_REGISTER = SPI_MASTER_CONTROL_TX_INHIBIT_M;
		
		// Read command
		SPI_MASTER_TX_FIFO_DATA = 0x03;
		// Addr
		SPI_MASTER_TX_FIFO_DATA = (addr >> 16) & 0xff;
		SPI_MASTER_TX_FIFO_DATA = (addr >> 8) & 0xff;
		SPI_MASTER_TX_FIFO_DATA = addr & 0xff;
		
		// 32bit data
		SPI_MASTER_TX_FIFO_DATA = 0;
		SPI_MASTER_TX_FIFO_DATA = 0;
		SPI_MASTER_TX_FIFO_DATA = 0;
		SPI_MASTER_TX_FIFO_DATA = 0;

		// Release TX inhibit
		SPI_MASTER_CONTROL_REGISTER = 0x0;
		
		// Increment flash address
		addr += 4;
		
		// Wait until SPI fifo is empty
		while((SPI_MASTER_STATUS_TX_FIFO_EMPTY_S(SPI_MASTER_STATUS_REGISTER))==0);
		for(delay_cnt=0; delay_cnt<233; delay_cnt++);
		
		// Discard dummy bytes
		read_value = SPI_MASTER_RX_FIFO_DATA;
		read_value = SPI_MASTER_RX_FIFO_DATA;
		read_value = SPI_MASTER_RX_FIFO_DATA;
		read_value = SPI_MASTER_RX_FIFO_DATA;
		
		// Print flash content
		print_uart('0');
		print_uart('x');
		for(i=0; i<4; i++) {
			read_value = SPI_MASTER_RX_FIFO_DATA;
			print_uart(hex_to_ascii((read_value>>4)&0xf));
			print_uart(hex_to_ascii(read_value & 0xf));
		}
		// New line
		print_uart('\r');
		print_uart('\n');
	}
}
