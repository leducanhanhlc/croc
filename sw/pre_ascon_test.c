// Copyright (c) 2025 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0/
//
// Author:
// - Leonardo Le

#include "uart.h"
#include "print.h"
#include "util.h"

#define TB_FREQUENCY 10000000
#define TB_BAUDRATE    115200

#define PRE_ASCON_BASE_ADDR  0x20002000  // Hoặc dùng USER_ASCON_BASE_ADDR nếu có định nghĩa


int main() {
    uart_init();

    printf("He%xo World!\n", 0x11);
    uart_write_flush();

    // Step 1: Prepare input and write to input register
    uint32_t input_data = 0x12345432;

    *reg32(PRE_ASCON_BASE_ADDR, 0x0) = input_data;
    asm volatile (
        "nop; nop; nop; nop; nop;"
    ); // wait a few cycles
    // Step 4: Read output
    uint32_t result = *reg32(PRE_ASCON_BASE_ADDR, 0x0);
    printf("Input  = 0x%x\n", input_data);
    uart_write_flush();
    printf("Output = 0x%x\n", result);
    uart_write_flush();
    // Step 5: Validate
    if (result == input_data) {
        printf("TEST PASSED \n");
    } else {
        printf("TEST FAILED ❌\n");
    }

    uart_write_flush();
    return 1;
}
