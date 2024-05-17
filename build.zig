const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const examples = b.option(bool, "examples", "Build examples") orelse false;

    const mod = b.addModule("mac_address", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("lib/root.zig"),
    });

    if (target.result.os.tag == .windows) {
        const zigwin32_mod = b.dependency("zigwin32", .{
            .target = target,
            .optimize = optimize,
        }).module("zigwin32");

        mod.addImport("win32", zigwin32_mod);
        mod.pic = true;
    }

    if (examples) {
        const print_all_exe = b.addExecutable(.{
            .name = "example_1",
            .target = target,
            .optimize = optimize,
            .root_source_file = b.path("examples/print_all.zig"),
        });
        print_all_exe.root_module.addImport("mac_address", mod);
        b.installArtifact(print_all_exe);
    }
}
