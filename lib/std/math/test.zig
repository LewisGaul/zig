const std = @import("../std.zig");
const print = std.debug.print;
const assert = std.debug.assert;
const meta = std.meta;
const math = std.math;
const bitCount = meta.bitCount;
const nan = math.nan;

// Switch to 'true' to enable debug output.
var verbose = true;

// Include all tests.
comptime {
    _ = @import("test/exp.zig");
    // _ = @import("test/exp2.zig");
    // _ = @import("test/expm1.zig");
    // // TODO: The implementation seems to be broken...
    // // _ = @import("test/expo2.zig");
    // _ = @import("test/ln.zig");
    // _ = @import("test/log2.zig");
    // _ = @import("test/log10.zig");
    // _ = @import("test/log1p.zig");
}

pub const RoundingMode = enum {
    Nearest,
    Down,
    Up,
    TowardZero,
};

pub const FloatException = enum {
    Invalid,
    Inexact,
    DivByZero,
    Overflow,
    Underflow,
};

// Used for the type signature.
fn genericFloatInFloatOut(x: anytype) @TypeOf(x) {
    return x;
}

/// Create a testcase struct type for a given function that takes in a generic
/// float value and outputs the same float type. Provides descriptive reporting
/// of errors.
pub fn Testcase(
    comptime func: @TypeOf(genericFloatInFloatOut),
    comptime name: []const u8,
    comptime float_type: type,
) type {
    if (@typeInfo(float_type) != .Float) @compileError("Expected float type");

    return struct {
        pub const F: type = float_type;

        input: F,
        exp_output: F,

        const Self = @This();

        pub const bits = bitCount(F);
        const U: type = meta.Int(.unsigned, bits);

        pub fn init(input: F, exp_output: F) Self {
            return .{ .input = input, .exp_output = exp_output };
        }

        pub fn run(tc: Self) !void {
            const hex_bits_fmt_size = comptime std.fmt.comptimePrint("{d}", .{bits / 4});
            const hex_float_fmt_size = switch (bits) {
                16 => "10",
                32 => "16",
                64 => "24",
                128 => "40",
                else => unreachable,
            };
            const input_bits = @bitCast(U, tc.input);
            if (verbose) {
                print(
                    " IN:  0x{X:0>" ++ hex_bits_fmt_size ++ "}  " ++
                        "{[1]x:<" ++ hex_float_fmt_size ++ "}  {[1]e}\n",
                    .{ input_bits, tc.input },
                );
            }
            const output = func(tc.input);
            const output_bits = @bitCast(U, output);
            if (verbose) {
                print(
                    "OUT:  0x{X:0>" ++ hex_bits_fmt_size ++ "}  " ++
                        "{[1]x:<" ++ hex_float_fmt_size ++ "}  {[1]e}\n",
                    .{ output_bits, output },
                );
            }
            const exp_output_bits = @bitCast(U, tc.exp_output);
            // Compare bits rather than values so that NaN compares correctly.
            if (output_bits != exp_output_bits) {
                if (verbose) {
                    print(
                        "EXP:  0x{X:0>" ++ hex_bits_fmt_size ++ "}  " ++
                            "{[1]x:<" ++ hex_float_fmt_size ++ "}  {[1]e}\n",
                        .{ exp_output_bits, tc.exp_output },
                    );
                }
                print(
                    "FAILURE: expected {s}({x})->{x}, got {x} ({d}-bit)\n",
                    .{ name, tc.input, tc.exp_output, output, bits },
                );
                return error.TestExpectedEqual;
            }
        }
    };
}

/// Run all testcases in the given iterable, using the '.run()' method.
pub fn runTests(tests: anytype) !void {
    var failures: usize = 0;
    print("\n", .{});
    for (tests) |tc| {
        tc.run() catch {
            failures += 1;
        };
        if (verbose) print("\n", .{});
    }
    if (verbose) {
        print(
            "Subtest summary: {d} passed; {d} failed\n",
            .{ tests.len - failures, failures },
        );
    }
    if (failures > 0) return error.Failure;
}

/// Create a float of the given type using the unsigned integer bit representation.
pub fn floatFromBits(comptime T: type, bits: meta.Int(.unsigned, bitCount(T))) T {
    return @bitCast(T, bits);
}

/// Generate a comptime slice of testcases of the given type.
///
/// The input type should be an instance of 'Testcase'.
///
/// The input testcases should be a comptime iterable of 2-tuples containing
/// input and expected output for the testcase. These values may be a comptime
/// integer or float, or a regular float, and will be cast to the destination
/// float type.
pub fn genTests(comptime T: type, comptime testcases: anytype) []const T {
    comptime var out_tests: []const T = &.{};
    inline for (testcases) |tc| {
        assert(tc.len == 2);
        out_tests = out_tests ++ &[_]T{T.init(tc[0], tc[1])};
    }
    return out_tests;
}


pub fn genTests2(comptime T: type, comptime testcases: anytype) []const T {
    comptime var out_tests: []const T = &.{};
    inline for (testcases) |tc| {
        assert(tc.len == 5);
        assert(tc[0] == RoundingMode.Nearest);
        out_tests = out_tests ++ &[_]T{T.init(tc[1], tc[2])};
    }
    return out_tests;
}

/// A comptime slice of NaN testcases, applicable to all functions.
///
/// The input type should be an instance of 'Testcase'.
pub fn nanTests(comptime T: type) []const T {
    // NaNs should always be unchanged when passed through.
    comptime var out_tests: []const T = &.{};
    const nan_values: []const T.F = &[_]T.F{
        nan(T.F),
        -nan(T.F),
    } ++ comptime switch (T.bits) {
        32 => &[_]T.F{
            floatFromBits(T.F, 0x7fc01234), //  qNaN(0x1234)
            floatFromBits(T.F, 0xffc01234), // -qNaN(0x1234)
            floatFromBits(T.F, 0x7f801234), //  sNaN(0x1234)
        },
        64 => &[_]T.F{
            floatFromBits(T.F, 0x7ff8000000001234), //  qNaN(0x1234)
            floatFromBits(T.F, 0x7ff8000000001234), // -qNaN(0x1234)
            floatFromBits(T.F, 0xfff0000000001234), //  sNaN(0x1234)
        },
        else => @compileError("Not yet implemented for " ++ @typeName(T.F)),
    };
    inline for (nan_values) |val| {
        out_tests = out_tests ++ &[_]T{T.init(val, val)};
    }
    return out_tests;
}
