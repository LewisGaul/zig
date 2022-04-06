const math = @import("../../math.zig");
const test_utils = @import("../test.zig");
const Testcase = test_utils.Testcase;
const genTests = test_utils.genTests;
const genTests2 = test_utils.genTests2;
const runTests = test_utils.runTests;

const Tc32 = Testcase(math.exp, "exp", f32);
const Tc64 = Testcase(math.exp, "exp", f64);

test "math.exp32() special" {
    try runTests(genTests(Tc32, @import("exp_32.zig").special));
}

test "math.exp32() sanity" {
    try runTests(genTests(Tc32, @import("exp_32.zig").sanity));
}

test "math.exp32() boundary" {
    try runTests(genTests(Tc32, @import("exp_32.zig").boundary));
}

test "math.exp32() nan" {
    try runTests(test_utils.nanTests(Tc32));
}

test "math.exp64() special" {
    try runTests(genTests2(Tc64, @import("exp_64.zig").special));
}

test "math.exp64() sanity" {
    try runTests(genTests(Tc64, @import("exp_64.zig").sanity));
}

test "math.exp64() boundary" {
    try runTests(genTests(Tc64, @import("exp_64.zig").boundary));
}


test "math.exp64() nan" {
    try runTests(test_utils.nanTests(Tc64));
}
