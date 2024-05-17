# `mac_address`

A cross-platform library to retrieve the MAC address from your network
interfaces.

## Install

First, add the dependency to your `build.zig.zon file`:

```zig
.{
    .name = "my-awesome-project",
    .version = "1.2.3",
    .dependencies = .{
        .mac_address = .{
            .url = "git+https://github.com/weskoerber/mac_address#main",
        },
    },
}
```

Then, import `mac_address` into your `build.zig`:

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mac_address = b.dependency("mac_address", .{
            .target = target,
            .optimize = optimize,
    }).module("mac_address");

    const my_exe = b.addExecutable(.{
        .name = "my_exe",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    my_exe.root_module.addImport(mac_address);
}
```

## Usage

See the `examples` directory for example usage. Example executables can be
built by setting the `examples` option to `true`:

```zig
    const mac_address = b.dependency("mac_address", .{
            .target = target,
            .optimize = optimize,
            .examples = true,
    }).module("mac_address");
```
