#ifndef PLATFORM_CONFIG_H
#define PLATFORM_CONFIG_H

#define STACK_SIZE (4096)
#define STACK_BASE (RAM_BASE)
#define STACK_TOP  (STACK_BASE + STACK_SIZE)
#define BOOT_IMAGE_MEASURED_BINARY_OFFSET (0x130) /* (CAUTION: make sure this is equal to sizeof(boot_image_header_t)) */

#endif //PLATFORM_CONFIG_H
