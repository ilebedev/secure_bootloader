#ifndef BOOT_API_H
#define BOOT_API_H

#include <stdint.h>

typedef struct bootloader_metadata_t {
  bool has_encrypted_sk_sm;
  // PUF helper data belongs here
  // encrypted SK_D belongs here
} bootloader_metadata_t;

typedef struct bootloader_state_t {
  uint8_t device_public_key[32];
  uint8_t security_monitor_public_key[32];
  uint8_t security_monitor_secret_key[64];
  uint8_t security_monitor_hash[64];
  uint8_t security_monitor_signature[64];
  uint8_t security_monitor_size[64];
  bootloader_metadata_t software_metadata;
} bootloader_state_t;

extern bootloader_state_t boot_api_state;

#endif // BOOT_API_H
