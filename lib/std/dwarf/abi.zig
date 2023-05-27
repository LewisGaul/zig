const builtin = @import("builtin");
const std = @import("../std.zig");
const os = std.os;
const mem = std.mem;

pub const RegisterContext = struct {
    eh_frame: bool,
    is_macho: bool,
};

pub fn isSupportedArch(arch: std.Target.Cpu.Arch) bool {
    return switch (arch) {
        .x86,
        .x86_64,
        .arm,
        .aarch64,
        => true,
        else => false,
    };
}

pub fn ipRegNum() u8 {
    return switch (builtin.cpu.arch) {
        .x86 => 8,
        .x86_64 => 16,
        .arm => 15,
        .aarch64 => 32,
        else => unreachable,
    };
}

pub fn fpRegNum(reg_ctx: RegisterContext) u8 {
    return switch (builtin.cpu.arch) {
        // GCC on OS X did the opposite of ELF for these registers (only in .eh_frame), and that is now the convention for MachO
        .x86 => if (reg_ctx.eh_frame and reg_ctx.is_macho) 4 else 5,
        .x86_64 => 6,
        .arm => 11,
        .aarch64 => 29,
        else => unreachable,
    };
}

pub fn spRegNum(reg_ctx: RegisterContext) u8 {
    return switch (builtin.cpu.arch) {
        .x86 => if (reg_ctx.eh_frame and reg_ctx.is_macho) 5 else 4,
        .x86_64 => 7,
        .arm => 13,
        .aarch64 => 31,
        else => unreachable,
    };
}

fn RegBytesReturnType(comptime ContextPtrType: type) type {
    const info = @typeInfo(ContextPtrType);
    if (info != .Pointer or info.Pointer.child != os.ucontext_t) {
        @compileError("Expected a pointer to ucontext_t, got " ++ @typeName(@TypeOf(ContextPtrType)));
    }

    return if (info.Pointer.is_const) return []const u8 else []u8;
}

/// Returns a slice containing the backing storage for `reg_number`.
///
/// `reg_ctx` describes in what context the register number is used, as it can have different
/// meanings depending on the DWARF container. It is only required when getting the stack or
/// frame pointer register on some architectures.
pub fn regBytes(ucontext_ptr: anytype, reg_number: u8, reg_ctx: ?RegisterContext) !RegBytesReturnType(@TypeOf(ucontext_ptr)) {
    var m = &ucontext_ptr.mcontext;

    return switch (builtin.cpu.arch) {
        .x86 => switch (reg_number) {
            0 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.EAX]),
            1 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.ECX]),
            2 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.EDX]),
            3 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.EBX]),
            4...5 => if (reg_ctx) |r| bytes: {
                if (reg_number == 4) {
                    break :bytes if (r.eh_frame and r.is_macho)
                        mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.EBP])
                    else
                        mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.ESP]);
                } else {
                    break :bytes if (r.eh_frame and r.is_macho)
                        mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.ESP])
                    else
                        mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.EBP]);
                }
            } else error.RegisterContextRequired,
            6 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.ESI]),
            7 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.EDI]),
            8 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.EIP]),
            9 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.EFL]),
            10 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.CS]),
            11 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.SS]),
            12 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.DS]),
            13 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.ES]),
            14 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.FS]),
            15 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.GS]),
            16...23 => error.InvalidRegister, // TODO: Support loading ST0-ST7 from mcontext.fpregs
            // TODO: Map TRAPNO, ERR, UESP
            32...39 => error.InvalidRegister, // TODO: Support loading XMM0-XMM7 from mcontext.fpregs
            else => error.InvalidRegister,
        },
        .x86_64 => switch (builtin.os.tag) {
            .linux, .netbsd, .solaris => switch (reg_number) {
                0 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.RAX]),
                1 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.RDX]),
                2 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.RCX]),
                3 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.RBX]),
                4 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.RSI]),
                5 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.RDI]),
                6 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.RBP]),
                7 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.RSP]),
                8 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.R8]),
                9 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.R9]),
                10 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.R10]),
                11 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.R11]),
                12 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.R12]),
                13 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.R13]),
                14 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.R14]),
                15 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.R15]),
                16 => mem.asBytes(&ucontext_ptr.mcontext.gregs[os.REG.RIP]),
                17...32 => |i| mem.asBytes(&m.fpregs.xmm[i - 17]),
                else => error.InvalidRegister,
            },
            .freebsd => switch (reg_number) {
                0 => mem.asBytes(&ucontext_ptr.mcontext.rax),
                1 => mem.asBytes(&ucontext_ptr.mcontext.rdx),
                2 => mem.asBytes(&ucontext_ptr.mcontext.rcx),
                3 => mem.asBytes(&ucontext_ptr.mcontext.rbx),
                4 => mem.asBytes(&ucontext_ptr.mcontext.rsi),
                5 => mem.asBytes(&ucontext_ptr.mcontext.rdi),
                6 => mem.asBytes(&ucontext_ptr.mcontext.rbp),
                7 => mem.asBytes(&ucontext_ptr.mcontext.rsp),
                8 => mem.asBytes(&ucontext_ptr.mcontext.r8),
                9 => mem.asBytes(&ucontext_ptr.mcontext.r9),
                10 => mem.asBytes(&ucontext_ptr.mcontext.r10),
                11 => mem.asBytes(&ucontext_ptr.mcontext.r11),
                12 => mem.asBytes(&ucontext_ptr.mcontext.r12),
                13 => mem.asBytes(&ucontext_ptr.mcontext.r13),
                14 => mem.asBytes(&ucontext_ptr.mcontext.r14),
                15 => mem.asBytes(&ucontext_ptr.mcontext.r15),
                16 => mem.asBytes(&ucontext_ptr.mcontext.rip),
                // TODO: Extract xmm state from mcontext.fpstate?
                else => error.InvalidRegister,
            },
            .openbsd => switch (reg_number) {
                0 => mem.asBytes(&ucontext_ptr.sc_rax),
                1 => mem.asBytes(&ucontext_ptr.sc_rdx),
                2 => mem.asBytes(&ucontext_ptr.sc_rcx),
                3 => mem.asBytes(&ucontext_ptr.sc_rbx),
                4 => mem.asBytes(&ucontext_ptr.sc_rsi),
                5 => mem.asBytes(&ucontext_ptr.sc_rdi),
                6 => mem.asBytes(&ucontext_ptr.sc_rbp),
                7 => mem.asBytes(&ucontext_ptr.sc_rsp),
                8 => mem.asBytes(&ucontext_ptr.sc_r8),
                9 => mem.asBytes(&ucontext_ptr.sc_r9),
                10 => mem.asBytes(&ucontext_ptr.sc_r10),
                11 => mem.asBytes(&ucontext_ptr.sc_r11),
                12 => mem.asBytes(&ucontext_ptr.sc_r12),
                13 => mem.asBytes(&ucontext_ptr.sc_r13),
                14 => mem.asBytes(&ucontext_ptr.sc_r14),
                15 => mem.asBytes(&ucontext_ptr.sc_r15),
                16 => mem.asBytes(&ucontext_ptr.sc_rip),
                // TODO: Extract xmm state from sc_fpstate?
                else => error.InvalidRegister,
            },
            .macos => switch (reg_number) {
                0 => mem.asBytes(&ucontext_ptr.mcontext.ss.rax),
                1 => mem.asBytes(&ucontext_ptr.mcontext.ss.rdx),
                2 => mem.asBytes(&ucontext_ptr.mcontext.ss.rcx),
                3 => mem.asBytes(&ucontext_ptr.mcontext.ss.rbx),
                4 => mem.asBytes(&ucontext_ptr.mcontext.ss.rsi),
                5 => mem.asBytes(&ucontext_ptr.mcontext.ss.rdi),
                6 => mem.asBytes(&ucontext_ptr.mcontext.ss.rbp),
                7 => mem.asBytes(&ucontext_ptr.mcontext.ss.rsp),
                8 => mem.asBytes(&ucontext_ptr.mcontext.ss.r8),
                9 => mem.asBytes(&ucontext_ptr.mcontext.ss.r9),
                10 => mem.asBytes(&ucontext_ptr.mcontext.ss.r10),
                11 => mem.asBytes(&ucontext_ptr.mcontext.ss.r11),
                12 => mem.asBytes(&ucontext_ptr.mcontext.ss.r12),
                13 => mem.asBytes(&ucontext_ptr.mcontext.ss.r13),
                14 => mem.asBytes(&ucontext_ptr.mcontext.ss.r14),
                15 => mem.asBytes(&ucontext_ptr.mcontext.ss.r15),
                16 => mem.asBytes(&ucontext_ptr.mcontext.ss.rip),
                else => error.InvalidRegister,
            },
            else => error.UnimplementedOs,
        },
        .arm => switch (builtin.os.tag) {
            .linux => switch (reg_number) {
                0 => mem.asBytes(&ucontext_ptr.mcontext.arm_r0),
                1 => mem.asBytes(&ucontext_ptr.mcontext.arm_r1),
                2 => mem.asBytes(&ucontext_ptr.mcontext.arm_r2),
                3 => mem.asBytes(&ucontext_ptr.mcontext.arm_r3),
                4 => mem.asBytes(&ucontext_ptr.mcontext.arm_r4),
                5 => mem.asBytes(&ucontext_ptr.mcontext.arm_r5),
                6 => mem.asBytes(&ucontext_ptr.mcontext.arm_r6),
                7 => mem.asBytes(&ucontext_ptr.mcontext.arm_r7),
                8 => mem.asBytes(&ucontext_ptr.mcontext.arm_r8),
                9 => mem.asBytes(&ucontext_ptr.mcontext.arm_r9),
                10 => mem.asBytes(&ucontext_ptr.mcontext.arm_r10),
                11 => mem.asBytes(&ucontext_ptr.mcontext.arm_fp),
                12 => mem.asBytes(&ucontext_ptr.mcontext.arm_ip),
                13 => mem.asBytes(&ucontext_ptr.mcontext.arm_sp),
                14 => mem.asBytes(&ucontext_ptr.mcontext.arm_lr),
                15 => mem.asBytes(&ucontext_ptr.mcontext.arm_pc),
                // CPSR is not allocated a register number (See: https://github.com/ARM-software/abi-aa/blob/main/aadwarf32/aadwarf32.rst, Section 4.1)
                else => error.InvalidRegister,
            },
            else => error.UnimplementedOs,
        },
        .aarch64 => switch (builtin.os.tag) {
            .macos => switch (reg_number) {
                0...28 => mem.asBytes(&ucontext_ptr.mcontext.ss.regs[reg_number]),
                29 => mem.asBytes(&ucontext_ptr.mcontext.ss.fp),
                30 => mem.asBytes(&ucontext_ptr.mcontext.ss.lr),
                31 => mem.asBytes(&ucontext_ptr.mcontext.ss.sp),
                32 => mem.asBytes(&ucontext_ptr.mcontext.ss.pc),
                else => error.InvalidRegister,
            },
            .netbsd => switch (reg_number) {
                0...34 => mem.asBytes(&ucontext_ptr.mcontext.gregs[reg_number]),
                else => error.InvalidRegister,
            },
            .freebsd => switch (reg_number) {
                0...29 => mem.asBytes(&ucontext_ptr.mcontext.gpregs.x[reg_number]),
                30 => mem.asBytes(&ucontext_ptr.mcontext.gpregs.lr),
                31 => mem.asBytes(&ucontext_ptr.mcontext.gpregs.sp),

                // TODO: This seems wrong, but it was in the previous debug.zig code for mapping PC, check this
                32 => mem.asBytes(&ucontext_ptr.mcontext.gpregs.elr),

                else => error.InvalidRegister,
            },
            else => switch (reg_number) {
                0...30 => mem.asBytes(&ucontext_ptr.mcontext.regs[reg_number]),
                31 => mem.asBytes(&ucontext_ptr.mcontext.sp),
                32 => mem.asBytes(&ucontext_ptr.mcontext.pc),
                else => error.InvalidRegister,
            },
        },
        else => error.UnimplementedArch,
    };
}

/// Returns the ABI-defined default value this register has in the unwinding table
/// before running any of the CIE instructions.
pub fn getRegDefaultValue(reg_number: u8, out: []u8) void {
    // TODO: Implement any ABI-specific rules for the default value for registers
    _ = reg_number;
    @memset(out, undefined);
}
