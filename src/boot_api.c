#include "boot_api.h"
volatile bootloader_state_t boot_api_state __attribute__((section(".boot_api_state")));\
