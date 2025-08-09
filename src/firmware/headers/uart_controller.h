#ifndef UART_CONTROLLER_H
#define UART_CONTROLLER_H

// Include base addresses and macros
#include "chip_top.h"

// Register addresses
#define UART_RX_FIFO_DATA      REG_ADDR(UART_BASE_ADDR + 0x00)
#define UART_TX_FIFO_DATA      REG_ADDR(UART_BASE_ADDR + 0x04)
#define UART_STATUS_REGISTER   REG_ADDR(UART_BASE_ADDR + 0x08)
#define UART_CONTROL_REGISTER  REG_ADDR(UART_BASE_ADDR + 0x0C)
#define UART_CLOCK_DIVIDER_LSB REG_ADDR(UART_BASE_ADDR + 0x10)
#define UART_CLOCK_DIVIDER_MSB REG_ADDR(UART_BASE_ADDR + 0x14)

//// UART_STATUS_REGISTER
// status_register fields masks
#define UART_STATUS_RX_FIFO_NOT_EMPTY_M (0x01)
#define UART_STATUS_RX_FIFO_FULL_M      (0x02)
#define UART_STATUS_TX_FIFO_EMPTY_M     (0x04)
#define UART_STATUS_TX_FIFO_FULL_M      (0x08)
#define UART_STATUS_OVERRUN_ERROR_M     (0x20)
#define UART_STATUS_RX_FRAME_ERROR_M    (0x40)
// status_register fields value set
#define UART_STATUS_RX_FIFO_NOT_EMPTY_S(val) (val << 0)
#define UART_STATUS_RX_FIFO_FULL_S(val)      (val << 1)
#define UART_STATUS_TX_FIFO_EMPTY_S(val)     (val << 2)
#define UART_STATUS_TX_FIFO_FULL_S(val)      (val << 3)
#define UART_STATUS_OVERRUN_ERROR_S(val)     (val << 5)
#define UART_STATUS_RX_FRAME_ERROR_S(val)    (val << 6)
// status_register fields value get
#define UART_STATUS_RX_FIFO_NOT_EMPTY_G(val) ((val & UART_STATUS_RX_FIFO_NOT_EMPTY_M) >> 0)
#define UART_STATUS_RX_FIFO_FULL_G(val)      ((val & UART_STATUS_RX_FIFO_FULL_M) >> 1)
#define UART_STATUS_TX_FIFO_EMPTY_G(val)     ((val & UART_STATUS_TX_FIFO_EMPTY_M) >> 2)
#define UART_STATUS_TX_FIFO_FULL_G(val)      ((val & UART_STATUS_TX_FIFO_FULL_M) >> 3)
#define UART_STATUS_OVERRUN_ERROR_G(val)     ((val & UART_STATUS_OVERRUN_ERROR_M) >> 5)
#define UART_STATUS_RX_FRAME_ERROR_G(val)    ((val & UART_STATUS_RX_FRAME_ERROR_M) >> 6)

//// UART_CONTROL_REGISTER
// control_register fields masks
#define UART_CONTROL_TX_FIFO_RESET_M (0x01)
#define UART_CONTROL_RX_FIFO_RESET_M (0x02)
// control_register fields value set
#define UART_CONTROL_TX_FIFO_RESET_S(val) (val << 0)
#define UART_CONTROL_RX_FIFO_RESET_S(val) (val << 1)
// control_register fields value get
#define UART_CONTROL_TX_FIFO_RESET_G(val) ((val & UART_CONTROL_TX_FIFO_RESET_M) >> 0)
#define UART_CONTROL_RX_FIFO_RESET_G(val) ((val & UART_CONTROL_RX_FIFO_RESET_M) >> 1)

#endif // UART_CONTROLLER_H

