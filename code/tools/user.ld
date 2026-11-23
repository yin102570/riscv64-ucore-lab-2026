OUTPUT_ARCH(riscv)
ENTRY(_start)

SECTIONS
{
    . = 0x800020;

    . = ALIGN(0x1000);

    .text : {
        *(.text .text.* .stub)
    }

    . = ALIGN(0x1000);

    .rodata : {
        *(.rodata .rodata.* .srodata .srodata.*)
    }

    . = ALIGN(0x1000);

    .data : {
        *(.data .data.* .sdata .sdata.*)
    }

    . = ALIGN(0x1000);

    .bss : {
        *(.bss .bss.* .sbss .sbss.*)
        *(COMMON)
    }

    /DISCARD/ : {
        *(.eh_frame .note.GNU-stack)
    }
}
