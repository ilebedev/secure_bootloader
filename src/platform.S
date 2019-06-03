#include "config.h"

.section .text.platform

.global platform_clear_algined_memory
platform_clear_algined_memory:
  # a0 is base address
  # a1 is (base+size)
  # ^ both must be aligned to a cache line (512b)
  .platform_clear_algined_memory.loop:
    sd x0, -8(a1)
    sd x0, -16(a1)
    sd x0, -24(a1)
    sd x0, -32(a1)
    sd x0, -40(a1)
    sd x0, -48(a1)
    sd x0, -56(a1)
    sd x0, -64(a1)
    addi a1, a1, -64
    blt a0, a1, .platform_clear_algined_memory.loop
  jr ra


.global platform_clean_shared_state
platform_clean_shared_state:
  # Set whatever CSRs the platform needs to clean microarchitectural state
  # This would go here
  jr ra


.global platform_clean_core_state
platform_clean_core_state:
  fence
  fence.i
  # Set whatever CSRs the platform needs to clean microarchitectural state
  # This would go here
  jr ra


.global platform_load_boot_image
platform_load_boot_image:
  # RISCY uses a memory-mapped interface to signal the loading of an ELF, and receive notification that the loader is done
  # Ask host to load ELF into DRAM
  li t0, MEM_LOADER_BASE
  li t1, RAM_BASE
  sw t1, 0(t0)
  fence # make sure the request goes out

  # wait for host to finish
  .platform_load_boot_image.wait:
  ld t1, 8(t0)
  bnez t1, .platform_load_boot_image.wait

  fence
  fence.i

  jr ra


.global platform_barrier_signal
platform_barrier_signal:
  # Assume this is hart # 0
  # Wake other harts via inter-processor interrupts (IPI)
  li t0, 1 # value to write to other harts' mip.msip
  li t1, MSIP_BASE
  li t2, ((NUM_HARTS - 1) * 4)
  .platform_barrier_signal.loop:
      beqz t2, .platform_barrier_signal.done
      add t3, t1, t2
      sw t0, 0(t3)
      addi t2, t2, -4
      j .platform_barrier_signal.loop
      # --- (unreachable)
  .platform_barrier_signal.done:
  jr ra


.global platform_barrier_wait
platform_barrier_wait:
  # Enable IPI to wait on
  la t0, .platform_barrier.wake_ipi
  csrw mtvec, t0
  csrsi mie, 8
  csrsi mstatus, 8

  # Wait for an IPI from core 0
  .platform_barrier.wait_ipi:
    wfi # may be implemented as a NOP. In this case, loop and busy-wait
    j .platform_barrier.wait_ipi
    # --- (unreachable)

  # Once the IPI arrives (barrier has been cleared)
  .platform_barrier.wake_ipi:
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

  # Return
  jr ra
