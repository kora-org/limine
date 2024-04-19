const std = @import("std");
const builtin = @import("builtin");

pub const COMMON_MAGIC = .{ 0xc7b1dd30df4c8b88, 0x0a82e883a194f07b };

pub const Identifiers = struct {
    pub const BootloaderInfo = COMMON_MAGIC ++ .{ 0xf55038d8e2a1202f, 0x279426fcf5f59740 };
    pub const StackSize = COMMON_MAGIC ++ .{ 0x224ef0460a8e8926, 0xe1cb0fc25f46ea3d };
    pub const Hhdm = COMMON_MAGIC ++ .{ 0x48dcf1cb8ad2b852, 0x63984e959a98244b };
    pub const Framebuffer = COMMON_MAGIC ++ .{ 0x9d5827dcd881dd75, 0xa3148604f6fab11b };
    pub const PagingMode = COMMON_MAGIC ++ .{ 0x95c1a0edab0944cb, 0xa4e5cb3842f7488a };
    pub const Smp = COMMON_MAGIC ++ .{ 0x95a67b819a1b857e, 0xa0b61b723b6a73e0 };
    pub const MemoryMap = COMMON_MAGIC ++ .{ 0x67cf3d9d378a806f, 0xe304acdfc50c3c62 };
    pub const EntryPoint = COMMON_MAGIC ++ .{ 0x13d86c035a1cd3e1, 0x2b0caa89d8f3026a };
    pub const KernelFile = COMMON_MAGIC ++ .{ 0xad97e90e83f1ed67, 0x31eb5d1c5ff23b69 };
    pub const Module = COMMON_MAGIC ++ .{ 0x3e7e279702be32af, 0xca1c4f3bd1280cee };
    pub const Rsdp = COMMON_MAGIC ++ .{ 0xc5e77b6b397e7b43, 0x27637845accdcf3c };
    pub const Smbios = COMMON_MAGIC ++ .{ 0x9e9046f11e095391, 0xaa4a520fefbde5ee };
    pub const EfiSystemTable = COMMON_MAGIC ++ .{ 0x5ceba5163eaaf6d6, 0x0a6981610cf65fcc };
    pub const EfiMemoryMap = COMMON_MAGIC ++ .{ 0x7df62a431d6872d5, 0xa4fcdfb3e57306c8 };
    pub const BootTime = COMMON_MAGIC ++ .{ 0x502746e184c088aa, 0xfbc5ec83e6327893 };
    pub const KernelAddress = COMMON_MAGIC ++ .{ 0x71ba76863cc55f63, 0xb2644a48c516a487 };
    pub const DeviceTree = COMMON_MAGIC ++ .{ 0xb40ddb48fb54bac7, 0x545081493f81ffb7 };
};

pub const Uuid = struct {
    a: u32,
    b: u16,
    c: u16,
    d: [8]u8,
};

pub const File = struct {
    /// The revision of the file.
    revision: u64,
    /// The address of the file.
    base: u64,
    /// The size of the file.
    length: u64,
    /// The path of the file within the volume, with a leading slash.
    path: []const u8,
    /// A command line associated with the file.
    cmdline: []const u8,
    /// Type of media file resides on.
    media_type: MediaTypes,
    _unused: u32,
    /// If non-0, this is the IP of the TFTP server the file was loaded
    /// from.
    tftp_ip: u32,
    /// Likewise, but port.
    tftp_port: u32,
    /// 1-based partition index of the volume from which the file was
    /// loaded. If 0, it means invalid or unpartitioned.
    partiton_index: u32,
    /// If non-0, this is the ID of the disk the file was loaded from as
    /// reported in its MBR.
    mbr_disk_id: u32,
    /// If non-0, this is the UUID of the disk the file was loaded from as
    /// reported in its GPT.
    gpt_disk_uuid: Uuid,
    /// If non-0, this is the UUID of the partition the file was loaded
    /// from as reported in the GPT.
    gpt_part_uuid: Uuid,
    /// If non-0, this is the UUID of the filesystem of the partition
    /// the file was loaded from.
    part_uuid: Uuid,

    pub const MediaTypes = enum {
        Generic,
        Optical,
        Tftp,
    };

    /// Returns a slice of the file.
    pub fn getSlice(self: *const @This()) []const u8 {
        return @as([*]u8, @ptrCast(self.base))[0..self.length];
    }

    /// Returns the Zig string version of the path.
    pub fn getPath(self: *const @This()) [:0]const u8 {
        return std.mem.sliceTo(self.path, 0);
    }

    /// Returns the Zig string version of the command line.
    pub fn getCmdline(self: *const @This()) [:0]const u8 {
        return std.mem.sliceTo(self.cmdline, 0);
    }
};

pub const BootloaderInfo = struct {
    pub const Request = extern struct {
        /// The ID of the request.
        id: [4]u64 = Identifiers.BootloaderInfo,
        /// The revision of the request that the kernel provides.
        revision: u64 = 0,
        /// The pointer to the response structure.
        response: ?*const Response = null,
    };

    pub const Response = extern struct {
        /// The revision of the response that the bootloader provides.
        revision: u64 = 0,
        /// Zero-terminated ASCII strings containing the name of the
        /// loading bootloader.
        name: [*:0]const u8,
        /// Zero-terminated ASCII strings containing the version of the
        /// loading bootloader.
        version: [*:0]const u8,

        /// Returns the Zig string version of the bootloader name.
        pub fn getName(self: *const @This()) [:0]const u8 {
            return std.mem.sliceTo(self.name, 0);
        }

        /// Returns the Zig string version of the bootloader version.
        pub fn getVersion(self: *const @This()) [:0]const u8 {
            return std.mem.sliceTo(self.version, 0);
        }
    };
};

pub const StackSize = struct {
    pub const Request = extern struct {
        /// The ID of the request.
        id: [4]u64 = Identifiers.StackSize,
        /// The revision of the request that the kernel provides.
        revision: u64 = 0,
        /// The pointer to the response structure.
        response: ?*const Response = null,
        /// The requested stack size (also used for SMP processors).
        stack_size: u64,
    };

    pub const Response = extern struct {
        /// The revision of the response that the bootloader provides.
        revision: u64 = 0,
    };
};

pub const Hhdm = struct {
    pub const Request = extern struct {
        /// The ID of the request.
        id: [4]u64 = Identifiers.Hhdm,
        /// The revision of the request that the kernel provides.
        revision: u64 = 0,
        /// The pointer to the response structure.
        response: ?*const Response = null,
    };

    pub const Response = extern struct {
        /// The revision of the response that the bootloader provides.
        revision: u64 = 0,
        /// The virtual address offset of the beginning of the higher half
        /// direct map.
        offset: u64,
    };
};

pub const Framebuffer = struct {
    pub const Request = extern struct {
        /// The ID of the request.
        id: [4]u64 = Identifiers.Framebuffer,
        /// The revision of the request that the kernel provides.
        revision: u64 = 1,
        /// The pointer to the response structure.
        response: ?*const Response = null,
    };

    pub const Response = extern struct {
        /// The revision of the response that the bootloader provides.
        revision: u64 = 1,
        /// How many framebuffers are present.
        framebuffer_count: u64,
        /// Pointer to an array of `framebuffer_count` pointers to `Fb`
        /// structures.
        framebuffers: [*]*Fb,

        /// Returns a slice of the `framebuffers` array.
        pub fn getFramebuffers(self: *const @This()) []*Fb {
            return self.framebuffers[0..self.framebuffer_count];
        }
    };

    pub const Fb = extern struct {
        /// Address to the framebuffer
        address: u64,
        /// Width of the framebuffer in pixels
        width: u64,
        /// Height of the framebuffer in pixels
        height: u64,
        /// Pitch of the framebuffer in bytes
        pitch: u64,
        /// Bits per pixel of the framebuffer
        bpp: u16,
        memory_model: MemoryModel,
        red_mask_size: u8,
        red_mask_shift: u8,
        green_mask_size: u8,
        green_mask_shift: u8,
        blue_mask_size: u8,
        blue_mask_shift: u8,
        _unused: [7]u8,
        edid_size: u64,
        edid: ?[*]const u8,

        // Revision 1
        /// How many video modes are present
        mode_count: u64,
        /// Pointer to an array of `mode_count` pointers to `VideoMode`
        /// structures.
        modes: ?[*]*VideoMode,

        /// Returns a slice of the `modes` array.
        pub fn getVideoModes(self: *const @This()) ?[]*VideoMode {
            if (self.modes) |modes|
                return modes[0..self.mode_count];
        }

        pub const VideoMode = extern struct {
            /// Pitch of the framebuffer in bytes
            pitch: u64,
            /// Width of the framebuffer in pixels
            width: u64,
            /// Height of the framebuffer in pixels
            height: u64,
            /// Bits per pixel of the framebuffer
            bpp: u16,
            memory_model: MemoryModel,
            red_mask_size: u8,
            red_mask_shift: u8,
            green_mask_size: u8,
            green_mask_shift: u8,
            blue_mask_size: u8,
            blue_mask_shift: u8,
        };

        /// Returns a slice of the `address` pointer.
        pub fn getSlice(self: *const @This(), comptime T: type) []T {
            return @as([*]T, @ptrFromInt(self.address))[0 .. (self.pitch / @sizeOf(T)) * self.width];
        }

        /// Returns the EDID data.
        pub fn getEdid(self: *const @This()) ?[]const u8 {
            if (self.edid) |edid| {
                return edid[0..self.edid_size];
            }
            return null;
        }

        pub const MemoryModel = enum(u8) {
            Rgb = 1,
            _,
        };
    };
};

pub const PagingMode = struct {
    pub const Request = extern struct {
        /// The ID of the request.
        id: [4]u64 = Identifiers.PagingMode,
        /// The revision of the request that the kernel provides.
        revision: u64 = 0,
        /// The pointer to the response structure.
        response: ?*const Response = null,
        /// The paging mode the kernel will use
        mode: Mode = switch (builtin.cpu.arch) {
            .x86_64, .aarch64 => .FourLevel,
            .riscv64 => .Sv48,
            else => unreachable,
        },
        /// Flags that literally does nothing. I don't know why the hell
        /// is it included even though there's no flags in the first place
        /// but it's mintsuki's decision and not mine so.
        flags: u64 = 0,
    };

    pub const Response = extern struct {
        /// The revision of the response that the bootloader provides.
        revision: u64 = 0,
    };

    pub const Mode = switch (builtin.cpu.arch) {
        .x86_64, .aarch64 => enum(u64) {
            /// 4-level paging
            FourLevel,
            /// 5-level paging
            FiveLevel,
        },
        .riscv64 => enum(u64) {
            Sv32,
            Sv48,
            Sv57,
        },
        else => unreachable,
    };
};

pub const Smp = struct {
    pub const Request = extern struct {
        /// The ID of the request.
        id: [4]u64 = Identifiers.Smp,
        /// The revision of the request that the kernel provides.
        revision: u64 = 0,
        /// The pointer to the response structure.
        response: ?*const Response = null,
        /// Bit 0: Enable X2APIC, if possible. (x86-64 only)
        flags: u64 = 0,
    };

    pub const Response = switch (builtin.cpu.arch) {
        .x86_64 => extern struct {
            /// The revision of the response that the bootloader provides.
            revision: u64 = 0,
            /// Bit 0: X2APIC has been enabled.
            flags: u32,
            /// The Local APIC ID of the bootstrap processor.
            bsp_lapic_id: u32,
            /// How many CPUs are present. It includes the bootstrap
            /// processor.
            cpu_count: u64,
            /// Pointer to an array of `cpu_count` pointers to `Cpu`
            /// structures.
            cpus: [*]*Cpu,

            /// Returns a slice of the `cpus` array.
            pub fn getCpus(self: *const @This()) []*Cpu {
                return self.cpus[0..self.cpu_count];
            }
        },
        .aarch64 => extern struct {
            /// The revision of the response that the bootloader provides.
            revision: u64 = 0,
            /// Always zero.
            flags: u32,
            /// MPIDR of the bootstrap processor (as read from `MPIDR_EL1`,
            /// with Res1 masked off).
            bsp_mpidr: u64,
            /// How many CPUs are present. It includes the bootstrap
            /// processor.
            cpu_count: u64,
            /// Pointer to an array of `cpu_count` pointers to `Cpu`
            /// structures.
            cpus: [*]*Cpu,

            /// Returns a slice of the `cpus` array.
            pub fn getCpus(self: *const @This()) []*Cpu {
                return self.cpus[0..self.cpu_count];
            }
        },
        .riscv64 => extern struct {
            /// The revision of the response that the bootloader provides.
            revision: u64 = 0,
            /// Always zero.
            flags: u32,
            /// Hart ID of the bootstrap processor as reported by the UEFI
            /// RISC-V Boot Protocol or the SBI.
            bsp_hart_id: u64,
            /// How many CPUs are present. It includes the bootstrap
            /// processor.
            cpu_count: u64,
            /// Pointer to an array of `cpu_count` pointers to `Cpu`
            /// structures.
            cpus: [*]*Cpu,

            /// Returns a slice of the `cpus` array.
            pub fn getCpus(self: *const @This()) []*Cpu {
                return self.cpus[0..self.cpu_count];
            }
        },
        else => unreachable,
    };

    pub const Cpu = switch (builtin.cpu.arch) {
        .x86_64 => extern struct {
            /// ACPI Processor UID as specified by the MADT
            processor_id: u32,
            /// Local APIC ID of the processor as specified by the MADT
            lapic_id: u32,
            reserved: u64,
            /// An atomic write to this field causes the parked CPU to
            /// jump to the written address, on a 64KiB (or Stack Size
            /// Request size) stack.
            goto: *const fn (*Cpu) callconv(.C) void,
            /// A free for use field.
            extra_argument: u64,
        },
        .aarch64 => extern struct {
            /// ACPI Processor UID as specified by the MADT
            processor_id: u32,
            /// GIC CPU Interface number of the processor as specified by
            /// the MADT (possibly always 0)
            gic_iface_num: u32,
            /// MPIDR of the processor as specified by the MADT or device
            /// tree
            mpidr: u64,
            reserved: u64,
            /// An atomic write to this field causes the parked CPU to
            /// jump to the written address, on a 64KiB (or Stack Size
            /// Request size) stack.
            goto: *const fn (*Cpu) callconv(.C) void,
            /// A free for use field.
            extra_argument: u64,
        },
        .riscv64 => extern struct {
            /// ACPI Processor UID as specified by the MADT (always 0 on
            /// non-ACPI systems).
            processor_id: u32,
            /// Hart ID of the processor as specified by the MADT or
            /// device tree.
            hart_id: u64,
            reserved: u64,
            /// An atomic write to this field causes the parked CPU to
            /// jump to the written address, on a 64KiB (or Stack Size
            /// Request size) stack.
            goto: *const fn (*Cpu) callconv(.C) void,
            /// A free for use field.
            extra_argument: u64,
        },
        else => unreachable,
    };
};

pub const MemoryMap = struct {
    pub const Request = extern struct {
        /// The ID of the request.
        id: [4]u64 = Identifiers.MemoryMap,
        /// The revision of the request that the kernel provides.
        revision: u64 = 0,
        /// The pointer to the response structure.
        response: ?*const Response = null,
    };

    pub const Response = extern struct {
        /// The revision of the response that the bootloader provides.
        revision: u64 = 0,
        /// How many memory map entries are present.
        entry_count: u64,
        /// Pointer to an array of `entry_count` pointers to `Entry`
        /// structures.
        entries: [*]*Entry,

        /// Returns a slice of the `entries` array.
        pub fn getEntries(self: *const @This()) []*Entry {
            return self.entries[0..self.entry_count];
        }
    };

    pub const Entry = extern struct {
        base: u64,
        length: u64,
        type: Types,
    };

    pub const Types = enum(u64) {
        Usable,
        Reserved,
        AcpiReclaimable,
        AcpiNvs,
        BadMemory,
        BootloaderReclaimable,
        KernelAndModules,
        Framebuffer,
    };
};

pub const EntryPoint = struct {
    pub const Request = extern struct {
        /// The ID of the request.
        id: [4]u64 = Identifiers.EntryPoint,
        /// The revision of the request that the kernel provides.
        revision: u64 = 0,
        /// The pointer to the response structure.
        response: ?*const Response = null,
        /// The requested entry point.
        entry_point: *const fn () callconv(.C) void,
    };

    pub const Response = extern struct {
        /// The revision of the response that the bootloader provides.
        revision: u64 = 0,
    };
};

pub const KernelFile = struct {
    pub const Request = extern struct {
        /// The ID of the request.
        id: [4]u64 = Identifiers.KernelFile,
        /// The revision of the request that the kernel provides.
        revision: u64 = 0,
        /// The pointer to the response structure.
        response: ?*const Response = null,
    };

    pub const Response = extern struct {
        /// The revision of the response that the bootloader provides.
        revision: u64 = 0,
        /// Pointer to the kernel file.
        kernel_file: *File,
    };
};

pub const Module = struct {
    pub const Request = extern struct {
        /// The ID of the request.
        id: [4]u64 = Identifiers.Module,
        /// The revision of the request that the kernel provides.
        revision: u64 = 0,
        /// The pointer to the response structure.
        response: ?*const Response = null,

        // Revision 1
        /// How many internal modules are passed by the kernel.
        internal_module_count: u64 = 0,
        /// Pointer to an array of `internal_module_count` pointers
        /// to `InternalModule` structures.
        internal_modules: ?[*]*InternalModule = null,
    };

    pub const Response = extern struct {
        /// The revision of the response that the bootloader provides.
        revision: u64 = 0,
        /// How many modules are present.
        module_count: u64,
        /// Pointer to an array of `module_count` pointers to the
        /// currently loaded modules.
        modules: [*]*File,

        /// Returns a slice of the `modules` array.
        pub fn getModules(self: *const @This()) []*File {
            return self.modules[0..self.module_count];
        }
    };

    pub const InternalModule = extern struct {
        /// The path of the file within the volume, with a leading slash.
        path: []const u8,
        /// A command line associated with the file.
        cmdline: []const u8,
        /// Flags changing module loading behavior.
        flags: Flags = .{},

        pub const Flags = packed struct {
            Required: bool = 0,
            // Revision 2
            Compressed: bool = 0,
        };

        /// Returns the Zig string version of the path.
        pub fn getPath(self: *const @This()) [:0]const u8 {
            return std.mem.sliceTo(self.path, 0);
        }

        /// Returns the Zig string version of the command line.
        pub fn getCmdline(self: *const @This()) [:0]const u8 {
            return std.mem.sliceTo(self.cmdline, 0);
        }
    };
};

pub const Rsdp = struct {
    pub const Request = extern struct {
        /// The ID of the request.
        id: [4]u64 = Identifiers.Rsdp,
        /// The revision of the request that the kernel provides.
        revision: u64 = 0,
        /// The pointer to the response structure.
        response: ?*const Response = null,
    };

    pub const Response = extern struct {
        /// The revision of the response that the bootloader provides.
        revision: u64 = 0,
        /// Address of the RSDP table.
        address: u64,
    };
};

pub const Smbios = struct {
    pub const Request = extern struct {
        /// The ID of the request.
        id: [4]u64 = Identifiers.Smbios,
        /// The revision of the request that the kernel provides.
        revision: u64 = 0,
        /// The pointer to the response structure.
        response: ?*const Response = null,
    };

    pub const Response = extern struct {
        /// The revision of the response that the bootloader provides.
        revision: u64 = 0,
        /// Address of the 32-bit SMBIOS entry point. 0 if not present.
        entry_32: u64,
        /// Address of the 64-bit SMBIOS entry point. 0 if not present.
        entry_64: u64,
    };
};

pub const EfiSystemTable = struct {
    pub const Request = extern struct {
        /// The ID of the request.
        id: [4]u64 = Identifiers.EfiSystemTable,
        /// The revision of the request that the kernel provides.
        revision: u64 = 0,
        /// The pointer to the response structure.
        response: ?*const Response = null,
    };

    pub const Response = extern struct {
        /// The revision of the response that the bootloader provides.
        revision: u64 = 0,
        /// Pointer to the EFI system table. `null` if not present.
        system_table: ?*std.os.uefi.tables.SystemTable = null,
    };
};

pub const EfiMemoryMap = struct {
    pub const Request = extern struct {
        /// The ID of the request.
        id: [4]u64 = Identifiers.EfiMemoryMap,
        /// The revision of the request that the kernel provides.
        revision: u64 = 0,
        /// The pointer to the response structure.
        response: ?*const Response = null,
    };

    pub const Response = extern struct {
        /// The revision of the response that the bootloader provides.
        revision: u64 = 0,
        /// Pointer (HHDM) to the EFI memory map.
        memmap: [*]std.os.uefi.tables.MemoryDescriptor,
        /// Size in bytes of the EFI memory map.
        memmap_size: u64,
        /// EFI memory map descriptor size in bytes.
        desc_size: u64,
        /// Version of EFI memory map descriptors.
        desc_version: u64,
    };
};

pub const BootTime = struct {
    pub const Request = extern struct {
        /// The ID of the request.
        id: [4]u64 = Identifiers.BootTime,
        /// The revision of the request that the kernel provides.
        revision: u64 = 0,
        /// The pointer to the response structure.
        response: ?*const Response = null,
    };

    pub const Response = extern struct {
        /// The revision of the response that the bootloader provides.
        revision: u64 = 0,
        /// The UNIX time on boot, in seconds, taken from the system RTC.
        boot_time: i64,
    };
};

pub const KernelAddress = struct {
    pub const Request = extern struct {
        /// The ID of the request.
        id: [4]u64 = Identifiers.KernelAddress,
        /// The revision of the request that the kernel provides.
        revision: u64 = 0,
        /// The pointer to the response structure.
        response: ?*const Response = null,
    };

    pub const Response = extern struct {
        /// The revision of the response that the bootloader provides.
        revision: u64 = 0,
        /// The physical base address of the kernel.
        physical_base: u64,
        /// The virtual base address of the kernel.
        virtual_base: u64,
    };
};

pub const DeviceTree = struct {
    pub const Request = extern struct {
        /// The ID of the request.
        id: [4]u64 = Identifiers.DeviceTree,
        /// The revision of the request that the kernel provides.
        revision: u64 = 0,
        /// The pointer to the response structure.
        response: ?*const Response = null,
    };

    pub const Response = extern struct {
        /// The revision of the response that the bootloader provides.
        revision: u64 = 0,
        /// Virtual pointer to the device tree blob. 0 if not present.
        address: u64 = 0,
    };
};

test "docs" {
    // this is a dummy test function for docs generation
    // im too lazy to write actual tests

    std.testing.refAllDecls(@This());
}
