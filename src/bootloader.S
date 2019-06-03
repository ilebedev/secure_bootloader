#include "config.h"

.section .text.entry

.global reset_vector
reset_vector:
  # 1. Only the the hart designated to perform secure bootloading proceeds.
  #    Other harts wait on an interrupt barrier.
  li a0, 0 // Core 0 performs boot
  csrr a1, mhartid
  bne a1, a0, .wait_for_boot

  # 2. Hart 0 sanitizes DRAM to destroy data from previous boot
  li a0, RAM_BASE
  li a1, (RAM_BASE+RAM_SIZE)
  call platform_clear_algined_memory

  # 3. Hart 0 loads a boot image into memory
  call platform_load_boot_image

  # 4. Hart 0 sets a stack pointer; can now call C functions
  la sp, m_stack_top

  # 5. Hart 0 calls into the C secure bootloader routine to derive keys, etc.
  #    The stack should contain all internal architectural state
  call bootloader

  # 6. Erase private information on the stack
  #    (TODO: make sure the PAGE_SIZE is a multiple of 64 bytes)
  la a0, m_stack_base
  la a1, m_stack_top
  call platform_clear_algined_memory

  # 7. Scrub shared state
  call platform_clean_shared_state

  # 8. Wake other harts by signaling a barrier
  call platform_barrier_signal

  # 9-1. Other cores are now cleaning up and booting. Do the same
  j boot_sw_image
  # --- (unreachable)

  # 9-2 Meanwhile, other harts wait on an IPI barrier
  .wait_for_boot:
    # Wait on an IPI barrier
    call platform_barrier_wait

    # Boot
    j boot_sw_image
    # --- (unreachable)

boot_sw_image:
  # 10 Init the core to a clean state before boot
  call platform_clean_core_state

  # 11 Transfer control to boot image
  la ra, post_boot_ptr
  jr ra
  # ---- (unreachable)
