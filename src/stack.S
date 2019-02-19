#include "config.h"

.section ".stack"
.globl stack_base, stack_top
.align PAGE_SHIFT

stack_base:
  .skip PAGE_SIZE
stack_top:
