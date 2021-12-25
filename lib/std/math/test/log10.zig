const math = @import("../../math.zig");
const test_utils = @import("../test.zig");
const Testcase = test_utils.Testcase;
const runTests = test_utils.runTests;
const floatFromBits = test_utils.floatFromBits;
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
        tc32(-0x1.0223a0p+3,  nan32        ),
        tc32( 0x1.161868p+2,  0x1.46a9bcp-1),
        tc32(-0x1.0c34b4p+3,  nan32        ),
        tc32(-0x1.a206f0p+2,  nan32        ),
        tc32( 0x1.288bbcp+3,  0x1.ef1300p-1),
        // TODO: Incorrect last digit
        // tc32( 0x1.52efd0p-1, -0x1.6ee6dep-3),
        tc32(-0x1.a05cc8p-2,  nan32        ),
        tc32( 0x1.1f9efap-1, -0x1.0075ccp-2),
        tc32( 0x1.8c5db0p-1, -0x1.c75df8p-4),
        tc32(-0x1.5b86eap-1,  nan32        ),

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
        tc32( 0.1,   -1    ),
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
        tc64(-0x1.02239f3c6a8f1p+3,  nan64               ),
        tc64( 0x1.161868e18bc67p+2,  0x1.46a9bd1d2eb87p-1),
        tc64(-0x1.0c34b3e01e6e7p+3,  nan64               ),
        tc64(-0x1.a206f0a19dcc4p+2,  nan64               ),
        tc64( 0x1.288bbb0d6a1e6p+3,  0x1.ef12fff994862p-1),
        tc64( 0x1.52efd0cd80497p-1, -0x1.6ee6db5a155cbp-3),
        tc64(-0x1.a05cc754481d1p-2,  nan64               ),
        tc64( 0x1.1f9ef934745cbp-1, -0x1.0075cda79d321p-2),
        tc64( 0x1.8c5db097f7442p-1, -0x1.c75df6442465ap-4),
        tc64(-0x1.5b86ea8118a0ep-1,  nan64               ),
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
        tc64( 0.1,   -1    ),
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
