const std = @import("std");
const builtin = @import("builtin");
const limine = @import("limine");

// Set the base revision to 4, this is recommended as this is the latest
// base revision described by the Limine boot protocol specification.
// See specification for further info.

pub export var base_revision linksection(".limine_requests") = limine.baseRevision(4);

// The Limine requests can be placed anywhere, but it is important that
// the compiler does not optimise them away, so, usually, they should
// be made volatile or equivalent.

pub export var framebuffer_request: limine.Framebuffer.Request linksection(".limine_requests") = .{};

// Finally, define the start and end markers for the Limine requests.
// These can also be moved anywhere, to any .zig file, as seen fit.

pub export var requests_start_marker linksection(".limine_requests_start") = limine.requests_start_marker;
pub export var requests_end_marker linksection(".limine_requests_end") = limine.requests_end_marker;

// Halt and catch fire function
fn hcf() void {
    while (true) {
        switch (builtin.target.cpu.arch) {
            .x86_64 => {
                asm volatile ("hlt");
            },
            .aarch64, .riscv64 => {
                asm volatile ("wfi");
            },
            .loongarch64 => {
                asm volatile ("idle 0");
            },
            else => @compileError("unsupported architecture"),
        }
    }
}

// The following will be our kernel's entry point.
// If renaming _start() to something else, make sure to change the
// linker script accordingly.
pub export fn _start() callconv(.c) void {
    // Ensure the bootloader actually understands our base revision (see spec).
    if (limine.baseRevisionSupported(&base_revision) == false) {
        hcf();
    }

    // Ensure we got a framebuffer
    if (framebuffer_request.response) |framebuffer_response| {
        if (framebuffer_response.framebuffer_count < 1) {
            hcf();
        }

        // Fetch the first framebuffer
        const framebuffer = framebuffer_response.getFramebuffers()[0];

        // Note: we assume the framebuffer model is RGB with 32-bit pixels.
        for (0..100) |i| {
            framebuffer.getSlice(u32)[i * (framebuffer.pitch / 4) + i] = 0xffffff;
        }
    }

    // We're done, just hang...
    hcf();
}
