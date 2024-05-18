const std = @import("std");
const mem = std.mem;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const examples = b.option(bool, "examples", "Build examples") orelse false;
    const verbose = b.option(bool, "verbose", "Add verbose logging") orelse false;

    const mod = b.addModule("mac_address", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("lib/root.zig"),
    });

    const build_options = b.addOptions();
    build_options.addOption(bool, "verbose", verbose);
    mod.addOptions("options", build_options);

    if (target.result.os.tag == .windows) {
        const zigwin32_mod = b.dependency("zigwin32", .{
            .target = target,
            .optimize = optimize,
        }).module("zigwin32");

        mod.addImport("win32", zigwin32_mod);
        mod.pic = true;
    }

    if (examples) {
        buildExamples(
            b,
            .{ .name = "mac_address", .module = mod },
            .{ .target = target, .optimize = optimize },
        ) catch |err| {
            std.debug.print("error: {}\n  -> failed building examples\n", .{err});
        };
    }
}

fn buildExamples(b: *std.Build, import: std.Build.Module.Import, options: anytype) !void {
    const examples_dir = try b.build_root.join(b.allocator, &.{"examples"});
    const dir = try b.build_root.handle.openDir(examples_dir, .{ .iterate = true });
    var iter = dir.iterate();

    while (try iter.next()) |example_src| {
        const extension_pos = mem.indexOfScalar(u8, example_src.name, '.').?;

        const root_source_file = b.pathJoin(&.{
            "./examples",
            example_src.name,
        });

        const exe_name = example_src.name[0..extension_pos];

        const exe = b.addExecutable(.{
            .name = exe_name,
            .target = options.target,
            .optimize = options.optimize,
            .root_source_file = b.path(root_source_file),
        });

        exe.root_module.addImport(import.name, import.module);
        b.installArtifact(exe);
    }
}
