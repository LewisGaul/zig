const std = @import("std");

pub fn build(b: *std.Build) void {
    const test_step = b.step("test", "Test it");
    b.default_step = test_step;

    add(b, test_step, .Debug);
    add(b, test_step, .ReleaseFast);
    add(b, test_step, .ReleaseSmall);
    add(b, test_step, .ReleaseSafe);
}

fn add(b: *std.Build, test_step: *std.Build.Step, optimize: std.builtin.OptimizeMode) void {
    const lib_a = b.addStaticLibrary(.{
        .name = "a",
        .optimize = optimize,
        .target = .{},
    });
    lib_a.addCSourceFile("a.c", &[_][]const u8{});
    lib_a.addIncludePath(".");
    lib_a.install();

    const test_exe = b.addTest(.{
        .root_source_file = .{ .path = "main.zig" },
        .optimize = optimize,
        .target = .{},
    });
    test_exe.linkSystemLibrary("a"); // force linking liba.a as -la
    test_exe.addSystemIncludePath(".");
    const search_path = std.fs.path.join(b.allocator, &[_][]const u8{ b.install_path, "lib" }) catch @panic("OOM");
    test_exe.addLibraryPath(search_path);

    test_step.dependOn(&test_exe.step);
}
