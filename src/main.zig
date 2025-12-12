const std = @import("std");
const builtin = @import("builtin");

pub const common_magic = .{ 0xc7b1dd30df4c8b88, 0x0a82e883a194f07b };

pub const requests_start_marker: [4]u64 = .{ 0xf6b8f4b39de7d1ae, 0xfab91a6940fcb9cf, 0x785c6ed015d3e316, 0x181e920a7852b9d9 };
pub const requests_end_marker: [2]u64 = .{ 0xadc0e0531bb10d03, 0x9572709f31764c62 };

pub inline fn baseRevision(n: comptime_int) [3]u64 {
    return .{ 0xf9562b2d5c95a6c8, 0x6a7b384944536bdc, n };
}

pub inline fn baseRevisionSupported(rev: []u64) bool {
    return rev[2] == 0;
}

pub inline fn loadedBaseRevisionValid(rev: []u64) bool {
    return rev[1] != 0x6a7b384944536bdc;
}

pub inline fn loadedBaseRevision(rev: []u64) u64 {
    return rev[1];
}

pub const Identifiers = struct {
    pub const BootloaderInfo = common_magic ++ .{ 0xf55038d8e2a1202f, 0x279426fcf5f59740 };
    pub const ExecutableCmdline = common_magic ++ .{ 0x4b161536e598651e, 0xb390ad4a2f1f303a };
    pub const FirmwareType = common_magic ++ .{ 0x8c2f75d90bef28a8, 0x7045a4688eac00c3 };
    pub const StackSize = common_magic ++ .{ 0x224ef0460a8e8926, 0xe1cb0fc25f46ea3d };
    pub const Hhdm = common_magic ++ .{ 0x48dcf1cb8ad2b852, 0x63984e959a98244b };
    pub const Framebuffer = common_magic ++ .{ 0x9d5827dcd881dd75, 0xa3148604f6fab11b };
    pub const PagingMode = common_magic ++ .{ 0x95c1a0edab0944cb, 0xa4e5cb3842f7488a };
    pub const Multiprocessor = common_magic ++ .{ 0x95a67b819a1b857e, 0xa0b61b723b6a73e0 };
    pub const MemoryMap = common_magic ++ .{ 0x67cf3d9d378a806f, 0xe304acdfc50c3c62 };
    pub const EntryPoint = common_magic ++ .{ 0x13d86c035a1cd3e1, 0x2b0caa89d8f3026a };
    pub const ExecutableFile = common_magic ++ .{ 0xad97e90e83f1ed67, 0x31eb5d1c5ff23b69 };
    pub const Module = common_magic ++ .{ 0x3e7e279702be32af, 0xca1c4f3bd1280cee };
    pub const Rsdp = common_magic ++ .{ 0xc5e77b6b397e7b43, 0x27637845accdcf3c };
    pub const Smbios = common_magic ++ .{ 0x9e9046f11e095391, 0xaa4a520fefbde5ee };
    pub const EfiSystemTable = common_magic ++ .{ 0x5ceba5163eaaf6d6, 0x0a6981610cf65fcc };
    pub const EfiMemoryMap = common_magic ++ .{ 0x7df62a431d6872d5, 0xa4fcdfb3e57306c8 };
    pub const DateAtBoot = common_magic ++ .{ 0x502746e184c088aa, 0xfbc5ec83e6327893 };
    pub const ExecutableAddress = common_magic ++ .{ 0x71ba76863cc55f63, 0xb2644a48c516a487 };
    pub const DeviceTree = common_magic ++ .{ 0xb40ddb48fb54bac7, 0x545081493f81ffb7 };
    pub const RiscvBspHartId = common_magic ++ .{ 0x1369359f025525f9, 0x2ff2a56178391bb6 };
    pub const BootloaderPerformance = common_magic ++ .{ 0x6b50ad9bf36d13ad, 0xdc4c7e88fc759e17 };
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
    address: u64,
    /// The size of the file.
    size: u64,
    /// The path of the file within the volume, with a leading slash.
    path: [*:0]const u8,
    /// A string associated with the file.
    string: [*:0]const u8,
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
    partition_index: u32,
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

    pub const MediaTypes = enum(u32) {
        generic,
        optical,
        tftp,
    };

    /// Returns a slice of the file.
    pub fn getSlice(self: *const File) []const u8 {
        return @as([*]const u8, @ptrFromInt(self.address))[0..self.size];
    }

    /// Returns the Zig string version of the path.
    pub fn getPath(self: *const File) [:0]const u8 {
        return std.mem.sliceTo(self.path, 0);
    }

    /// Returns the Zig string version of the string.
    pub fn getString(self: *const File) [:0]const u8 {
        return std.mem.sliceTo(self.string, 0);
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
        pub fn getName(self: *const Response) [:0]const u8 {
            return std.mem.sliceTo(self.name, 0);
        }

        /// Returns the Zig string version of the bootloader version.
        pub fn getVersion(self: *const Response) [:0]const u8 {
            return std.mem.sliceTo(self.version, 0);
        }
    };
};

pub const ExecutableCmdline = struct {
    pub const Request = extern struct {
        /// The ID of the request.
        id: [4]u64 = Identifiers.ExecutableCmdline,
        /// The revision of the request that the kernel provides.
        revision: u64 = 0,
        /// The pointer to the response structure.
        response: ?*const Response = null,
    };

    pub const Response = extern struct {
        /// The revision of the response that the bootloader provides.
        revision: u64 = 0,
        /// A command line associated with the booted executable.
        cmdline: [*:0]const u8,

        /// Returns the Zig string version of the command line.
        pub fn getCmdline(self: *const Response) [:0]const u8 {
            return std.mem.sliceTo(self.cmdline, 0);
        }
    };
};

pub const FirmwareType = struct {
    pub const Request = extern struct {
        /// The ID of the request.
        id: [4]u64 = Identifiers.FirmwareType,
        /// The revision of the request that the kernel provides.
        revision: u64 = 0,
        /// The pointer to the response structure.
        response: ?*const Response = null,
    };

    pub const Response = extern struct {
        /// The revision of the response that the bootloader provides.
        revision: u64 = 0,
        /// The firmware type used by the bootloader
        type: Type = .x86_bios,
    };

    pub const Type = enum(u64) {
        x86_bios = 0,
        uefi32 = 1,
        uefi64 = 2,
        sbi = 3,
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
        /// The requested stack size (also used for MP processors).
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
        pub fn getFramebuffers(self: *const Response) []*Fb {
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
        pub fn getVideoModes(self: *const Fb) ?[]*VideoMode {
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
            rgb = 1,
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
            .x86_64, .aarch64, .loongarch64 => .four_level,
            .riscv64 => .sv48,
            else => unreachable,
        },

        // Revision 1
        /// The highest paging mode in numerical order that the OS supports.
        max_mode: Mode = switch (builtin.cpu.arch) {
            .x86_64, .aarch64 => .five_level,
            .riscv64 => .sv57,
            .loongarch64 => .four_level,
            else => unreachable,
        },
        /// The lowest paging mode in numerical order that the OS supports.
        min_mode: Mode = switch (builtin.cpu.arch) {
            .x86_64, .aarch64, .loongarch64 => .four_level,
            .riscv64 => .sv39,
            else => unreachable,
        },
    };

    pub const Response = extern struct {
        /// The revision of the response that the bootloader provides.
        revision: u64 = 0,
        /// The paging mode that was actually enabled.
        mode: Mode,
    };

    pub const Mode = switch (builtin.cpu.arch) {
        .x86_64, .aarch64 => enum(u64) {
            /// 4-level paging
            four_level,
            /// 5-level paging
            five_level,
        },
        .riscv64 => enum(u64) {
            sv39,
            sv48,
            sv57,
        },
        .loongarch64 => enum(u64) {
            /// 4-level paging
            four_level,
        },
        else => u64,
    };
};

pub const Smp = Multiprocessor;
pub const Multiprocessor = struct {
    pub const Request = extern struct {
        /// The ID of the request.
        id: [4]u64 = Identifiers.Multiprocessor,
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
            pub fn getCpus(self: *const Response) []*Cpu {
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
            pub fn getCpus(self: *const Response) []*Cpu {
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
            pub fn getCpus(self: *const Response) []*Cpu {
                return self.cpus[0..self.cpu_count];
            }
        },
        else => extern struct {
            revision: u64 = 0,
        },
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
            goto: *const fn (*Cpu) callconv(.c) void,
            /// A free for use field.
            extra_argument: u64,
        },
        .aarch64 => extern struct {
            /// ACPI Processor UID as specified by the MADT
            processor_id: u32,
            reserved1: u32,
            /// MPIDR of the processor as specified by the MADT or device
            /// tree
            mpidr: u64,
            reserved: u64,
            /// An atomic write to this field causes the parked CPU to
            /// jump to the written address, on a 64KiB (or Stack Size
            /// Request size) stack.
            goto: *const fn (*Cpu) callconv(.c) void,
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
            goto: *const fn (*Cpu) callconv(.c) void,
            /// A free for use field.
            extra_argument: u64,
        },
        else => extern struct {
            reserved: u64,
        },
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
        pub fn getEntries(self: *const Response) []*Entry {
            return self.entries[0..self.entry_count];
        }
    };

    pub const Entry = extern struct {
        base: u64,
        length: u64,
        type: Types,
    };

    pub const Types = enum(u64) {
        usable,
        reserved,
        acpi_reclaimable,
        acpi_nvs,
        bad_memory,
        bootloader_reclaimable,
        kernel_and_modules,
        framebuffer,
        acpi_tables,
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
        entry_point: *const fn () callconv(.c) void,
    };

    pub const Response = extern struct {
        /// The revision of the response that the bootloader provides.
        revision: u64 = 0,
    };
};

pub const KernelFile = ExecutableFile;
pub const ExecutableFile = struct {
    pub const Request = extern struct {
        /// The ID of the request.
        id: [4]u64 = Identifiers.ExecutableFile,
        /// The revision of the request that the kernel provides.
        revision: u64 = 0,
        /// The pointer to the response structure.
        response: ?*const Response = null,
    };

    pub const Response = extern struct {
        /// The revision of the response that the bootloader provides.
        revision: u64 = 0,
        /// Pointer to the executable file.
        executable_file: *File,
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
        pub fn getModules(self: *const Response) []*File {
            return self.modules[0..self.module_count];
        }
    };

    pub const InternalModule = extern struct {
        /// The path of the file within the volume, with a leading slash.
        path: [*:0]const u8,
        /// A string associated with the file.
        string: [*:0]const u8,
        /// Flags changing module loading behavior.
        flags: Flags = .{},

        pub const Flags = packed struct(u64) {
            Required: bool = false,
            Compressed: bool = false,
            _padding: u62 = 0,
        };

        /// Returns the Zig string version of the path.
        pub fn getPath(self: *const InternalModule) [:0]const u8 {
            return std.mem.sliceTo(self.path, 0);
        }

        /// Returns the Zig string version of the string.
        pub fn getString(self: *const InternalModule) [:0]const u8 {
            return std.mem.sliceTo(self.string, 0);
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
        memmap: *std.os.uefi.tables.MemoryDescriptor,
        /// Size in bytes of the EFI memory map.
        memmap_size: u64,
        /// EFI memory map descriptor size in bytes.
        desc_size: u64,
        /// Version of EFI memory map descriptors.
        desc_version: u64,
    };
};

pub const BootTime = DateAtBoot;
pub const DateAtBoot = struct {
    pub const Request = extern struct {
        /// The ID of the request.
        id: [4]u64 = Identifiers.DateAtBoot,
        /// The revision of the request that the kernel provides.
        revision: u64 = 0,
        /// The pointer to the response structure.
        response: ?*const Response = null,
    };

    pub const Response = extern struct {
        /// The revision of the response that the bootloader provides.
        revision: u64 = 0,
        /// The UNIX time on boot, in seconds, taken from the system RTC,
        /// representing the date and time of boot.
        boot_time: i64,
    };
};

pub const FileAddress = ExecutableAddress;
pub const ExecutableAddress = struct {
    pub const Request = extern struct {
        /// The ID of the request.
        id: [4]u64 = Identifiers.ExecutableAddress,
        /// The revision of the request that the kernel provides.
        revision: u64 = 0,
        /// The pointer to the response structure.
        response: ?*const Response = null,
    };

    pub const Response = extern struct {
        /// The revision of the response that the bootloader provides.
        revision: u64 = 0,
        /// The physical base address of the executable.
        physical_base: u64,
        /// The virtual base address of the executable.
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

pub const RiscvBspHartId = struct {
    pub const Request = extern struct {
        /// The ID of the request.
        id: [4]u64 = Identifiers.RiscvBspHartId,
        /// The revision of the request that the kernel provides.
        revision: u64 = 0,
        /// The pointer to the response structure.
        response: ?*const Response = null,
    };

    pub const Response = extern struct {
        /// The revision of the response that the bootloader provides.
        revision: u64 = 0,
        /// Hart ID of the bootstrap processor as reported by the UEFI
        /// RISC-V Boot Protocol or the SBI.
        bsp_hart_id: u64,
    };
};

pub const BootloaderPerformance = struct {
    pub const Request = extern struct {
        /// The ID of the request.
        id: [4]u64 = Identifiers.BootloaderPerformance,
        /// The revision of the request that the kernel provides.
        revision: u64 = 0,
        /// The pointer to the response structure.
        response: ?*const Response = null,
    };

    pub const Response = extern struct {
        /// The revision of the response that the bootloader provides.
        revision: u64 = 0,
        /// Time of system reset in microseconds relative to an
        /// arbitrary point in the past.
        reset_usec: u64,
        /// Time of bootloader initialisation in microseconds relative
        /// to an arbitrary point in the past.
        init_usec: u64,
        /// Time of executable handoff in microseconds relative to an
        /// arbitrary point in the past.
        exec_usec: u64,
    };
};

test "docs" {
    // this is a dummy test function for docs generation
    // im too lazy to write actual tests

    std.testing.refAllDecls(@This());
}
