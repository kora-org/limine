# limine/template
An example kernel on how to use the Limine Zig bindings. Based on https://codeberg.org/Limine/limine-c-template

## Supported targets
- `x86_64-freestanding-none`
- `aarch64-freestanding-none`
- `riscv64-freestanding-none`
- `loongarch64-freestanding-none`
To build to a supported target, use `-Dtarget=[target triple]`.

## Build steps
- `install` (default): Compiles the kernel and outputs it to zig-out/bin
- `iso`: Compiles the kernel and generates a bootable ISO to zig-out/iso
- `hdd`: Compiles the kernel and generates a bootable disk image to zig-out/hdd
- `run`: Builds the kernel and the ISO and runs it with QEMU
- `run-hdd`: Builds the kernel and the disk image and runs it with QEMU
