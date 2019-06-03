#ifndef PLATFORM_H
#define PLATFORM_H

#include <csr/csr.h>
#include <config.h>
#include <string.h>

// Prerequisites
_Static_assert ( ((RAM_BASE&0xFF) == 0), "Implementation of `platform_clear_memory_and_load_boot_image` assumes the DRAM_BASE is aligned to a  is aligned to a 512B boundary.");

_Static_assert ( ((RAM_SIZE&0xFF) == 0), "Implementation of `platform_clear_memory_and_load_boot_image` assumes the DRAM_SIZE is a multiple of 512B.");

// Basic platform primitives: stack, image loading
typedef struct bootloader_stack_t { uint8_t x[4096]; } bootloader_stack_t;
volatile bootloader_stack_t stack __attribute__(( section(".data.stack"), aligned(4096) )) ;
boot_image_header_t boot_image_header __attribute__(( section(".boot_image") )) ;

// Device secret
typedef struct device_secret_t { uint8_t x[32]; } device_secret_t;

static inline void platform_read_device_secret(device_secret_t * out_device_secret) {
  memcpy(out_device_secret, (device_secret_t *)(DEVICE_SECRET_BASE), sizeof(device_secret_t));
}

static inline void platform_hide_device_secret() {
  //_Static_assert ( ( sizeof(device_secret) >= sizeof(public_key_seed_t) ), "Implementation of `platform_hide_device_secret` assumes the secret size is a multiple of 8 bytes");
  //_Static_assert ( ((DEVICE_SECRET_ADDR&0x7) == 0), "Implementation of `platform_hide_device_secret` assumes the secret is aligned to an 8B word in memory");

  for (unsigned int i=0; i<sizeof(device_secret_t); i++) {
    ( (uint8_t*)(DEVICE_SECRET_BASE) )[i] = 0;
  }
}

// Platform IO
static inline void platform_finalize_secure_boot() {
  return; // This is the place to print a commitment to the derived keys on a RISCY platform.
}

__attribute__ (( noreturn )) static inline void platform_panic(char* message) {
  // This is the place to print a commitment to the derived keys on a RISCY platform.
  void (*soft_reboot)(void) = BOOT_ROM_BASE;
  soft_reboot();
}

// TRNG
static inline void create_random_value(size_t bytes, void * out_random_data) {
  for (unsigned int i=0; i<bytes; i++) {
    ( (uint8_t*)(out_random_data) )[i] = (uint8_t)(read_csr(trng));
  }
}

#endif //PLATFORM_H
