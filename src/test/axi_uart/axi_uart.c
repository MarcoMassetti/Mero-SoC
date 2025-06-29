
int main() {
	volatile char i;
	volatile unsigned int delay_cnt;

	// UART RX register
	volatile unsigned int *RX_REGISTER = (unsigned int*)0x40000;
	// UART TX register
	volatile unsigned int *TX_REGISTER = (unsigned int*)0x40004;
	// UART status register
	volatile unsigned int *STAT_REGISTER = (unsigned int*)0x40008;
	// UART clk_div low
	volatile unsigned int *CLK_DIV_LH_REGISTER = (unsigned int*)0x40010;
	// UART clk_div high
	volatile unsigned int *CLK_DIV_HI_REGISTER = (unsigned int*)0x40014;
   
   // Baud rate 9600
	*CLK_DIV_LH_REGISTER = 0x64;
	*CLK_DIV_HI_REGISTER = 0x03;
   
	while (1) {
		if (*STAT_REGISTER & 0x1) {
			*TX_REGISTER = 'R';
			*TX_REGISTER = 'x';
			*TX_REGISTER = ':';
			*TX_REGISTER = ' ';
			while (*STAT_REGISTER & 0x1) {
				*TX_REGISTER = *RX_REGISTER&0xff;
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
