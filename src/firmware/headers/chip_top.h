#ifndef CHIP_TOP_H
#define CHIP_TOP_H

// Base address of the peripherals (use byte address)
#define CPU_INTERFACE_BASE_ADDR (unsigned char*)0x00010000
#define UART_BASE_ADDR          (unsigned char*)0x00010100
#define SPI_MASTER_BASE_ADDR    (unsigned char*)0x00010200

// Dereference of memory address (use word address)
#define REG_ADDR(addr) *((volatile unsigned int*)(addr))

#endif // CHIP_TOP_H

