const std = @import("std");

pub fn build(b: *std.Build) !void {
    var target = b.standardTargetOptions(.{
        .default_target = .{
            .cpu_arch = .x86_64,
            .os_tag = .freestanding,
            .abi = .none,
        },
        .whitelist = &.{
            .{ .cpu_arch = .x86_64, .os_tag = .freestanding, .abi = .none },
            .{ .cpu_arch = .aarch64, .os_tag = .freestanding, .abi = .none },
            .{ .cpu_arch = .riscv64, .os_tag = .freestanding, .abi = .none },
            .{ .cpu_arch = .loongarch64, .os_tag = .freestanding, .abi = .none },
        },
    });
    switch (target.query.cpu_arch.?) {
        .x86_64 => {
            const features = std.Target.x86.Feature;
            target.query.cpu_features_sub.addFeature(@intFromEnum(features.mmx));
            target.query.cpu_features_sub.addFeature(@intFromEnum(features.sse));
            target.query.cpu_features_sub.addFeature(@intFromEnum(features.sse2));
            target.query.cpu_features_sub.addFeature(@intFromEnum(features.avx));
            target.query.cpu_features_sub.addFeature(@intFromEnum(features.avx2));
            target.query.cpu_features_add.addFeature(@intFromEnum(features.soft_float));
        },
        else => {},
    }
    const optimize = b.standardOptimizeOption(.{});

    const limine = b.dependency("limine", .{});
    const limine_bootloader = b.dependency("limine_bootloader", .{});

    const exe = b.addExecutable(.{
        .name = "kernel",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .code_model = switch (target.query.cpu_arch.?) {
                .x86_64 => .kernel,
                else => .default,
            },
            .red_zone = false,
            .imports = &.{
                .{ .name = "limine", .module = limine.module("limine") },
            },
        }),
        .use_llvm = true,
        .use_lld = true,
    });
    exe.setLinkerScript(switch (target.query.cpu_arch.?) {
        .x86_64 => b.path("src/linker-x86_64.ld"),
        .aarch64 => b.path("src/linker-aarch64.ld"),
        .riscv64 => b.path("src/linker-riscv64.ld"),
        .loongarch64 => b.path("src/linker-loongarch64.ld"),
        else => return error.UnsupportedArchitecture,
    });
    b.installArtifact(exe);

    const limine_exe = b.addExecutable(.{
        .name = "limine-deploy",
        .root_module = b.createModule(.{
            .target = b.graph.host,
            .optimize = .ReleaseSafe,
        }),
    });
    limine_exe.addCSourceFile(.{ .file = limine_bootloader.path("limine.c"), .flags = &[_][]const u8{"-std=c99"} });
    limine_exe.linkLibC();

    const iso_step = b.step("iso", "Generate a bootable ISO file");
    iso_step.dependOn(try generateIso(b, exe, limine_exe, limine_bootloader));

    const hdd_step = b.step("hdd", "Generate a bootable disk image");
    hdd_step.dependOn(try generateHdd(b, exe, limine_exe, limine_bootloader));

    const qemu_iso_step = b.step("run", "Boot ISO in QEMU");
    qemu_iso_step.dependOn(try runIsoQemu(b, iso_step, target.query.cpu_arch.?));

    const qemu_hdd_step = b.step("run-hdd", "Boot disk image in QEMU");
    qemu_hdd_step.dependOn(try runHddQemu(b, hdd_step, target.query.cpu_arch.?));
}

fn generateIso(
    b: *std.Build,
    exe: *std.Build.Step.Compile,
    limine_exe: *std.Build.Step.Compile,
    limine_bootloader: *std.Build.Dependency,
) !*std.Build.Step {
    const limine_path = limine_bootloader.path(".");
    const limine_exe_run = b.addRunArtifact(limine_exe);
    limine_exe_run.addArg("bios-install");

    const iso_dir = try b.cache_root.join(b.allocator, &[_][]const u8{"iso"});
    const iso_path = b.getInstallPath(.{ .custom = "iso" }, "template.iso");
    const cmd = &[_][]const u8{
        // zig fmt: off
        "/bin/sh", "-c",
        try std.mem.concat(b.allocator, u8, &[_][]const u8{
            "rm -rf ", iso_dir, " && ",
            "rm -rf ", b.getInstallPath(.{ .custom = "iso" }, ""), " && ",
            "mkdir -p ", iso_dir, "/boot/limine && ",
            "mkdir -p ", iso_dir, "/EFI/BOOT && ",
            "mkdir -p ", b.getInstallPath(.{ .custom = "iso" }, ""), " && ",
            "cp ", b.getInstallPath(.bin, exe.name), " ", iso_dir, "/boot && ",
            "cp src/limine.conf ", iso_dir, " && ",
            "cp ", limine_path.getPath(b), "/limine-bios.sys ",
                   limine_path.getPath(b), "/limine-bios-cd.bin ",
                   limine_path.getPath(b), "/limine-uefi-cd.bin ",
                   iso_dir, "/boot/limine && ",
            "cp ", limine_path.getPath(b), "/BOOTX64.EFI ",
                   limine_path.getPath(b), "/BOOTAA64.EFI ",
                   limine_path.getPath(b), "/BOOTRISCV64.EFI ",
                   limine_path.getPath(b), "/BOOTLOONGARCH64.EFI ",
                   iso_dir, "/EFI/BOOT && ",
            "xorriso -as mkisofs -R -r -J -b boot/limine/limine-bios-cd.bin ",
                "-no-emul-boot -boot-load-size 4 -boot-info-table -hfsplus ",
                "-apm-block-size 2048 --efi-boot boot/limine/limine-uefi-cd.bin ",
                "-efi-boot-part --efi-boot-image --protective-msdos-label ",
                iso_dir, " -o ", iso_path,
        }),
        // zig fmt: on
    };

    const iso_cmd = b.addSystemCommand(cmd);
    iso_cmd.step.dependOn(b.getInstallStep());

    limine_exe_run.addArg(iso_path); // FIXME: this probably should be addFileArg
    limine_exe_run.step.dependOn(&iso_cmd.step);

    return &limine_exe_run.step;
}

fn generateHdd(
    b: *std.Build,
    exe: *std.Build.Step.Compile,
    limine_exe: *std.Build.Step.Compile,
    limine_bootloader: *std.Build.Dependency,
) !*std.Build.Step {
    const limine_path = limine_bootloader.path(".");
    const limine_exe_run = b.addRunArtifact(limine_exe);
    limine_exe_run.addArg("bios-install");

    const hdd_path = b.getInstallPath(.{ .custom = "hdd" }, "template.hdd");
    const cmd = &[_][]const u8{
        // zig fmt: off
        "/bin/sh", "-c",
        try std.mem.concat(b.allocator, u8, &[_][]const u8{
            "rm -rf ", b.getInstallPath(.{ .custom = "hdd" }, ""), " && ",
            "mkdir -p ", b.getInstallPath(.{ .custom = "hdd" }, ""), " && ",
            "dd if=/dev/zero bs=1M count=0 seek=64 of=", hdd_path, " && ",
            "sgdisk ", hdd_path, " -n 1:2048 -t 1:ef00 -m 1 && ",
            "mformat -i ", hdd_path, "@@1M && ",
            "mmd -i ", hdd_path, "@@1M ::/EFI ::/EFI/BOOT ::/boot ::/boot/limine && ",
            "mcopy -i ", hdd_path, "@@1M ", b.getInstallPath(.bin, exe.name), " ::/boot && ",
            "mcopy -i ", hdd_path, "@@1M src/limine.conf ::/boot/limine && ",
            "mcopy -i ", hdd_path, "@@1M ", limine_path.getPath(b), "/limine-bios.sys ::/boot/limine && ",
            "mcopy -i ", hdd_path, "@@1M ", limine_path.getPath(b), "/BOOTX64.EFI ::/EFI/BOOT && ",
            "mcopy -i ", hdd_path, "@@1M ", limine_path.getPath(b), "/BOOTAA64.EFI ::/EFI/BOOT && ",
            "mcopy -i ", hdd_path, "@@1M ", limine_path.getPath(b), "/BOOTRISCV64.EFI ::/EFI/BOOT && ",
            "mcopy -i ", hdd_path, "@@1M ", limine_path.getPath(b), "/BOOTLOONGARCH64.EFI ::/EFI/BOOT",
        }),
        // zig fmt: on
    };

    const hdd_cmd = b.addSystemCommand(cmd);
    hdd_cmd.step.dependOn(b.getInstallStep());

    limine_exe_run.addArg(hdd_path); // FIXME: this probably should be addFileArg
    limine_exe_run.step.dependOn(&hdd_cmd.step);

    return &limine_exe_run.step;
}

fn edk2FileName(b: *std.Build, arch: std.Target.Cpu.Arch) ![]const u8 {
    return b.cache_root.join(b.allocator, &[_][]const u8 { b.fmt("edk2-{s}.fd", .{@tagName(arch)}) });
}

fn downloadEdk2(b: *std.Build, arch: std.Target.Cpu.Arch) !void {
    const link = switch (arch) {
        .x86_64 => "https://retrage.github.io/edk2-nightly/bin/RELEASEX64_OVMF.fd",
        .aarch64 => "https://retrage.github.io/edk2-nightly/bin/RELEASEAARCH64_QEMU_EFI.fd",
        .riscv64 => "https://retrage.github.io/edk2-nightly/bin/RELEASERISCV64_VIRT.fd",
        .loongarch64 => "https://retrage.github.io/edk2-nightly/bin/RELEASELOONGARCH64_QEMU_EFI.fd",
        else => return error.UnsupportedArchitecture,
    };

    const cmd = &[_][]const u8{
        // zig fmt: off
        "/bin/sh", "-c",
        try std.mem.concat(b.allocator, u8, &[_][]const u8{
            "curl ", link, " -Lo ", try edk2FileName(b, arch), " && ",
            "truncate -s 64M ", try edk2FileName(b, arch), // needed to work on aarch64
        }),
        // zig fmt: on
    };
    var child_proc = std.process.Child.init(cmd, b.allocator);
    try child_proc.spawn();
    const ret_val = try child_proc.wait();
    try std.testing.expectEqual(ret_val, std.process.Child.Term{ .Exited = 0 });
}

fn runIsoQemu(b: *std.Build, iso: *std.Build.Step, arch: std.Target.Cpu.Arch) !*std.Build.Step {
    _ = std.fs.cwd().statFile(try edk2FileName(b, arch)) catch try downloadEdk2(b, arch);

    const qemu_executable = switch (arch) {
        .x86_64 => "qemu-system-x86_64",
        .aarch64 => "qemu-system-aarch64",
        .riscv64 => "qemu-system-riscv64",
        .loongarch64 => "qemu-system-loongarch64",
        else => return error.UnsupportedArchitecture,
    };

    const qemu_iso_args = switch (arch) {
        .x86_64 => &[_][]const u8{
            // zig fmt: off
            qemu_executable,
            //"-s", "-S",
            "-cpu", "max",
            "-smp", "2",
            "-M", "q35,accel=kvm:whpx:hvf:tcg",
            "-m", "2G",
            "-cdrom", b.getInstallPath(.{ .custom = "iso" }, "template.iso"),
            "-drive", b.fmt("if=pflash,unit=0,format=raw,file={s},readonly=on", .{try edk2FileName(b, arch)}),
            "-boot", "d",
            // zig fmt: on
        },
        .aarch64, .riscv64, .loongarch64 => &[_][]const u8{
            // zig fmt: off
            qemu_executable,
            //"-s", "-S",
            "-cpu", "max",
            "-smp", "2",
            "-M", "virt,accel=kvm:whpx:hvf:tcg",
            "-m", "2G",
            "-device", "ramfb",
            "-device", "qemu-xhci",
            "-device", "usb-kbd",
            "-device", "usb-mouse",
            "-cdrom", b.getInstallPath(.{ .custom = "iso" }, "template.iso"),
            "-drive", b.fmt("if=pflash,unit=0,format=raw,file={s},readonly=on", .{try edk2FileName(b, arch)}),
            "-boot", "d",
            // zig fmt: on
        },
        else => return error.UnsupportedArchitecture,
    };

    const qemu_iso_cmd = b.addSystemCommand(qemu_iso_args);
    qemu_iso_cmd.step.dependOn(iso);

    return &qemu_iso_cmd.step;
}

fn runHddQemu(b: *std.Build, hdd: *std.Build.Step, arch: std.Target.Cpu.Arch) !*std.Build.Step {
    _ = std.fs.cwd().statFile(try edk2FileName(b, arch)) catch try downloadEdk2(b, arch);

    const qemu_executable = switch (arch) {
        .x86_64 => "qemu-system-x86_64",
        .aarch64 => "qemu-system-aarch64",
        .riscv64 => "qemu-system-riscv64",
        .loongarch64 => "qemu-system-loongarch64",
        else => return error.UnsupportedArchitecture,
    };

    const qemu_hdd_args = switch (arch) {
        .x86_64 => &[_][]const u8{
            // zig fmt: off
            qemu_executable,
            //"-s", "-S",
            "-cpu", "max",
            "-smp", "2",
            "-M", "q35,accel=kvm:whpx:hvf:tcg",
            "-m", "2G",
            "-hda", b.getInstallPath(.{ .custom = "hdd" }, "template.hdd"),
            "-drive", b.fmt("if=pflash,unit=0,format=raw,file={s},readonly=on", .{try edk2FileName(b, arch)}),
            "-boot", "d",
            // zig fmt: on
        },
        .aarch64, .riscv64, .loongarch64 => &[_][]const u8{
            // zig fmt: off
            qemu_executable,
            //"-s", "-S",
            "-cpu", "max",
            "-smp", "2",
            "-M", "virt,accel=kvm:whpx:hvf:tcg",
            "-m", "2G",
            "-hda", b.getInstallPath(.{ .custom = "hdd" }, "template.hdd"),
            "-drive", b.fmt("if=pflash,unit=0,format=raw,file={s},readonly=on", .{try edk2FileName(b, arch)}),
            "-device", "ramfb",
            "-boot", "d",
            // zig fmt: on
        },
        else => return error.UnsupportedArchitecture,
    };

    const qemu_hdd_cmd = b.addSystemCommand(qemu_hdd_args);
    qemu_hdd_cmd.step.dependOn(hdd);

    return &qemu_hdd_cmd.step;
}
