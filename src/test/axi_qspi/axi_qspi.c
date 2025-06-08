
char hex_to_ascii(unsigned int hex) {
    if (hex < 10) {
        return '0' + hex;
    } else {
        return 'a' + (hex - 10);
    }
}

int main() {
	volatile unsigned int addr;
	volatile unsigned int delay_cnt;
	
	volatile unsigned int read_value;
	
	// SPI CTRL register
	volatile unsigned int *CTRL_REGISTER = (unsigned int*)0x60060;
	// SPI STAT register
	volatile unsigned int *STAT_REGISTER = (unsigned int*)0x60064;
	// SPI TX register
	volatile unsigned int *TX_REGISTER = (unsigned int*)0x60068;
	// SPI RX register
	volatile unsigned int *RX_REGISTER = (unsigned int*)0x6006c;
	// SPI SS register
	volatile unsigned int *SS_REGISTER = (unsigned int*)0x60070;
	

	// UART TX register
	volatile unsigned int *UART_TX_REGISTER = (unsigned int*)0x40004;
	
	char i;

   
    addr = 0;
	while (1) {

		// SPI enable / Master mode (CS asserted automatically with data), TX inhibit, reset TX/RX fifos
		*CTRL_REGISTER = 0x166;
		
		// Set SS polarity
		*SS_REGISTER = 0;
		
		// Read command
		*TX_REGISTER = 0x03;
		// Addr
		*TX_REGISTER = (addr >> 24) & 0xff;
		*TX_REGISTER = (addr >> 16) & 0xff;
		*TX_REGISTER = addr & 0xff;
		
		// 32bit data
		*TX_REGISTER = 0;
		*TX_REGISTER = 0;
		*TX_REGISTER = 0;
		*TX_REGISTER = 0;
		*CTRL_REGISTER = 0x6;

		// Release TX inhibit
		*CTRL_REGISTER = 0x6;
		
		// Increment flash address
		addr += 4;
		
		// 1 s delay
		for(delay_cnt=0; delay_cnt<233000; delay_cnt++);
		
		// Discard dummy bytes
		read_value = *RX_REGISTER;
		read_value = *RX_REGISTER;
		read_value = *RX_REGISTER;
		read_value = *RX_REGISTER;
		
		// Print flash content
		*UART_TX_REGISTER = '0';
		*UART_TX_REGISTER = 'x';
		for(i=0; i<4; i++) {
			read_value = *RX_REGISTER;
			*UART_TX_REGISTER = hex_to_ascii(read_value>>4);
			*UART_TX_REGISTER = hex_to_ascii(read_value & 0xf);
		}
		
		// New line
		*UART_TX_REGISTER = '\r';
		*UART_TX_REGISTER = '\n';
		
		for(delay_cnt=0; delay_cnt<233000; delay_cnt++);
	}
}
