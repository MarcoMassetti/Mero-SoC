// SPI CTRL register
volatile unsigned int *CTRL_REGISTER = (unsigned int*)0x60000;
// SPI STAT register
volatile unsigned int *STAT_REGISTER = (unsigned int*)0x60004;
// SPI TX register
volatile unsigned int *TX_REGISTER = (unsigned int*)0x60008;
// SPI RX register
volatile unsigned int *RX_REGISTER = (unsigned int*)0x6000c;


// UART RX register
volatile unsigned int *UART_RX_REGISTER = (unsigned int*)0x40000;
// UART TX register
volatile unsigned int *UART_TX_REGISTER = (unsigned int*)0x40004;
// UART status register
volatile unsigned int *UART_STAT_REGISTER = (unsigned int*)0x40008;
// UART clk_div low
volatile unsigned int *UART_CLK_DIV_LH_REGISTER = (unsigned int*)0x40010;
// UART clk_div high
volatile unsigned int *UART_CLK_DIV_HI_REGISTER = (unsigned int*)0x40014;
   

char hex_to_ascii(unsigned int hex) {
    if (hex < 10) {
        return '0' + hex;
    } else {
        return 'a' + (hex - 10);
    }
}

void print_uart(char chr) {
	// Wait for space in uart fifo
	while(*UART_STAT_REGISTER & 8);
	*UART_TX_REGISTER = chr;
}

int main() {
	volatile unsigned int addr;	
	volatile unsigned int read_value;
	
	volatile unsigned int delay_cnt;
	char i;
	
	// Baud rate 115200
	*UART_CLK_DIV_LH_REGISTER = 0x64;
	*UART_CLK_DIV_HI_REGISTER = 0x03;

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
		*CTRL_REGISTER = 0x4;
		
		// Read command
		*TX_REGISTER = 0x03;
		// Addr
		*TX_REGISTER = (addr >> 16) & 0xff;
		*TX_REGISTER = (addr >> 8) & 0xff;
		*TX_REGISTER = addr & 0xff;
		
		// 32bit data
		*TX_REGISTER = 0;
		*TX_REGISTER = 0;
		*TX_REGISTER = 0;
		*TX_REGISTER = 0;

		// Release TX inhibit
		*CTRL_REGISTER = 0x0;
		
		// Increment flash address
		addr += 4;
		
		// Wait until SPI fifo is empty
		while((*STAT_REGISTER & 4)==0);
		for(delay_cnt=0; delay_cnt<233; delay_cnt++);
		
		// Discard dummy bytes
		read_value = *RX_REGISTER;
		read_value = *RX_REGISTER;
		read_value = *RX_REGISTER;
		read_value = *RX_REGISTER;
		
		// Print flash content
		print_uart('0');
		print_uart('x');
		for(i=0; i<4; i++) {
			read_value = *RX_REGISTER;
			print_uart(hex_to_ascii((read_value>>4)&0xf));
			print_uart(hex_to_ascii(read_value & 0xf));
		}
		// New line
		print_uart('\r');
		print_uart('\n');
	}
}
