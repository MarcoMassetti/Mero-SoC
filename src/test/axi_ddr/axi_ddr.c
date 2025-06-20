
char hex_to_ascii(unsigned int hex) {
    if (hex < 10) {
        return '0' + hex;
    } else {
        return 'a' + (hex - 10);
    }
}

int main() {
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
	
	// DDR base address
	volatile unsigned int *DDR = (unsigned int*)0x80000;
	
	volatile unsigned int *addr, *addr1;
	char i,j;

   
    addr =  DDR;
	addr1 = DDR;
	while (1) {
		// Write some data to ddr
		for(i=0; i<5; i++) {
			*(addr) = (unsigned int)(addr);
			addr++;
		}
				
		// Read back and print in UART
		for(i=0; i<5; i++) {
			// Print ddr content
			read_value = *addr1;
			addr1++;
			
			*UART_TX_REGISTER = '0';
			*UART_TX_REGISTER = 'x';
			*UART_TX_REGISTER = hex_to_ascii((read_value>>28) & 0xf);
			*UART_TX_REGISTER = hex_to_ascii((read_value>>24) & 0xf);
			*UART_TX_REGISTER = hex_to_ascii((read_value>>20) & 0xf);
			*UART_TX_REGISTER = hex_to_ascii((read_value>>16) & 0xf);
			// small delay to transmit data
			for(delay_cnt=0; delay_cnt<2330; delay_cnt++);
			*UART_TX_REGISTER = hex_to_ascii((read_value>>12) & 0xf);
			*UART_TX_REGISTER = hex_to_ascii((read_value>>8)  & 0xf);
			*UART_TX_REGISTER = hex_to_ascii((read_value>>4)  & 0xf);
			*UART_TX_REGISTER = hex_to_ascii((read_value)     & 0xf);
			// New line
			*UART_TX_REGISTER = '\r';
			*UART_TX_REGISTER = '\n';
			// small delay to transmit data
			for(delay_cnt=0; delay_cnt<2330; delay_cnt++);
		}
		
		// 1 s delay
		for(delay_cnt=0; delay_cnt<233000; delay_cnt++);
	}
}
