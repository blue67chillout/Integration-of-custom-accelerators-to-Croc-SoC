// MAC Accelerator Test

#include <stdint.h>
#include "print.h"
#include "uart.h"

// MAC Accelerator base address = User domain base 
#define MAC_BASE 0x20001000

// Register offsets (in bytes) — FIXED
#define MAC_OPERAND_A_OFFSET  0x00  // operand_a
#define MAC_OPERAND_B_OFFSET  0x04  // operand_b
#define MAC_OPERAND_C_OFFSET  0x08  // operand_c
#define MAC_RESULT_OFFSET     0x0C  // result
#define MAC_STATUS_OFFSET     0x10  // done flag
#define MAC_CONTROL_OFFSET    0x14  // start


static inline void mac_write(uint32_t offset, uint32_t value) {
  volatile uint32_t *reg = (uint32_t *)(MAC_BASE + offset);
  *reg = value;
}

static inline uint32_t mac_read(uint32_t offset) {
  volatile uint32_t *reg = (uint32_t *)(MAC_BASE + offset);
  return *reg;
}


static inline void mac_write_a(int32_t value) {
  mac_write(MAC_OPERAND_A_OFFSET, (uint32_t)value);
}

static inline void mac_write_b(int32_t value) {
  mac_write(MAC_OPERAND_B_OFFSET, (uint32_t)value);
}

static inline void mac_write_c(int32_t value) {
  mac_write(MAC_OPERAND_C_OFFSET, (uint32_t)value);
}

static inline void mac_start(void) {
  mac_write(MAC_CONTROL_OFFSET, 0x1);
}

static inline uint32_t mac_is_done(void) {
  return mac_read(MAC_STATUS_OFFSET) & 0x1;
}

static inline uint32_t mac_read_result(void) {
  return mac_read(MAC_RESULT_OFFSET);
}


static void test_mac(int32_t a, int32_t b, int32_t c) {
  printf("Writing A=0x%x\n", (uint32_t)a);
  uart_write_flush();
  mac_write_a(a);

  printf("Writing B=0x%x\n", (uint32_t)b);
  uart_write_flush();
  mac_write_b(b);

  printf("Writing C=0x%x\n", (uint32_t)c);
  uart_write_flush();
  mac_write_c(c);

  printf("Starting MAC\n");
  uart_write_flush();
  mac_start();

  // Proper polling (no magic delays)
  while (!mac_is_done());

  printf("Reading result\n");
  uart_write_flush();
  uint32_t result = mac_read_result();
  uint32_t expected = (uint32_t)(a * b + c);

  printf("Result=0x%x (expected=0x%x)\n", result, expected);
  uart_write_flush();

  if (result == expected) {
    printf("PASS\n");
  } else {
    printf("FAIL\n");
  }
  uart_write_flush();
}

int main(void) {
  uart_init();

  printf("MAC Test Suite\n");
  uart_write_flush();

  test_mac(5, 3, 2);   // expected 17 (0x11)
  test_mac(7, 4, 1);   // expected 29 (0x1D)
  test_mac(-3, 6, 10); // signed test

  printf("Done\n");
  uart_write_flush();

  return 0;
}
