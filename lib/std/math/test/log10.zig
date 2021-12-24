const math = @import("../../math.zig");
const Testcase = @import("../test.zig").Testcase;
const runTests = @import("../test.zig").runTests;
const floatFromBits = @import("../test.zig").floatFromBits;
const inf32 = math.inf_f32;
const inf64 = math.inf_f64;
const nan32 = math.nan_f32;
const nan64 = math.nan_f64;


const Tc32 = Testcase(math.log10, "log10", f32);
const tc32 = Tc32.init;

const Tc64 = Testcase(math.log10, "log10", f64);
const tc64 = Tc64.init;

test "math.log10_32() sanity" {
    const cases = [_]Tc32{
        // zig fmt: off
        // TODO
        // zig fmt: on
    };
    try runTests(cases);
}

test "math.log10_32() special" {
    const cases = [_]Tc32{
        // zig fmt: off
        tc32( 0,     -inf32),
        tc32(-0,     -inf32),
        tc32( 1,      0    ),
        tc32( 10,     1    ),
        tc32(-1,      nan32),
        tc32( inf32,  inf32),
        tc32(-inf32,  nan32),
        // NaNs: should be unchanged when passed through.
        tc32( nan32,  nan32),
        tc32(-nan32, -nan32),
        tc32(floatFromBits(f32, 0x7ff01234), floatFromBits(f32, 0x7ff01234)),
        tc32(floatFromBits(f32, 0xfff01234), floatFromBits(f32, 0xfff01234)),
        // zig fmt: on
    };
    try runTests(cases);
}

test "math.log10_32() boundary" {
    const cases = [_]Tc32{
        // zig fmt: off
        // TODO
        // zig fmt: on
    };
    try runTests(cases);
}

test "math.log10_64() sanity" {
    const cases = [_]Tc64{
        // zig fmt: off
        // TODO
        // zig fmt: on
    };
    try runTests(cases);
}

test "math.log10_64() special" {
    const cases = [_]Tc64{
        // zig fmt: off
        tc64( 0,     -inf64),
        tc64(-0,     -inf64),
        tc64( 1,      0    ),
        tc64( 10,     1    ),
        tc64(-1,      nan64),
        tc64( inf64,  inf64),
        tc64(-inf64,  nan64),
        // NaNs: should be unchanged when passed through.
        tc64( nan64,  nan64),
        tc64(-nan64, -nan64),
        tc64(floatFromBits(f64, 0x7ff0123400000000), floatFromBits(f64, 0x7ff0123400000000)),
        tc64(floatFromBits(f64, 0xfff0123400000000), floatFromBits(f64, 0xfff0123400000000)),
        // zig fmt: on
    };
    try runTests(cases);
}

test "math.log10_64() boundary" {
    const cases = [_]Tc64{
        // zig fmt: off
        // TODO
        // zig fmt: on
    };
    try runTests(cases);
}
