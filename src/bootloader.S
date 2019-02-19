#include "config.h"

/* The following symbols must be defined:
  DRAM_BASE
  DRAM_SIZE
  MSIP_BASE
  BOOT_ADDR
*/

.section .text.entry

.global reset_vector
reset_vector:
  # 1. Only the the hart designated to perform secure bootloading proceeds.
  #    Other harts wait on an interrupt barrier.
  call platform_get_bootloader_hart
  csrr a1, mhartid
  bne a1, a0, .wait_for_boot

  # 2. Hart 0 sets a stack pointer; can now call C functions
  la sp, stack_top

  # 3. Hart 0 sanitizes DRAM to destroy data from previous boot
  call platform_clean_dram

  # 4. Hart 0 loads a boot image into memory
  call platform_load_boot_image

  # 5. Hart 0 calls into the C secure bootloader routine to derive keys, etc.
  #    The stack should contain all internal architectural state
  call secure_bootloader

  # 6. Erase private information on the stack
  #    (TODO: make sure the PAGE_SIZE is a multiple of 64 bytes)
  la t0, m_stack_base
  la t1, m_stack_ptr
  .stack_erase_loop:
    sd x0, -8(t1)
    sd x0, -16(t1)
    sd x0, -24(t1)
    sd x0, -32(t1)
    sd x0, -40(t1)
    sd x0, -48(t1)
    sd x0, -56(t1)
    sd x0, -64(t1)
    addi t1, t1, -64
    blt t0, t1, .stack_erase_loop
  li sp, 0

  # 7. Scrub shared state
  call platform_clean_shared_state

  # 8. Wake other harts via inter-processor interrupts (IPI)
  li t0, 1 # value to write to other harts' mip.msip
  li t1, MSIP_BASE
  li t2, ((NUM_HARTS - 1) * 4)
  .wake_other_harts_loop:
      beqz t2, .done_secure_boot
      add t3, t1, t2
      sw t0, 0(t3)
      addi t2, t2, -4
      j .wake_other_harts_loop
      # --- (unreachable)

  .done_secure_boot:
  # 9. Clean core state
  call platform_clean_core_state

  # 10. Transfer control to boot image
    li ra, BOOT_ADDR
    jr ra
    # ---- (unreachable)

  # Meanwhile, other harts wait on an IPI barrier
  .wait_for_boot:
    # Enable IPI to wait on
    la t0, .wake_on_ipi
    csrw mtvec, t0
    csrsi mie, 8
    csrsi mstatus, 8

    # Wait for an IPI from core 0
    .wait_on_ipi:
      wfi # may be implemented as a NOP. In this case, loop and busy-wait
      j .wait_on_ipi
      # --- (unreachable)

    # Once the IPI arrives (secure bootloader has executed)
    .wake_on_ipi:
      # Clear my mip.msip to clear the pending interrupt
      li t0, MSIP_BASE
      csrr t1, mhartid
      slli t1, t1, 2
      add t0, t0, t1
      sw x0, 0(t0)
      fence
      fence.i

      # Reset mtvec, mstatus, mie to disable interrupts
      csrw mtvec, zero
      csrw mie, zero
      csrw mstatus, zero

      # clean the core
      j done_secure_boot
      # --- (unreachable)
