// ascon_test.c
// SPDX-License-Identifier: Apache-2.0
// Author: Leonardo Le (adapted from ETH Zurich examples)

#include <stdint.h>
#include "util.h"
#include "uart.h"
#include "print.h"
#include "ascon_regs.h"  // file này cần được tạo bởi regtool

#define ASCON_BASE_ADDR  0x20000000  // Hoặc dùng USER_ASCON_BASE_ADDR nếu có định nghĩa

int main(void) {
    uart_init();
    printf("Running ASCON hardware test...\n");

    // Reset core nếu cần
    *reg32(ASCON_BASE_ADDR, ASCON_CTRL_REG_OFFSET) = 0x1;

    // Gửi chế độ encrypt (ví dụ: 0x01)
    *reg32(ASCON_BASE_ADDR, ASCON_MODE_REG_OFFSET) = 0x01;

    // Gửi dữ liệu đầu vào
    *reg32(ASCON_BASE_ADDR, ASCON_DATA_IN_0_REG_OFFSET) = 0x11223344;

    // Đánh dấu dữ liệu hợp lệ
    *reg32(ASCON_BASE_ADDR, ASCON_DATA_IN_VALID_REG_OFFSET) = 0x1;

    // Gửi tín hiệu start
    *reg32(ASCON_BASE_ADDR, ASCON_START_REG_OFFSET) = 0x1;

    // Chờ đến khi hoàn tất (polling DONE)
    while ((*reg32(ASCON_BASE_ADDR, ASCON_DONE_REG_OFFSET) & 0x1) == 0);

    // Đọc dữ liệu đầu ra
    uint32_t result = *reg32(ASCON_BASE_ADDR, ASCON_DATA_OUT_0_REG_OFFSET);
    printf("ASCON result = 0x%08x\n", result);

    uart_write_flush();

    return 0;
}
