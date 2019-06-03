OUTPUT_ARCH( "riscv" )
ENTRY( reset_vector )

SECTIONS
{
  /* Boot ROM contains only the code needed to initialize DRAM,
     and to authenticate the full boot loader.
     This includes the size and expected hash of the boot loader. */

  /* Boot ROM base */
  . = 0x1000;

  .rom : {
    _start = .;
    *(.text.entry)
    *(.text)
  }

  . = 0x80000000;
  .dram (NOLOAD): {
    PROVIDE(m_stack_base = .);
    *(.data.stack)
    PROVIDE(m_stack_top = .);
    *(.data.boot_image)
    PROVIDE(post_boot_ptr = .);
  }

  . = 0x10000000;
  .leftovers : {
    *(.*)
  }
}
