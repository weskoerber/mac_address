const std = @import("std");
const mem = std.mem;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const verbose = b.option(bool, "verbose", "Add verbose logging") orelse false;

    const mod = b.addModule("mac_address", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/root.zig"),
    });

    const build_options = b.addOptions();
    build_options.addOption(bool, "verbose", verbose);
    mod.addOptions("options", build_options);

    const exe1 = b.addExecutable(.{
        .name = "print_all",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .root_source_file = b.path("examples/print_all.zig"),
        }),
    });
    exe1.root_module.addImport("mac_address", mod);
    b.installArtifact(exe1);

    const exe2 = b.addExecutable(.{
        .name = "print_first_no_loopback",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .root_source_file = b.path("examples/print_first_no_loopback.zig"),
        }),
    });
    exe2.root_module.addImport("mac_address", mod);
    b.installArtifact(exe2);

    addDocsStep(b, .{ .target = target, .optimize = optimize });

    const test_step = b.step("test", "Run tests");

    const test_exe = b.addTest(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/root.zig"),
    });
    test_exe.root_module.addOptions("options", build_options);

    const run_test_exe = b.addRunArtifact(test_exe);
    test_step.dependOn(&run_test_exe.step);

    if (target.result.os.tag == .windows) {
        const zigwin32_mod = b.dependency("zigwin32", .{
            // .target = target,
            // .optimize = optimize,
        }).module("win32");

        mod.addImport("win32", zigwin32_mod);
        mod.pic = true;

        test_exe.root_module.addImport("win32", zigwin32_mod);
    }
}

fn addDocsStep(b: *std.Build, options: anytype) void {
    const docs_step = b.step("docs", "Emit docs");

    const lib = b.addStaticLibrary(.{
        .name = "mac_address",
        .root_source_file = b.path("src/root.zig"),
        .target = options.target,
        .optimize = options.optimize,
    });

    const docs_install = b.addInstallDirectory(.{
        .install_dir = .prefix,
        .install_subdir = "docs",
        .source_dir = lib.getEmittedDocs(),
    });

    docs_step.dependOn(&docs_install.step);
}
