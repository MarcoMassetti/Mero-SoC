
int main() {
	volatile char i;
	volatile unsigned int delay_cnt;
	
	// UART RX register
	volatile unsigned int *RX_REGISTER = (unsigned int*)0x40000;
	// UART TX register
	volatile unsigned int *TX_REGISTER = (unsigned int*)0x40004;
	// UART STAT register
	volatile unsigned int *STAT_REGISTER = (unsigned int*)0x40008;
   
	while (1) {
		if (*STAT_REGISTER & 0x1) {
			*TX_REGISTER = 'R';
			*TX_REGISTER = 'x';
			*TX_REGISTER = ':';
			while (*STAT_REGISTER & 0x1) {
				*TX_REGISTER = *RX_REGISTER & 0xff;
			}
		} else {
			*TX_REGISTER = 'N';
		}
		*TX_REGISTER = '\r';
		*TX_REGISTER = '\n';
		
		// 1 s delay
		for(delay_cnt=0; delay_cnt<233000; delay_cnt++);
	}
}
