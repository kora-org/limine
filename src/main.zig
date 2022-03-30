const std = @import("std");

const COMMON_MAGIC = .{ 0xc7b1dd30df4c8b88, 0x0a82e883a194f07b };

pub const Uuid = struct {
    a: u32,
    b: u16,
    c: u16,
    d: [8]u8,
};

pub const File = struct {
    revision: u64,
    base: u64,
    length: u64,
    path: []const u8,
    cmdline: []const u8,
    partiton_index: u64,
    unused: u32,
    tftp_ip: u32,
    tftp_port: u32,
    mbr_disk_id: u32,
    gpt_disk_uuid: Uuid,
    gpt_part_uuid: Uuid,
    part_uuid: Uuid,
};

pub const Identifiers = enum([4]u64) {
    BootloaderInfo = .{ COMMON_MAGIC, 0xf55038d8e2a1202f, 0x279426fcf5f59740 },
    Hhdm = .{ COMMON_MAGIC, 0x48dcf1cb8ad2b852, 0x63984e959a98244b },
    Framebuffer = .{ COMMON_MAGIC, 0xcbfe81d7dd2d1977, 0x063150319ebc9b71 },
    Terminal = .{ COMMON_MAGIC, 0x0785a0aea5d0750f, 0x1c1936fee0d6cf6e },
    FiveLevelPaging = .{ COMMON_MAGIC, 0x94469551da9b3192, 0xebe5e86db7382888 },
    Smp = .{ COMMON_MAGIC, 0x95a67b819a1b857e, 0xa0b61b723b6a73e0 },
    MemoryMap = .{ COMMON_MAGIC, 0x67cf3d9d378a806f, 0xe304acdfc50c3c62 },
    EntryPoint = .{ COMMON_MAGIC, 0x13d86c035a1cd3e1, 0x2b0caa89d8f3026a },
    KernelFile = .{ COMMON_MAGIC, 0xad97e90e83f1ed67, 0x31eb5d1c5ff23b69 },
    Module = .{ COMMON_MAGIC, 0x3e7e279702be32af, 0xca1c4f3bd1280cee },
    Rdsp = .{ COMMON_MAGIC, 0xc5e77b6b397e7b43, 0x27637845accdcf3c },
    Smbios = .{ COMMON_MAGIC, 0x9e9046f11e095391, 0xaa4a520fefbde5ee },
    EfiSystemTable = .{ COMMON_MAGIC, 0x5ceba5163eaaf6d6, 0x0a6981610cf65fcc },
    BootTime = .{ COMMON_MAGIC, 0x502746e184c088aa, 0xfbc5ec83e6327893 },
    KernelAddress = .{ COMMON_MAGIC, 0x71ba76863cc55f63, 0xb2644a48c516a487 },
};

pub const BootloaderInfo = struct {
    pub const Request = struct {
        id: [4]u64 = Identifiers.BootloaderInfo,
        revision: u64,
        response: Response = null,
    };

    pub const Response = struct {
        revision: u64,
        name: []const u8,
        version: []const u8,
    };
};

pub const Hhdm = struct {
    pub const Request = struct {
        id: [4]u64 = Identifiers.Hhdm,
        revision: u64,
        response: Response = null,
    };

    pub const Response = struct {
        revision: u64,
        offset: u64,
    };
};

pub const Framebuffer = struct {
    pub const Request = struct {
        id: [4]u64 = Identifiers.Framebuffer,
        revision: u64,
        response: Response = null,
    };

    pub const Response = struct {
        revision: u64,
        display_count: u64,
        displays: [*]Display,
    };

    pub const Display = struct {
        address: u64,
        width: u16,
        height: u16,
        pitch: u16,
        bpp: u16,
        memory_model: u8,
        red_mask_size: u8,
        red_mask_shift: u8,
        green_mask_size: u8,
        green_mask_shift: u8,
        blue_mask_size: u8,
        blue_mask_shift: u8,
        _unused: u8,
        edid_size: u64,
        edid: u64,
    };
};

pub const Terminal = struct {
    pub const Request = struct {
        id: [4]u64 = Identifiers.Terminal,
        revision: u64,
        response: Response = null,
        callback: fn (u64, u64, u64, u64) void = null,
    };

    pub const Response = struct {
        revision: u64,
        columns: u32,
        rows: u32,
        write: fn (ptr: [:0]const u8, length: u64) callconv(.C) void,
    };
};

pub const FiveLevelPaging = struct {
    pub const Request = struct {
        id: [4]u64 = Identifiers.FiveLevelPaging,
        revision: u64,
        response: Response = null,
    };

    pub const Response = struct {
        revision: u64,
    };
};

pub const Smp = struct {
    pub const Request = struct {
        id: [4]u64 = Identifiers.Smp,
        revision: u64,
        response: Response = null,
        flags: u64 = 0,
    };

    pub const Response = struct {
        revision: u64,
        flags: u32,
        bsp_lapic_id: u32,
        cpu_count: u64,
        cpus: [*]Info,
    };

    pub const Info = struct {
        processor_id: u32,
        lapic_id: u32,
        reserved_id: u64,
        goto_address: fn (*Info) void,
        extra_argument: u64,
    };
};

pub const MemoryMap = struct {
    pub const Request = struct {
        id: [4]u64 = Identifiers.MemoryMap,
        revision: u64,
        response: Response = null,
    };

    pub const Response = struct {
        revision: u64,
        entry_count: u64,
        entries: [*]Entry,
    };

    pub const Entry = struct {
        base: u64,
        length: u64,
        type: Types,
    };

    pub const Types = enum {
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
    pub const Request = struct {
        id: [4]u64 = Identifiers.EntryPoint,
        revision: u64,
        response: Response = null,
        entry_point: fn () void = null,
    };

    pub const Response = struct {
        revision: u64,
    };
};

pub const KernelFile = struct {
    pub const Request = struct {
        id: [4]u64 = Identifiers.KernelFile,
        revision: u64,
        response: Response = null,
    };

    pub const Response = struct {
        revision: u64,
        kernel_file: *File,
    };
};

pub const Module = struct {
    pub const Request = struct {
        id: [4]u64 = Identifiers.Module,
        revision: u64,
        response: Response = null,
    };

    pub const Response = struct {
        revision: u64,
        module_count: u64,
        modules: [*]File,
    };
};

pub const Rdsp = struct {
    pub const Request = struct {
        id: [4]u64 = Identifiers.Rdsp,
        revision: u64,
        response: Response = null,
    };

    pub const Response = struct {
        revision: u64,
        address: u64,
    };
};

pub const Smbios = struct {
    pub const Request = struct {
        id: [4]u64 = Identifiers.Smbios,
        revision: u64,
        response: Response = null,
    };

    pub const Response = struct {
        revision: u64,
        entry_32: u64,
        entry_64: u64,
    };
};

pub const EfiSystemTable = struct {
    pub const Request = struct {
        id: [4]u64 = Identifiers.EfiSystemTable,
        revision: u64,
        response: Response = null,
    };

    pub const Response = struct {
        revision: u64,
        system_table: std.os.uefi.SystemTable,
    };
};

pub const BootTime = struct {
    pub const Request = struct {
        id: [4]u64 = Identifiers.BootTime,
        revision: u64,
        response: Response = null,
    };

    pub const Response = struct {
        revision: u64,
        boot_time: i64,
    };
};

pub const KernelAddress = struct {
    pub const Request = struct {
        id: [4]u64 = Identifiers.KernelAddress,
        revision: u64,
        response: Response = null,
    };

    pub const Response = struct {
        revision: u64,
        physical_base: u64,
        virtual_base: u64,
    };
};
