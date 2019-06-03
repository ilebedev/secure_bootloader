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
    *(.text.entry)
    *(.text.platform)
    *(.text.*)
    *(.text)
    *(.rodata)
    *(.got)
    *(.got.*)
  }

  . = 0x80000000;
  .dram (NOLOAD): {
    *(.data.stack)
    *(.data.boot_image)
    PROVIDE(measured_binary = .);
  }
}
