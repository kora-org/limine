const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    b.addModule(.{
        .name = "limine",
        .source_file = .{ .path = "src/main.zig" },
    });

    const main_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);

    const docs = main_tests;
    docs.emit_docs = .emit;

    const docs_step = b.step("docs", "Generate documentation");
    docs_step.dependOn(&docs.step);
}
